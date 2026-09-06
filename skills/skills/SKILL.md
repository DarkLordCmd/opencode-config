---
name: linux-agent-skills
description: 'Router and index for the Linux/DevOps agent skill library. Load this skill first to find which specialized skill to load. Covers: Linux sysadmin (files, processes, networking, shell, users), Docker (containers, images, compose, Dockerfile), Kubernetes (kubectl, deployments, Helm, ingress, secrets), security (firewall, hardening, SSL/TLS, audit), DevOps (Ansible, Terraform, CI/CD, monitoring, Git), databases (MySQL, PostgreSQL, Redis, MongoDB, Elasticsearch, SQL optimization), backup & recovery (rsync, snapshot, disaster-recovery, cloud-backup), networking (DNS, VPN, load-balancer, proxy, TCP/IP, traffic-analysis), performance (tuning, profiling, benchmarking), server management (Nginx, Apache, systemd, cron, SSH, log-analysis), cloud CLI (AWS, Azure, GCloud, Aliyun). Use when user asks about any infrastructure, server, container, or DevOps task.'
---

# Linux Agent Skills — Router

This is the first-layer router. Read this file, then load the single most relevant skill path before acting.

## How to Load a Skill

1. Match the user's task to a skill path in the tables below.
2. Read that `SKILL.md` file into context.
3. Follow its instructions.

> **Do not load more than 2 skills at once** unless the task explicitly spans two platforms (e.g., database backup requires both `database/<engine>` + `backup/<method>`).

---

## Routing Table

### Linux Core

| Task / Keywords | Skill Path |
|-----------------|------------|
| find, chmod, chown, ln, rsync files, file search, disk usage, batch rename | `skills/linux/file-operations/SKILL.md` |
| ps, top, kill, htop, process, PID, cgroup, ulimit, fork | `skills/linux/process-management/SKILL.md` |
| ss, netstat, tcpdump, iptables, ip route, curl, wget, Linux network | `skills/linux/network-tools/SKILL.md` |
| bash script, shell script, trap, jq, awk, sed, parallel, heredoc | `skills/linux/shell-scripting/SKILL.md` |
| cron, logrotate, sysctl, kernel param, ulimit, journalctl, OS tuning | `skills/linux/system-admin/SKILL.md` |
| useradd, groupadd, sudo, ACL, PAM, passwd, visudo, permission policy | `skills/linux/user-permissions/SKILL.md` |

### Docker

| Task / Keywords | Skill Path |
|-----------------|------------|
| docker run, exec, logs, stop, rm, container lifecycle | `skills/docker/container-ops/SKILL.md` |
| docker build, push, pull, tag, prune, registry, image | `skills/docker/image-management/SKILL.md` |
| docker compose, compose up/down, service definition, multi-container | `skills/docker/compose/SKILL.md` |
| Dockerfile, FROM, RUN, COPY, multi-stage build, .dockerignore | `skills/docker/dockerfile/SKILL.md` |
| docker network, bridge, overlay, macvlan, container networking | `skills/docker/networking/SKILL.md` |

### Kubernetes

| Task / Keywords | Skill Path |
|-----------------|------------|
| kubectl get/apply/describe/delete, basics, kubeconfig | `skills/kubernetes/kubectl-basics/SKILL.md` |
| Deployment, StatefulSet, DaemonSet, rollout, replica, k8s app deploy | `skills/kubernetes/deployment/SKILL.md` |
| Helm, chart, values.yaml, helm install/upgrade/rollback | `skills/kubernetes/helm/SKILL.md` |
| ConfigMap, Secret, env injection, k8s config | `skills/kubernetes/configmap-secret/SKILL.md` |
| Pod crash, CrashLoopBackOff, OOMKilled, k8s debug, pending pod | `skills/kubernetes/troubleshooting/SKILL.md` |
| Service, Ingress, Ingress controller, LoadBalancer, NodePort, TLS termination | `skills/kubernetes/service-ingress/SKILL.md` |
| pod exec, port-forward, pod lifecycle, init container | `skills/kubernetes/pod-management/SKILL.md` |

### Security

| Task / Keywords | Skill Path |
|-----------------|------------|
| iptables, firewalld, ufw, nftables, firewall rules | `skills/security/firewall/SKILL.md` |
| SSH hardening, sshd_config, fail2ban, OS hardening, CIS benchmark | `skills/security/hardening/SKILL.md` |
| TLS, SSL certificate, Let's Encrypt, openssl, HTTPS, mTLS | `skills/security/ssl-tls/SKILL.md` |
| audit, auditd, compliance, lynis, security scan, CVE, log audit | `skills/security/audit/SKILL.md` |

### DevOps

| Task / Keywords | Skill Path |
|-----------------|------------|
| Ansible, playbook, role, inventory, ad-hoc, Galaxy | `skills/devops/ansible/SKILL.md` |
| Terraform, HCL, plan/apply/destroy, state, module, IaC | `skills/devops/terraform/SKILL.md` |
| GitHub Actions, GitLab CI, pipeline, workflow, CI/CD | `skills/devops/ci-cd/SKILL.md` |
| Prometheus, Grafana, alerting, metrics, dashboard, monitoring | `skills/devops/monitoring/SKILL.md` |
| git rebase, reflog, cherry-pick, submodule, advanced git | `skills/devops/git-advanced/SKILL.md` |

### Database

