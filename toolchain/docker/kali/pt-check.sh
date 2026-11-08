#!/bin/bash
# Toolchain verification. Run: pt-check   (inside the container)
# Exit code 1 if a critical tool is missing.
CRIT="nmap netexec impacket-GetUserSPNs ffuf gobuster sqlmap nuclei subfinder httpx naabu hashcat john hydra hydra chisel socat nc openssl python3 go cl.exe_mingw gcc"
missing=0

ver() {
    local bin="$1"; shift
    if command -v "$bin" >/dev/null 2>&1; then
        printf '%-24s %s\n' "$bin" "$("$@" 2>&1 | head -1 | cut -c1-70)"
    else
        printf '%-24s MISSING\n' "$bin"; missing=$((missing+1))
    fi
}

echo "== core =="
ver nmap nmap --version
ver masscan masscan --version
ver netexec netexec --version
ver impacket-GetUserSPNs impacket-GetUserSPNs --help
ver impacket-secretsdump impacket-secretsdump --help
ver ffuf ffuf -V
ver gobuster gobuster version
ver feroxbuster feroxbuster --version
ver sqlmap sqlmap --version
ver nuclei nuclei -version
ver subfinder subfinder -version
ver httpx httpx -version
ver naabu naabu -version
ver amass amass -version
ver hashcat hashcat --version
ver john john --list=build-info
ver hydra hydra -h
ver responder responder --help
ver chisel chisel --version
ver certipy certipy -h
ver enum4linux-ng enum4linux-ng -h
ver smbclient smbclient --version
ver nxc nxc --version

echo "== scripting / build =="
ver python3 python3 --version
ver go go version
ver gcc gcc --version
ver x86_64-w64-mingw32-gcc x86_64-w64-mingw32-gcc --version
ver proxychains4 proxychains4 -h
ver socat socat -V
ver nc nc -h
ver openssl openssl version

echo "== wordlists =="
for d in /usr/share/seclists /usr/share/wordlists; do
    if [ -d "$d" ]; then printf '%-24s %s files\n' "$d" "$(find "$d" -type f 2>/dev/null | wc -l)"; else printf '%-24s MISSING\n' "$d"; fi
done

echo "== optional packages not available in apt =="
cat /usr/local/share/pt-missing-packages.txt 2>/dev/null || echo "none recorded"

exit $([ "$missing" -eq 0 ] && echo 0 || echo 1)
