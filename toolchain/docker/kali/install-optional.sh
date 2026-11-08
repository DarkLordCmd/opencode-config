#!/bin/bash
# Optional Kali packages. Missing ones are recorded, not fatal.
# Rebuild after editing: E:\pintest\tools\build.ps1 -NoCache
set -u

PKGS="
feroxbuster nuclei subfinder amass httpx-toolkit naabu ligolo-ng
dirsearch wpscan smbmap
bloodhound.py certipy
rlwrap sshuttle
bettercap mitmproxy
onesixtyone snmp nbtscan
krb5-user cewl crunch dnsrecon dnsenum fierce sipvicious
iputils-ping net-tools bind9-dnsutils
"

apt-get update -qq
MISSED=""
for p in $PKGS; do
    if apt-get install -y --no-install-recommends -o Acquire::Retries=3 "$p" >/dev/null 2>&1; then
        echo "ok   $p"
    else
        echo "MISS $p"
        MISSED="$MISSED $p"
    fi
done
rm -rf /var/lib/apt/lists/*
echo "missing:$MISSED" > /usr/local/share/pt-missing-packages.txt

# Fallback: ProjectDiscovery tools built from source when apt did not provide them
for t in nuclei subfinder httpx naabu; do
    if ! command -v "$t" >/dev/null 2>&1; then
        case "$t" in
            nuclei)    pkg="github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest" ;;
            subfinder) pkg="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" ;;
            httpx)     pkg="github.com/projectdiscovery/httpx/cmd/httpx@latest" ;;
            naabu)     pkg="github.com/projectdiscovery/naabu/v2/cmd/naabu@latest" ;;
        esac
        echo "go   $t"
        GOBIN=/usr/local/bin go install "$pkg" >/dev/null 2>&1 || echo "MISS $t (go install)"
    fi
done