| Task / Keywords | Skill Path |
|-----------------|------------|
| MySQL, mysqldump, replication, slow query, InnoDB | `skills/database/mysql/SKILL.md` |
| PostgreSQL, pg_dump, VACUUM, pg_stat, index, WAL | `skills/database/postgresql/SKILL.md` |
| Redis, persistence, AOF, RDB, cluster, sentinel, eviction | `skills/database/redis/SKILL.md` |
| MongoDB, replica set, sharding, aggregation, Atlas | `skills/database/mongodb/SKILL.md` |
| Elasticsearch, index, shard, query DSL, mapping, Kibana | `skills/database/elasticsearch/SKILL.md` |
| SQL query tuning, EXPLAIN, index design, JOIN optimization | `skills/database/sql-optimization/SKILL.md` |

### Backup & Recovery

| Task / Keywords | Skill Path |
|-----------------|------------|
| rsync backup, incremental sync, remote backup via rsync | `skills/backup/rsync/SKILL.md` |
| tar, gzip, bzip2, xz, compression, archive | `skills/backup/tar-compression/SKILL.md` |
| snapshot, LVM snapshot, ZFS snapshot, filesystem snapshot | `skills/backup/snapshot/SKILL.md` |
| S3, cloud backup, Rclone, object storage, offsite backup | `skills/backup/cloud-backup/SKILL.md` |
| backup strategy, 3-2-1, retention policy, RPO, RTO | `skills/backup/backup-strategy/SKILL.md` |
| disaster recovery, DR drill, restore procedure, failover | `skills/backup/disaster-recovery/SKILL.md` |

### Networking

| Task / Keywords | Skill Path |
|-----------------|------------|
| DNS, bind, resolv.conf, dig, nslookup, zone file | `skills/network/dns/SKILL.md` |
| VPN, OpenVPN, WireGuard, IPsec, tunnel | `skills/network/vpn/SKILL.md` |
| load balancer, HAProxy, keepalived, VRRP, traffic distribution | `skills/network/load-balancer/SKILL.md` |
| Squid, Nginx proxy, reverse proxy, forward proxy | `skills/network/proxy/SKILL.md` |
| tcpdump, Wireshark, packet capture, bandwidth, traffic analysis | `skills/network/traffic-analysis/SKILL.md` |
| TCP/IP, OSI model, socket, MTU, routing table, BGP, VLAN | `skills/network/tcp-ip/SKILL.md` |

### Performance

| Task / Keywords | Skill Path |
|-----------------|------------|
| sysctl tuning, kernel params, I/O scheduler, CPU governor, OS performance | `skills/performance/tuning/SKILL.md` |
| slow server, high load, perf diagnosis, bottleneck, latency | `skills/performance/troubleshooting/SKILL.md` |
| benchmark, sysbench, fio, ab, wrk, iperf, performance test | `skills/performance/benchmarking/SKILL.md` |
| perf, strace, ltrace, flame graph, CPU profiling, memory profiling | `skills/performance/profiling/SKILL.md` |

### Server Management

| Task / Keywords | Skill Path |
|-----------------|------------|
| Nginx config, virtual host, upstream, rate limit, Nginx tuning | `skills/server/nginx/SKILL.md` |
| Apache, httpd, .htaccess, mod_rewrite, VirtualHost | `skills/server/apache/SKILL.md` |
| systemd, systemctl, service unit, journald, boot target | `skills/server/systemd/SKILL.md` |
| cron, crontab, scheduled task, at, anacron | `skills/server/cron/SKILL.md` |
| SSH, sshd, key management, ssh-keygen, port forwarding, ProxyJump | `skills/server/ssh/SKILL.md` |
| log analysis, grep log, logrotate, ELK, syslog, rsyslog | `skills/server/log-analysis/SKILL.md` |

### Cloud CLI

| Task / Keywords | Skill Path |
|-----------------|------------|
| AWS CLI, aws s3, ec2, iam, cloudwatch, awscli config | `skills/cloud-cli/aws-cli/SKILL.md` |
| Azure CLI, az vm, az storage, az aks, az login | `skills/cloud-cli/azure-cli/SKILL.md` |
| gcloud, GCP, GKE, Cloud Storage, Cloud Run, Google Cloud | `skills/cloud-cli/gcloud/SKILL.md` |
| aliyun, Alibaba Cloud, OSS, ECS, RAM, aliyun CLI | `skills/cloud-cli/aliyun-cli/SKILL.md` |

### General Q&A (Fallback)

| Task / Keywords | Skill Path |
|-----------------|------------|
| Conceptual questions, multi-topic sysadmin Q&A, no clear platform match | `skills/sysadmin-qa/SKILL.md` |

---

## Precedence Rules

When keywords overlap, apply these rules in order:

1. **Explicit platform wins** — if the user names a specific tool (e.g., `nginx`, `mysql`, `kubectl`, `terraform`), load that tool's skill directly.
2. **Container > OS** — if both Docker/K8s and Linux keywords appear, prefer the container skill; only load `linux/network-tools` if the issue is on the host network.
3. **Platform-specific troubleshooting** — prefer `kubernetes/troubleshooting` for K8s issues and `performance/troubleshooting` for OS-level performance issues; don't default to `sysadmin-qa`.
4. **TLS in K8s context** → `kubernetes/service-ingress` first, then `security/ssl-tls` if certificate management is needed.
5. **Database backup** → load the database skill (`database/<engine>`) AND the backup skill (`backup/<method>`) together.
6. **Networking overlap** — use context to disambiguate: "Docker network" → `docker/networking`; "host firewall" → `security/firewall`; "DNS setup" → `network/dns`; "K8s service expose" → `kubernetes/service-ingress`.
7. **`sysadmin-qa` is the last resort** — only use when no specific skill matches and the question is conceptual or spans more than 3 categories.

---

## Changelog

| Version | Date | Content |
|---------|------|---------|
| v1.0 | 2026-04-27 | Initial router SKILL.md — 60 skills, 12 categories, routing table + precedence rules |
