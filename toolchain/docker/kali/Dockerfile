# syntax=docker/dockerfile:1
FROM kalilinux/kali-rolling

ARG DEBIAN_FRONTEND=noninteractive
ARG WITH_MSF=false

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PINTEST_HOME=/pintest \
    PIP_NO_CACHE_DIR=1 \
    GOPATH=/root/go \
    PATH=/root/.local/bin:/root/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ---- Tier 1: packages that must exist, build fails if any is missing ----
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        -o Acquire::Retries=5 -o Acquire::http::Timeout=30 \
        ca-certificates curl wget git jq unzip zip less vim-tiny tmux procps file \
        python3 python3-pip python3-venv pipx \
        openssl netcat-traditional socat proxychains4 \
        nmap masscan tcpdump dnsutils ldap-utils smbclient whois \
        gobuster ffuf sqlmap hydra john hashcat \
        wordlists \
        impacket-scripts netexec responder chisel enum4linux-ng \
        nikto whatweb \
        golang-go gcc g++ make gdb mingw-w64 \
    ; rm -rf /var/lib/apt/lists/*

# ---- SecLists: large download, retried, git fallback ----
RUN set -eux; \
    if ! apt-get install -y --no-install-recommends -o Acquire::Retries=5 seclists; then \
        echo "apt seclists failed, falling back to git"; \
        rm -rf /usr/share/seclists; \
        git clone --depth 1 https://github.com/danielmiessler/SecLists.git /usr/share/seclists; \
    fi; \
    rm -rf /var/lib/apt/lists/*; \
    test -d /usr/share/seclists

# ---- Tier 2: optional packages, missing ones are logged not fatal ----
COPY install-optional.sh /usr/local/bin/install-optional.sh
RUN chmod +x /usr/local/bin/install-optional.sh && /usr/local/bin/install-optional.sh

# ---- Tier 3: Python tooling that is not packaged cleanly ----
RUN set -eux; \
    pipx ensurepath >/dev/null 2>&1 || true; \
    for p in certipy-ad pypykatz; do pipx install "$p" >/dev/null 2>&1 && echo "ok   $p" || echo "MISS $p"; done; \
    true

# ---- Tier 4: metasploit, off by default (--build-arg WITH_MSF=true) ----
RUN if [ "$WITH_MSF" = "true" ]; then \
        apt-get update && apt-get install -y --no-install-recommends metasploit-framework && \
        rm -rf /var/lib/apt/lists/*; \
    else echo "metasploit skipped (WITH_MSF=false)"; fi

# ---- Tier 5: extras that were missing at first pass ----
# Appended as a separate layer so earlier cached layers are reused on rebuild.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends -o Acquire::Retries=5 \
        python3-docx python3-openpyxl jadx apktool || echo "WARN: some apt extras missing"; \
    pipx install frida-tools >/dev/null 2>&1 && echo "ok   frida-tools" || echo "MISS frida-tools"; \
    GOBIN=/usr/local/bin go install github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest \
        >/dev/null 2>&1 && echo "ok   interactsh-client" || echo "MISS interactsh-client"; \
    apt-get install -y --no-install-recommends -o Acquire::Retries=5 metasploit-framework \
        && echo "ok   metasploit" || echo "MISS metasploit"; \
    rm -rf /var/lib/apt/lists/*

# ---- Toolchain check script ----
COPY pt-check.sh /usr/local/bin/pt-check
RUN chmod +x /usr/local/bin/pt-check

COPY bashrc.additions /root/.bashrc.additions
RUN cat /root/.bashrc.additions >> /root/.bashrc

WORKDIR /pintest
ENV PINTEST_HOME=/pintest

CMD ["/bin/bash"]
