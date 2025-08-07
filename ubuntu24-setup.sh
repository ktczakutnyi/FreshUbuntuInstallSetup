#!/bin/bash

# Ubuntu 24.04 Fresh Install Setup Script
# This script installs essential development tools and applications organized by category

set -e  # Exit on any error

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-functions.sh"

print_header "Ubuntu 24.04 Fresh Install Setup Script"
print_header "Security Tools Installation with Organized Categories"

# Create organized tool directories
create_tool_directories

# Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Python3 and pip
print_status "Installing Python3 and pip..."
sudo apt install -y python3 python3-pip

# Verify Python3 installation
if command_exists python3; then
    print_status "Python3 installed successfully: $(python3 --version)"
else
    print_error "Python3 installation failed"
    exit 1
fi

# Verify pip installation
if command_exists pip3; then
    print_status "pip3 installed successfully: $(pip3 --version)"
else
    print_error "pip3 installation failed"
    exit 1
fi

# Install snap if not already installed (usually comes with Ubuntu)
if ! command_exists snap; then
    print_status "Installing snapd..."
    sudo apt install -y snapd
else
    print_status "snap is already installed"
fi

# Install Visual Studio Code via snap
print_status "Installing Visual Studio Code via snap..."
sudo snap install --classic code

# Install Ghidra via snap
print_status "Installing Ghidra via snap..."
sudo snap install ghidra

# Install JADX (Java decompiler) - Binary Analysis Category
print_section "Installing Binary Analysis Tools"
print_status "Installing JADX (Java Decompiler) - Most Important Tool for Android Reverse Engineering..."
print_status "JADX is a tool for reverse engineering Android applications that decompiles bytecode to Java source code from APK and DEX files"

# First, ensure Java and zip are installed (required for JADX)
sudo apt install -y default-jre default-jdk zip

# Get the latest JADX version dynamically
print_status "Retrieving latest JADX version..."
JADX_VERSION=$(curl -s "https://api.github.com/repos/skylot/jadx/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+' || echo "1.4.7")
print_status "Latest JADX version: ${JADX_VERSION}"

# Download and install JADX to /opt/jadx (following the tutorial structure)
JADX_DIR="/opt/jadx"
JADX_URL="https://github.com/skylot/jadx/releases/latest/download/jadx-${JADX_VERSION}.zip"

print_status "Downloading JADX v${JADX_VERSION}..."
cd /tmp
curl -Lo jadx.zip "$JADX_URL" || wget -O jadx.zip "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip"

print_status "Extracting JADX..."
unzip jadx.zip -d jadx-temp

print_status "Installing JADX to ${JADX_DIR}..."
# Clean up any existing installation
sudo rm -rf "$JADX_DIR" 2>/dev/null || true
# Create fresh directory structure
sudo mkdir -p "$JADX_DIR/bin"
sudo mkdir -p "$JADX_DIR/lib"

# Move JADX files to specified directory
sudo mv jadx-temp/bin/jadx "$JADX_DIR/bin/"
sudo mv jadx-temp/bin/jadx-gui "$JADX_DIR/bin/"
sudo mv jadx-temp/lib/* "$JADX_DIR/lib/"

# Make executables
sudo chmod +x "$JADX_DIR/bin/jadx"
sudo chmod +x "$JADX_DIR/bin/jadx-gui"

# Add to PATH environment variable system-wide
echo 'export PATH=$PATH:/opt/jadx/bin' | sudo tee -a /etc/profile
# Also add to current session
export PATH=$PATH:/opt/jadx/bin

# Create symbolic links for compatibility with existing script structure
sudo ln -sf "$JADX_DIR/bin/jadx" /usr/local/bin/jadx
sudo ln -sf "$JADX_DIR/bin/jadx-gui" /usr/local/bin/jadx-gui

# Clean up
rm -rf jadx.zip jadx-temp

print_status "JADX installed successfully to $JADX_DIR"
print_status "JADX CLI and GUI are now available system-wide"

# Download a test APK for demonstration
print_status "Downloading test APK for JADX testing..."
sudo curl -o /opt/security-tools/binary-analysis/test.apk https://raw.githubusercontent.com/appium-boneyard/sign/master/tests/assets/tiny.apk 2>/dev/null || print_warning "Test APK download failed - will skip"

print_status "Test JADX with: jadx /opt/security-tools/binary-analysis/test.apk"

# Install Wine
print_status "Installing Wine..."
# Enable 32-bit architecture for Wine
sudo dpkg --add-architecture i386

# Add Wine repository for latest version
sudo mkdir -pm755 /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key

# Add Wine repository
echo "deb [arch=amd64,i386 signed-by=/etc/apt/keyrings/winehq-archive.key] https://dl.winehq.org/wine-builds/ubuntu/ noble main" | sudo tee /etc/apt/sources.list.d/winehq.list

# Update package list
sudo apt update

# Install Wine stable with error handling
print_status "Installing Wine stable (this may take a while)..."
if ! sudo apt install -y --install-recommends winehq-stable; then
    print_warning "Wine installation from repository failed, trying alternative method..."
    # Fallback to Ubuntu repository version
    sudo apt install -y wine
fi

# Install tmux and basic utilities
print_status "Installing tmux and basic utilities..."
sudo apt install -y \
    tmux \
    gedit \
    curl \
    wget \
    git \
    vim \
    htop \
    tree \
    unzip \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    screen \
    minicom \
    putty \
    ghex

# Configure tmux with mouse mode and useful settings
print_status "Configuring tmux with mouse mode and enhanced settings..."
TMUX_CONF="$HOME/.tmux.conf"

# Create tmux configuration file
cat << 'TMUX_CONFIG' > "$TMUX_CONF"
# Enable mouse mode for easier navigation
set -g mouse on

# Set prefix key to Ctrl-a (alternative to default Ctrl-b)
# Uncomment the next two lines if you prefer Ctrl-a as prefix
# unbind C-b
# set -g prefix C-a

# Enable 256 color support
set -g default-terminal "screen-256color"

# Start window numbering at 1 instead of 0
set -g base-index 1
set -g pane-base-index 1

# Automatically renumber windows when one is closed
set -g renumber-windows on

# Increase scrollback buffer size
set -g history-limit 10000

# Enable vim-style key bindings in copy mode
setw -g mode-keys vi

# Status bar configuration
set -g status-position bottom
set -g status-bg colour234
set -g status-fg colour137
set -g status-left ''
set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '
set -g status-right-length 50
set -g status-left-length 20

# Window status formatting
setw -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F '
setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '

# Pane border colors
set -g pane-border-style fg=colour238
set -g pane-active-border-style fg=colour51

# Message colors
set -g message-style fg=colour232,bg=colour166

# Easy pane splitting with more intuitive key bindings
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Easy pane navigation with Alt+arrow keys (no prefix needed)
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Easy window switching with Shift+arrow keys (no prefix needed)
bind -n S-Left previous-window
bind -n S-Right next-window

# Reload tmux config with prefix + r
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Enable activity monitoring
setw -g monitor-activity on
set -g visual-activity on

# Don't exit tmux when closing a session
set -g detach-on-destroy off
TMUX_CONFIG

print_status "tmux configuration created at $TMUX_CONF"
print_status "tmux features enabled:"
print_status "  ✓ Mouse mode - use mouse for scrolling, pane selection, and resizing"
print_status "  ✓ 256 color support for better visual experience"
print_status "  ✓ Improved status bar with time and date"
print_status "  ✓ Easy pane splitting: prefix + | (horizontal) or prefix + - (vertical)"
print_status "  ✓ Alt+arrow keys for pane navigation (no prefix needed)"
print_status "  ✓ Shift+arrow keys for window switching (no prefix needed)"
print_status "  ✓ prefix + r to reload config"
print_status "  ✓ Vim-style key bindings in copy mode"
print_status "  ✓ Increased scrollback buffer (10,000 lines)"

# If tmux is running, source the new configuration
if command_exists tmux && [ -n "$TMUX" ]; then
    print_status "Reloading tmux configuration in current session..."
    tmux source-file "$TMUX_CONF" 2>/dev/null || true
    print_status "tmux configuration reloaded!"
else
    print_status "tmux configuration will be loaded when you start tmux"
fi

print_status "tmux usage tips:"
print_status "  • Start tmux: tmux"
print_status "  • Detach from session: Ctrl+B, then d"
print_status "  • Re-attach to session: tmux attach"
print_status "  • List sessions: tmux list-sessions"
print_status "  • Create new window: Ctrl+B, then c"
print_status "  • Switch windows: Shift+Left/Right arrows"
print_status "  • Split pane horizontally: Ctrl+B, then |"
print_status "  • Split pane vertically: Ctrl+B, then -"
print_status "  • Navigate panes: Alt+arrow keys"
print_status "  • Resize panes: Ctrl+B, then arrow keys"
print_status "  • Scroll with mouse: just use your mouse wheel!"
print_status "  • Copy mode: Ctrl+B, then [ (use vim keys to navigate)"

# Install Java (OpenJDK 17 and latest)
print_status "Installing OpenJDK 17..."
sudo apt install -y openjdk-17-jdk openjdk-17-jre

print_status "Installing latest Java (OpenJDK 21)..."
sudo apt install -y openjdk-21-jdk openjdk-21-jre

# Set Java 21 as default
print_status "Setting Java 21 as default..."
sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-21-openjdk-amd64/bin/java 2100
sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/java-21-openjdk-amd64/bin/javac 2100
sudo update-alternatives --set java /usr/lib/jvm/java-21-openjdk-amd64/bin/java
sudo update-alternatives --set javac /usr/lib/jvm/java-21-openjdk-amd64/bin/javac

# Install Python development tools and dependencies
print_status "Installing Python development tools..."
sudo apt install -y python3-dev python3-venv libssl-dev libffi-dev
python3 -m pip install --upgrade pip --break-system-packages
python3 -m pip install --upgrade pwntools --break-system-packages

# Install pipx for safe system-wide Python tools
print_status "Installing pipx..."
sudo apt install -y pipx
pipx ensurepath

# Network reconnaissance tools
print_section "Installing Network Reconnaissance Tools"
print_status "Installing network reconnaissance tools to /opt/security-tools/network-recon..."

# Install tools that are commonly available
sudo apt install -y \
    nmap \
    nikto \
    netdiscover

# Create symlinks in the network-recon directory for organization
NETWORK_RECON_DIR="/opt/security-tools/network-recon"
sudo mkdir -p "$NETWORK_RECON_DIR/installed-tools"

# Create documentation for installed tools
cat << EOF | sudo tee "$NETWORK_RECON_DIR/README.md" > /dev/null
# Network Reconnaissance Tools

## Installed via APT:
- nmap: Network exploration and security auditing
- nikto: Web server scanner
- netdiscover: Network address discovering tool

## Manual installations will be added here:
- amass: In-depth Attack Surface Mapping and Asset Discovery
- dmitry: Information gathering tool
- recon-ng: Web reconnaissance framework

## Usage Examples:
- nmap -sS target: TCP SYN scan
- nikto -h target: Web vulnerability scan
- netdiscover -r 192.168.1.0/24: Network discovery

EOF

# Install tools with error handling (some may not be available)
tools_to_try=(
    "amass"
    "dmitry" 
    "ike-scan"
    "legion"
    "zenmap"
    "unix-privesc-check"
    "ffuf"
)

for tool in "${tools_to_try[@]}"; do
    if apt-cache show "$tool" >/dev/null 2>&1; then
        sudo apt install -y "$tool" || print_warning "Failed to install $tool"
        echo "- $tool: Installed via APT" | sudo tee -a "$NETWORK_RECON_DIR/README.md" > /dev/null
    else
        print_warning "$tool not available in repositories - will be installed manually if possible"
        echo "- $tool: Not available in APT - manual installation needed" | sudo tee -a "$NETWORK_RECON_DIR/README.md" > /dev/null
    fi
done

# Install SpiderFoot from source (recommended method)
print_status "Installing SpiderFoot from source..."
SPIDERFOOT_DIR="/opt/security-tools/network-recon/spiderfoot"
if [ ! -d "$SPIDERFOOT_DIR" ]; then
    print_status "Cloning SpiderFoot repository..."
    sudo git clone https://github.com/smicallef/spiderfoot.git "$SPIDERFOOT_DIR"
    
    print_status "Installing SpiderFoot dependencies..."
    cd "$SPIDERFOOT_DIR"
    sudo pip3 install -r requirements.txt --break-system-packages
    
    # Create a convenient launcher script
    sudo tee /usr/local/bin/spiderfoot > /dev/null << 'SPIDERFOOT_SCRIPT'
#!/bin/bash
cd /opt/security-tools/network-recon/spiderfoot
python3 sf.py "$@"
SPIDERFOOT_SCRIPT
    sudo chmod +x /usr/local/bin/spiderfoot
    
    # Create a web UI launcher script
    sudo tee /usr/local/bin/spiderfoot-web > /dev/null << 'SPIDERFOOT_WEB_SCRIPT'
#!/bin/bash
cd /opt/security-tools/network-recon/spiderfoot
echo "Starting SpiderFoot Web UI on http://127.0.0.1:5001"
echo "Press Ctrl+C to stop"
python3 sf.py -l 127.0.0.1:5001
SPIDERFOOT_WEB_SCRIPT
    sudo chmod +x /usr/local/bin/spiderfoot-web
    
    print_status "SpiderFoot installed to $SPIDERFOOT_DIR"
    print_status "Use 'spiderfoot-web' to start the web interface"
else
    print_status "SpiderFoot already installed at $SPIDERFOOT_DIR"
fi

# Install recon-ng from source (not available in PyPI)
print_status "Installing recon-ng from source..."
RECONNG_DIR="/opt/security-tools/network-recon/recon-ng"
if [ ! -d "$RECONNG_DIR" ]; then
    print_status "Cloning recon-ng repository..."
    sudo git clone https://github.com/lanmaster53/recon-ng.git "$RECONNG_DIR"
    
    print_status "Installing recon-ng dependencies..."
    cd "$RECONNG_DIR"
    # Use --ignore-installed to bypass system package conflicts (like blinker)
    sudo pip3 install -r REQUIREMENTS --break-system-packages --ignore-installed blinker || {
        print_warning "Some dependencies failed to install, trying alternative approach..."
        sudo pip3 install -r REQUIREMENTS --break-system-packages --force-reinstall --no-deps || {
            print_warning "Dependency installation encountered issues, but recon-ng may still be functional"
        }
    }
    
    # Create a convenient launcher script
    sudo tee /usr/local/bin/recon-ng > /dev/null << 'RECONNG_SCRIPT'
#!/bin/bash
cd /opt/security-tools/network-recon/recon-ng
python3 recon-ng "$@"
RECONNG_SCRIPT
    sudo chmod +x /usr/local/bin/recon-ng
    
    print_status "recon-ng installed to $RECONNG_DIR"
    print_status "Use 'recon-ng' to start the framework"
else
    print_status "recon-ng already installed at $RECONNG_DIR"
fi

# Web application security tools
print_section "Installing Web Application Security Tools"
WEB_TESTING_DIR="/opt/security-tools/web-testing"
print_status "Installing web application security tools to $WEB_TESTING_DIR..."

# Install commonly available tools
sudo apt install -y \
    sqlmap \
    sqlitebrowser

# Create documentation for web testing tools
cat << EOF | sudo tee "$WEB_TESTING_DIR/README.md" > /dev/null
# Web Application Security Tools

## Installed via APT:
- sqlmap: Automatic SQL injection and database takeover tool
- sqlitebrowser: GUI for SQLite databases

## Manual installations needed:
- burpsuite: Web application security testing platform
- wpscan: WordPress security scanner
- commix: Command injection exploiter
- skipfish: Web application reconnaissance tool

## Usage Examples:
- sqlmap -u "http://target.com/page.php?id=1" --dbs
- wpscan --url http://target.com
- burpsuite (GUI application)

EOF

# Install tools with error handling
web_tools_to_try=(
    "burpsuite"
    "commix"
    "skipfish"
    "webshells"
    "wpscan"
)

for tool in "${web_tools_to_try[@]}"; do
    if apt-cache show "$tool" >/dev/null 2>&1; then
        sudo apt install -y "$tool" || print_warning "Failed to install $tool"
        echo "- $tool: Installed via APT" | sudo tee -a "$WEB_TESTING_DIR/README.md" > /dev/null
    else
        print_warning "$tool not available in repositories - manual installation guide added to documentation"
        echo "- $tool: Manual installation needed" | sudo tee -a "$WEB_TESTING_DIR/README.md" > /dev/null
    fi
done

# Password and hash tools
print_section "Installing Password & Hash Cracking Tools"
PASSWORD_DIR="/opt/security-tools/password-cracking"
print_status "Installing password and hash tools to $PASSWORD_DIR..."

# Install commonly available tools
sudo apt install -y \
    hashcat \
    hydra \
    john \
    crunch

# Create documentation for password tools
cat << EOF | sudo tee "$PASSWORD_DIR/README.md" > /dev/null
## Password & Hash Cracking Tools

## Installed via APT:
- hashcat: Advanced password recovery tool
- hydra: Network logon cracker
- john: John the Ripper password cracker
- crunch: Wordlist generator

## Installed via Source:
- pipal: Password analysis tool for password dumps (installed from GitHub)
  - Usage: pipal <password_file>
  - Example: pipal --output=analysis_report.txt rockyou.txt
  - Location: /opt/security-tools/password-cracking/pipal/

## Wordlist Location:
- System wordlists: /usr/share/wordlists/
- Custom wordlists: $PASSWORD_DIR/wordlists/

## Usage Examples:
- hydra -l admin -P passwords.txt target ssh
- hashcat -m 0 -a 0 hashes.txt wordlist.txt
- john --wordlist=wordlist.txt hashes.txt
- crunch 8 8 -t @@@@@@%% > wordlist.txt

EOF

# Create wordlists directory
sudo mkdir -p "$PASSWORD_DIR/wordlists"
sudo mkdir -p "$PASSWORD_DIR/hashfiles"

# Install tools with error handling
password_tools_to_try=(
    "cewl"
    "medusa"
    "ncrack"
    "ophcrack"
    "wordlists"
)

for tool in "${password_tools_to_try[@]}"; do
    if apt-cache show "$tool" >/dev/null 2>&1; then
        sudo apt install -y "$tool" || print_warning "Failed to install $tool"
        echo "- $tool: Installed via APT" | sudo tee -a "$PASSWORD_DIR/README.md" > /dev/null
    else
        print_warning "$tool not available in repositories"
        echo "- $tool: Not available in APT" | sudo tee -a "$PASSWORD_DIR/README.md" > /dev/null
    fi
done

# WiFi security tools
print_section "Installing WiFi Security Tools"
WIFI_DIR="/opt/security-tools/wifi-hacking"
print_status "Installing WiFi security tools to $WIFI_DIR..."

# Install commonly available WiFi tools
sudo apt install -y \
    aircrack-ng \
    pixiewps \
    reaver \
    wifite

# Try to install kismet separately with error handling
if apt-cache show kismet >/dev/null 2>&1; then
    sudo apt install -y kismet || print_warning "Failed to install kismet"
else
    print_warning "kismet not available in standard repositories - attempting manual installation..."
    
    # Try to install Kismet from official repository
    print_status "Adding Kismet official repository..."
    
    # Add Kismet repository key
    if wget -O - https://www.kismetwireless.net/kismet-release.asc 2>/dev/null | sudo gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/kismet.gpg >/dev/null; then
        # Add Kismet repository
        UBUNTU_CODENAME=$(lsb_release -cs)
        echo "deb http://www.kismetwireless.net/apt/release/${UBUNTU_CODENAME} ${UBUNTU_CODENAME} main" | sudo tee /etc/apt/sources.list.d/kismet.list >/dev/null
        
        # Update package list and install Kismet
        if sudo apt update 2>/dev/null && sudo apt install -y kismet 2>/dev/null; then
            print_status "Kismet installed successfully from official repository!"
            
            # Add current user to kismet group for proper permissions
            if command_exists kismet; then
                print_status "Adding user to kismet group..."
                sudo usermod -aG kismet "$USER" || print_warning "Failed to add user to kismet group"
                print_status "You may need to log out and back in for group changes to take effect."
            fi
        else
            print_warning "Failed to install Kismet from official repository"
            # Clean up failed repository
            sudo rm -f /etc/apt/sources.list.d/kismet.list /etc/apt/trusted.gpg.d/kismet.gpg
            print_warning "Kismet repository removed due to installation failure"
        fi
    else
        print_warning "Failed to add Kismet repository key - skipping Kismet installation"
    fi
fi

# Create documentation for WiFi tools
cat << EOF | sudo tee "$WIFI_DIR/README.md" > /dev/null
# WiFi Security Tools

## Installed via APT:
- aircrack-ng: WiFi security auditing tools suite
- pixiewps: WPS offline bruteforce tool
- reaver: WPS brute force attack tool
- wifite: Automated wireless attack tool

## Installed via Official Repository:
- kismet: Wireless network detector and sniffer (installed from official Kismet repository)

## May need manual installation:
- fern-wifi-cracker: WiFi security testing GUI (not available in Ubuntu 24.04 repos)

## Dependencies installed:
- macchanger: MAC address changing tool
- python3-pyqt5: Qt5 Python bindings
- python3-scapy: Packet manipulation library
- subversion: Version control system
- xterm: Terminal emulator

## Capture Files:
- Store captures in: $WIFI_DIR/captures/
- Handshakes: $WIFI_DIR/handshakes/

## Usage Examples:
- airmon-ng start wlan0
- airodump-ng wlan0mon
- aircrack-ng -w wordlist.txt capture.cap
- reaver -i wlan0mon -b [BSSID] -vv
- wifite --kill
- kismet (wireless network detection and analysis)

## Important Notes:
- Always ensure monitor mode is enabled
- Use only on networks you own or have permission to test
- Backup original network manager configuration
- For Kismet: Log out and back in after installation for group permissions

## Manual Installation Instructions:

### For kismet (if automatic installation fails):
- Add repository key: wget -O - https://www.kismetwireless.net/kismet-release.asc | sudo gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/kismet.gpg >/dev/null
- Add repository: echo 'deb http://www.kismetwireless.net/apt/release/noble noble main' | sudo tee /etc/apt/sources.list.d/kismet.list
- Update and install: sudo apt update && sudo apt install kismet
- Add user to group: sudo usermod -aG kismet \$USER

### For fern-wifi-cracker:
- Download from: https://github.com/savio-code/fern-wifi-cracker
- Install dependencies: sudo apt install python3-pyqt5 python3-scapy
- Run: sudo python3 Fern-Wifi-Cracker/execute.py

EOF

# Create subdirectories for organized storage
sudo mkdir -p "$WIFI_DIR/captures"
sudo mkdir -p "$WIFI_DIR/handshakes"
sudo mkdir -p "$WIFI_DIR/scripts"

# Install fern-wifi-cracker and dependencies
print_status "Installing fern-wifi-cracker and dependencies..."
# Try to install fern-wifi-cracker with error handling
if apt-cache show fern-wifi-cracker >/dev/null 2>&1; then
    sudo apt install -y \
        fern-wifi-cracker \
        macchanger \
        python3-pyqt5 \
        python3-scapy \
        subversion \
        xterm
    echo "- fern-wifi-cracker: WiFi security testing GUI" | sudo tee -a "$WIFI_DIR/README.md" > /dev/null
else
    print_warning "fern-wifi-cracker not available in repositories - installing dependencies only"
    sudo apt install -y \
        macchanger \
        python3-pyqt5 \
        python3-scapy \
        subversion \
        xterm || print_warning "Some dependencies failed to install"
    echo "- fern-wifi-cracker: Not available in Ubuntu 24.04 repos - manual installation needed" | sudo tee -a "$WIFI_DIR/README.md" > /dev/null
fi

# Binary analysis and reverse engineering
print_section "Installing Additional Binary Analysis Tools"
BINARY_DIR="/opt/security-tools/binary-analysis"
print_status "Installing binary analysis tools to $BINARY_DIR..."

# Install binary analysis tools with error handling
binary_core_tools=(
    "clang"
    "radare2"
    "binwalk"
    "hashdeep"
)

for tool in "${binary_core_tools[@]}"; do
    if apt-cache show "$tool" >/dev/null 2>&1; then
        sudo apt install -y "$tool" || print_warning "Failed to install $tool"
    else
        print_warning "$tool not available in repositories"
    fi
done

# Install clang++ separately as it might have different package name
if apt-cache show "clang++" >/dev/null 2>&1; then
    sudo apt install -y "clang++" || print_warning "Failed to install clang++"
elif apt-cache show "clang" >/dev/null 2>&1; then
    print_status "clang++ included with clang package"
else
    print_warning "C++ compiler not available via clang package"
fi

# Install hex editors and additional analysis tools
print_status "Installing hex editors and analysis tools..."
hex_analysis_tools=(
    "hexedit"
    "xxd"
    "bless"
    "okteta"
)

for tool in "${hex_analysis_tools[@]}"; do
    if apt-cache show "$tool" >/dev/null 2>&1; then
        sudo apt install -y "$tool" || print_warning "Failed to install $tool"
    else
        print_warning "$tool not available in repositories"
    fi
done

# Install Android development tools
print_section "Installing Android Development Tools"
print_status "Installing Android Studio and SDK tools..."

# Install Android Studio via snap
if command_exists snap; then
    sudo snap install android-studio --classic || print_warning "Failed to install Android Studio via snap"
fi

# Install ADB and fastboot
sudo apt install -y adb fastboot android-sdk-platform-tools-common || print_warning "Some Android tools failed to install"

# Install scripting environments
print_status "Installing scripting environments..."
scripting_tools=(
    "python3-dev"
    "python3-pip"
    "nodejs"
    "npm"
    "default-jdk"
    "kotlin"
    "ruby"
    "perl"
)

for tool in "${scripting_tools[@]}"; do
    if apt-cache show "$tool" >/dev/null 2>&1; then
        sudo apt install -y "$tool" || print_warning "Failed to install $tool"
    else
        print_warning "$tool not available in repositories"
    fi
done

# Install CyberChef (web-based tool - create launcher)
print_status "Setting up CyberChef..."
CYBERCHEF_DIR="/opt/security-tools/binary-analysis/cyberchef"
sudo mkdir -p "$CYBERCHEF_DIR"

# Create CyberChef launcher script
sudo tee /usr/local/bin/cyberchef > /dev/null << 'CYBERCHEF_SCRIPT'
#!/bin/bash
echo "Opening CyberChef in your default browser..."
echo "CyberChef is a web-based tool for data analysis and manipulation"
echo "Visit: https://gchq.github.io/CyberChef/"
python3 -m webbrowser "https://gchq.github.io/CyberChef/" 2>/dev/null || \
xdg-open "https://gchq.github.io/CyberChef/" 2>/dev/null || \
echo "Please open https://gchq.github.io/CyberChef/ in your browser"
CYBERCHEF_SCRIPT
sudo chmod +x /usr/local/bin/cyberchef

# Install ImHex (modern hex editor)
print_status "Installing ImHex hex editor..."
if apt-cache show "imhex" >/dev/null 2>&1; then
    sudo apt install -y imhex || print_warning "Failed to install ImHex"
else
    print_warning "ImHex not available in repositories - download from GitHub"
fi

# Create documentation for binary analysis tools
cat << EOF | sudo tee "$BINARY_DIR/README.md" > /dev/null
# Binary Analysis & Reverse Engineering Tools

## Core Analysis Tools:
- jadx: Java decompiler for Android APK/DEX files (installed in /opt/jadx/) ⭐ MOST IMPORTANT
  - CLI version: jadx (command line decompilation)
  - GUI version: jadx-gui (graphical interface)
  - Test with: jadx /opt/security-tools/binary-analysis/test.apk
- ghidra: NSA's reverse engineering tool (via snap)
- radare2: Advanced command-line hexadecimal editor (r2 is cool!)
- binwalk: Firmware analysis tool
- clang/clang++: C/C++ compiler for analysis
- hashdeep: File hashing and integrity verification

## Hex Editors:
- hexedit: Console hex editor
- xxd: Hex dump utility
- bless: GTK+ hex editor
- okteta: KDE hex editor
- imhex: Modern hex editor (if available)

## Static Analysis:
- strings: Extract readable strings from binaries
- objdump: Display object file information
- nm: List symbols from object files
- readelf: Display ELF file information
- file: Determine file type

## Mobile Security (Android):
- android-studio: Android IDE and development tools (via snap)
- adb: Android Debug Bridge
- fastboot: Android bootloader protocol
- android-sdk-platform-tools: Android SDK platform tools

## Scripting Environments:
- python3: Python scripting
- kotlin: Kotlin programming language
- nodejs/npm: JavaScript runtime and package manager
- ruby: Ruby scripting language
- perl: Perl scripting language

## Web-based Tools:
- cyberchef: Data analysis and manipulation (run 'cyberchef' command)

## Manual installations needed:
- autospy: Digital forensics platform
- bulk-extractor: Computer forensics tool
- 010 Editor: Professional hex editor (commercial)

## Sample Analysis Workflow:
1. file sample.bin - Identify file type
2. strings sample.bin - Extract readable strings
3. hexdump -C sample.bin | head - View hex dump
4. radare2 sample.bin - Advanced analysis (r2 is cool!)
5. binwalk sample.bin - Firmware analysis
6. jadx sample.jar - Java decompilation ⭐
7. cyberchef - Web-based data manipulation
8. ghidra sample.exe - Advanced reverse engineering

## Android Analysis Workflow:
1. adb devices - List connected devices
2. adb shell - Access device shell
3. adb pull /data/app/package.apk - Extract APK
4. jadx package.apk - Decompile APK ⭐
5. android-studio - Open in IDE for analysis

## Directories:
- Samples: $BINARY_DIR/samples/
- Scripts: $BINARY_DIR/scripts/
- Reports: $BINARY_DIR/reports/
- Android: $BINARY_DIR/android/
- CyberChef: $BINARY_DIR/cyberchef/

EOF

# Create subdirectories
sudo mkdir -p "$BINARY_DIR/samples"
sudo mkdir -p "$BINARY_DIR/scripts"
sudo mkdir -p "$BINARY_DIR/reports"
sudo mkdir -p "$BINARY_DIR/android"
sudo mkdir -p "$BINARY_DIR/cyberchef"

# Try to install additional tools
binary_tools_to_try=(
    "autospy"
    "bulk-extractor"
)

for tool in "${binary_tools_to_try[@]}"; do
    if apt-cache show "$tool" >/dev/null 2>&1; then
        sudo apt install -y "$tool" || print_warning "Failed to install $tool"
        echo "- $tool: Installed via APT" | sudo tee -a "$BINARY_DIR/README.md" > /dev/null
    else
        print_warning "$tool not available in repositories"
        echo "- $tool: Manual installation needed" | sudo tee -a "$BINARY_DIR/README.md" > /dev/null
    fi
done

# Install metasploit framework (if available in repos, otherwise we'll add instructions)
print_status "Installing penetration testing frameworks..."
# Install searchsploit via snap if available
if command_exists snap; then
    sudo snap install searchsploit || print_warning "Failed to install searchsploit via snap"
fi

# Install available tools
sudo apt install -y \
    ettercap-text-only || print_warning "Failed to install ettercap"

# MITM and Interception Tools
print_section "Installing MITM & Interception Tools"
MITM_DIR="/opt/security-tools/mitm-interception"
print_status "Installing MITM and interception tools to $MITM_DIR..."

# Create MITM directory first
sudo mkdir -p "$MITM_DIR"

# Install mitmproxy
print_status "Installing mitmproxy..."
sudo apt install -y mitmproxy || print_warning "mitmproxy not available via apt"

# If mitmproxy not available via apt, install via pip
if ! command_exists mitmproxy; then
    print_status "Installing mitmproxy via pip..."
    python3 -m pip install mitmproxy --break-system-packages || print_warning "Failed to install mitmproxy via pip"
fi

# Install Frida
print_status "Installing Frida dynamic instrumentation toolkit..."
python3 -m pip install frida-tools --break-system-packages || print_warning "Failed to install Frida"

# Create Frida server downloader script
sudo tee /usr/local/bin/frida-server-android > /dev/null << 'FRIDA_SCRIPT'
#!/bin/bash
# Frida Server Downloader for Android
echo "Frida Server Android Downloader"
echo "==============================="
echo "This script helps download frida-server for Android devices"
echo ""
echo "Usage: frida-server-android [architecture]"
echo "Architectures: x86, x86_64, arm, arm64"
echo ""

ARCH=${1:-arm64}
FRIDA_VERSION=$(frida --version 2>/dev/null || echo "16.1.4")

echo "Downloading frida-server v$FRIDA_VERSION for $ARCH..."
DOWNLOAD_URL="https://github.com/frida/frida/releases/download/$FRIDA_VERSION/frida-server-$FRIDA_VERSION-android-$ARCH.xz"

mkdir -p /opt/security-tools/mitm-interception/frida
cd /opt/security-tools/mitm-interception/frida

wget "$DOWNLOAD_URL" -O "frida-server-$FRIDA_VERSION-android-$ARCH.xz"
if [ $? -eq 0 ]; then
    xz -d "frida-server-$FRIDA_VERSION-android-$ARCH.xz"
    chmod +x "frida-server-$FRIDA_VERSION-android-$ARCH"
    echo "Downloaded: frida-server-$FRIDA_VERSION-android-$ARCH"
    echo "Push to device with: adb push frida-server-$FRIDA_VERSION-android-$ARCH /data/local/tmp/frida-server"
    echo "Run on device with: adb shell 'su -c /data/local/tmp/frida-server &'"
else
    echo "Failed to download frida-server"
fi
FRIDA_SCRIPT
sudo chmod +x /usr/local/bin/frida-server-android

# Create documentation for MITM tools
cat << EOF | sudo tee "$MITM_DIR/README.md" > /dev/null
# MITM & Interception Tools

## Installed Tools:
- mitmproxy: Interactive TLS-capable intercepting HTTP proxy
- frida: Dynamic instrumentation toolkit
- ettercap: Network sniffer/interceptor/logger

## Nice to Have Tools (Manual Installation):
- Burp Suite: Web application security testing platform
- HttpToolkit: Modern HTTP debugging proxy

## Frida Tools:
- frida: Core Frida CLI
- frida-ps: List processes
- frida-trace: Trace function calls
- frida-kill: Kill processes
- frida-discover: Discover functions
- frida-server-android: Download Android frida-server

## Android Rooting & Analysis:
- Rooted Android Device preferred with production build
- KernelSU recommended for root management
- frida-server for runtime analysis

## Usage Examples:

### mitmproxy:
- mitmproxy -p 8080 --mode transparent
- mitmweb -p 8080 (web interface)

### Frida (requires root on Android):
- frida-ps -U (list processes on USB device)
- frida -U -l script.js package.name
- frida-trace -U -i "open*" package.name

### Android Setup:
1. Root device with KernelSU (preferred)
2. Download frida-server: frida-server-android arm64
3. Push to device: adb push frida-server-*-android-arm64 /data/local/tmp/frida-server
4. Run on device: adb shell 'su -c "/data/local/tmp/frida-server &"'
5. Connect from host: frida-ps -U

### Burp Suite Setup (Manual):
1. Download from: https://portswigger.net/burp/communitydownload
2. Install Java if needed
3. Configure proxy settings in browser/app

### HttpToolkit Setup (Manual):
1. Download from: https://httptoolkit.tech/
2. Install and configure certificates

## Android Emulator Setup:
- Use Android Studio AVD or real device
- Real device preferred for production build analysis
- Ensure USB debugging enabled
- Configure proxy settings for app testing

## Directories:
- Scripts: $MITM_DIR/scripts/
- Captures: $MITM_DIR/captures/
- Frida scripts: $MITM_DIR/frida/
- Certificates: $MITM_DIR/certificates/

EOF

# Create subdirectories for MITM tools
sudo mkdir -p "$MITM_DIR/scripts"
sudo mkdir -p "$MITM_DIR/captures"
sudo mkdir -p "$MITM_DIR/frida"
sudo mkdir -p "$MITM_DIR/certificates"

# Network analysis and manipulation tools
print_status "Installing network analysis tools..."
network_analysis_tools=(
    "netsniff-ng"
    "tcpdump"
    "wireshark"
)

for tool in "${network_analysis_tools[@]}"; do
    if apt-cache show "$tool" >/dev/null 2>&1; then
        sudo apt install -y "$tool" || print_warning "Failed to install $tool"
    else
        print_warning "$tool not available in repositories"
    fi
done

# Try to install responder separately (may not be available in Ubuntu 24.04)
if apt-cache show responder >/dev/null 2>&1; then
    sudo apt install -y responder || print_warning "Failed to install responder"
else
    print_warning "responder not available in repositories - can be installed via pip: pip3 install responder"
fi

# mitmproxy is already installed above in MITM section, but check if it needs to be installed here too
if ! command_exists mitmproxy; then
    if apt-cache show mitmproxy >/dev/null 2>&1; then
        sudo apt install -y mitmproxy || print_warning "Failed to install mitmproxy"
    else
        print_warning "mitmproxy not available via apt"
    fi
fi

# Post-exploitation and pivoting tools
print_status "Installing post-exploitation tools..."
post_exploitation_tools=(
    "netcat-traditional"
    "proxychains4"
    "weevely"
)

for tool in "${post_exploitation_tools[@]}"; do
    if apt-cache show "$tool" >/dev/null 2>&1; then
        sudo apt install -y "$tool" || print_warning "Failed to install $tool"
    else
        print_warning "$tool not available in repositories"
    fi
done

# Try to install evil-winrm separately (may not be available in Ubuntu 24.04)
if apt-cache show evil-winrm >/dev/null 2>&1; then
    sudo apt install -y evil-winrm || print_warning "Failed to install evil-winrm"
else
    print_warning "evil-winrm not available in repositories - can be installed via gem: sudo gem install evil-winrm"
fi

# Digital forensics tools
print_status "Installing digital forensics tools..."
digital_forensics_tools=(
    "cherrytree"
    "cutycapt"
    "recordmydesktop"
)

for tool in "${digital_forensics_tools[@]}"; do
    if apt-cache show "$tool" >/dev/null 2>&1; then
        sudo apt install -y "$tool" || print_warning "Failed to install $tool"
    else
        print_warning "$tool not available in repositories"
    fi
done

# Install Pipal from source (password analysis tool)
print_status "Installing Pipal (password analysis tool) from source..."
PIPAL_DIR="/opt/security-tools/password-cracking/pipal"
if [ ! -d "$PIPAL_DIR" ]; then
    print_status "Cloning Pipal repository..."
    sudo git clone https://github.com/digininja/pipal.git "$PIPAL_DIR"
    
    # Install Ruby and bundler if not already installed
    sudo apt install -y ruby ruby-dev bundler || print_warning "Failed to install Ruby dependencies"
    
    # Install Pipal dependencies
    cd "$PIPAL_DIR"
    if command_exists bundle; then
        sudo bundle install || print_warning "Failed to install Pipal Ruby gems"
    else
        print_warning "Bundler not available - Pipal may not work properly"
    fi
    
    # Create a convenient launcher script
    sudo tee /usr/local/bin/pipal > /dev/null << 'PIPAL_SCRIPT'
#!/bin/bash
cd /opt/security-tools/password-cracking/pipal
ruby pipal.rb "$@"
PIPAL_SCRIPT
    sudo chmod +x /usr/local/bin/pipal
    
    print_status "Pipal installed to $PIPAL_DIR"
    print_status "Use 'pipal <password_file>' to analyze password dumps"
    print_status "Example: pipal --output=analysis_report.txt rockyou.txt"
else
    print_status "Pipal already installed at $PIPAL_DIR"
fi

# Detection and Analysis Tools
print_section "Installing Detection & Analysis Tools"
DETECTION_DIR="/opt/security-tools/detection-analysis"
print_status "Installing detection and analysis tools to $DETECTION_DIR..."

# Ensure directory exists
sudo mkdir -p "$DETECTION_DIR"

# Install YARA for malware identification
print_status "Installing YARA..."
sudo apt install -y yara || print_warning "YARA not available in repositories"

# Install additional detection tools
detection_tools=(
    "clamav"
    "clamav-daemon"
    "rkhunter"
    "chkrootkit"
)

# Set non-interactive mode for package installation
export DEBIAN_FRONTEND=noninteractive

for tool in "${detection_tools[@]}"; do
    if apt-cache show "$tool" >/dev/null 2>&1; then
        # Pre-configure packages to avoid interactive prompts
        if [ "$tool" = "rkhunter" ] || [ "$tool" = "chkrootkit" ]; then
            # Set postfix to non-interactive mode to avoid mail server configuration
            echo "postfix postfix/main_mailer_type select No configuration" | sudo debconf-set-selections
            echo "postfix postfix/mailname string localhost" | sudo debconf-set-selections
        fi
        sudo apt install -y "$tool" || print_warning "Failed to install $tool"
    else
        print_warning "$tool not available in repositories"
    fi
done

# Reset DEBIAN_FRONTEND
unset DEBIAN_FRONTEND

# Install SNORT (network intrusion detection)
print_status "Installing SNORT network intrusion detection..."
if apt-cache show "snort" >/dev/null 2>&1; then
    # Pre-configure SNORT to avoid interactive prompts
    export DEBIAN_FRONTEND=noninteractive
    echo "snort snort/address_range string 192.168.0.0/16" | sudo debconf-set-selections
    echo "snort snort/interface string any" | sudo debconf-set-selections
    echo "snort snort/startup boolean false" | sudo debconf-set-selections
    
    sudo apt install -y snort || print_warning "Failed to install SNORT"
    unset DEBIAN_FRONTEND
else
    print_warning "SNORT not available in repositories - manual installation needed"
fi

# Create documentation for detection tools
cat << EOF | sudo tee "$DETECTION_DIR/README.md" > /dev/null
# Detection & Analysis Tools

## Installed Tools:
- yara: Pattern matching engine for malware identification
- clamav: Open-source antivirus engine
- rkhunter: Rootkit detection tool
- chkrootkit: Local rootkit detection tool
- snort: Network intrusion detection system (if available)

## Manual Installation Needed:
- Virus Total API integration
- Custom YARA rules
- SNORT rules and configuration

## Usage Examples:

### YARA:
- yara rules.yar target_file
- yara -r rules/ target_directory/

### ClamAV:
- clamscan -r /path/to/scan
- freshclam (update virus definitions)

### SNORT (if installed):
- snort -A console -q -c /etc/snort/snort.conf -i eth0

### Detection Workflow:
1. Update virus definitions: sudo freshclam
2. Scan with ClamAV: clamscan -r --infected target/
3. Check for rootkits: sudo rkhunter --check
4. YARA analysis: yara custom_rules.yar suspicious_file
5. Network monitoring: sudo snort -A console -i eth0

## Virus Total Integration:
- Sign up at: https://www.virustotal.com/
- Get API key for automated scanning
- Use python-virustotal-api package

## YARA Rules Resources:
- https://github.com/Yara-Rules/rules
- https://github.com/Neo23x0/signature-base
- Custom rules for specific threats

## Directories:
- YARA rules: $DETECTION_DIR/yara-rules/
- Scan results: $DETECTION_DIR/scan-results/
- SNORT logs: $DETECTION_DIR/snort-logs/
- Quarantine: $DETECTION_DIR/quarantine/

EOF

# Create subdirectories for detection tools
sudo mkdir -p "$DETECTION_DIR/yara-rules"
sudo mkdir -p "$DETECTION_DIR/scan-results"
sudo mkdir -p "$DETECTION_DIR/snort-logs"
sudo mkdir -p "$DETECTION_DIR/quarantine"

# Download some basic YARA rules
print_status "Downloading basic YARA rules..."
if command_exists git && command_exists yara; then
    sudo git clone https://github.com/Yara-Rules/rules.git "$DETECTION_DIR/yara-rules/yara-rules-repo" || print_warning "Failed to clone YARA rules repository"
fi

# Hardware and embedded tools
print_section "Installing Hardware & Embedded Tools"
HARDWARE_DIR="/opt/security-tools/hardware-embedded"
print_status "Installing hardware and embedded tools to $HARDWARE_DIR..."

sudo apt install -y \
    esptool \
    can-utils \
    audacity \
    gqrx-sdr

# Create documentation for hardware tools
cat << EOF | sudo tee "$HARDWARE_DIR/README.md" > /dev/null
# Hardware & Embedded Security Tools

## Installed Tools:
- esptool: ESP8266/ESP32 firmware flashing tool
- can-utils: CAN bus utilities for automotive testing
- audacity: Audio analysis and manipulation
- gqrx-sdr: Software defined radio receiver

## Manual installations needed:
- arduino: Arduino IDE for embedded development
- minicom: Serial communication program
- putty: Terminal emulator for serial connections

## Usage Examples:
- esptool.py --port /dev/ttyUSB0 read_flash 0x00000 0x400000 flash_dump.bin
- candump can0 - Monitor CAN bus traffic
- minicom -D /dev/ttyUSB0 -b 115200 - Serial communication
- gqrx - SDR analysis (GUI)

## Hardware Testing:
- Firmware dumps: $HARDWARE_DIR/firmware/
- CAN captures: $HARDWARE_DIR/can-logs/
- Serial logs: $HARDWARE_DIR/serial-logs/
- SDR recordings: $HARDWARE_DIR/sdr-captures/

EOF

# Create subdirectories
sudo mkdir -p "$HARDWARE_DIR/firmware"
sudo mkdir -p "$HARDWARE_DIR/can-logs"
sudo mkdir -p "$HARDWARE_DIR/serial-logs"
sudo mkdir -p "$HARDWARE_DIR/sdr-captures"

# Install Arduino IDE (if available)
if apt-cache search arduino | grep -q "arduino "; then
    sudo apt install -y arduino
    echo "- arduino: Arduino IDE installed via APT" | sudo tee -a "$HARDWARE_DIR/README.md" > /dev/null
else
    print_warning "Arduino IDE not available via APT - download from arduino.cc"
    echo "- arduino: Download from https://www.arduino.cc/en/software" | sudo tee -a "$HARDWARE_DIR/README.md" > /dev/null
fi

# Additional utilities
print_status "Installing additional utilities..."
additional_tools_to_try=(
    "maltego"
    "faraday"
)

for tool in "${additional_tools_to_try[@]}"; do
    if apt-cache show "$tool" >/dev/null 2>&1; then
        print_status "Installing $tool..."
        sudo apt install -y "$tool" || print_warning "Failed to install $tool"
    else
        print_warning "$tool not available in repositories - check manual installation"
    fi
done

# Install tools via alternate methods
print_status "Installing additional tools via alternate methods..."

# Install Go (needed for some security tools)
if ! command_exists go; then
    print_status "Installing Go programming language..."
    sudo apt install -y golang-go
fi

# Install some tools via go
if command_exists go; then
    print_status "Installing Go-based security tools..."
    
    # Install amass via go if not available via apt
    if ! command_exists amass; then
        print_status "Installing amass via go..."
        go install -v github.com/owasp-amass/amass/v4/cmd/amass@latest || print_warning "Failed to install amass via go"
    fi
    
    # Install ffuf via go if not available via apt
    if ! command_exists ffuf; then
        print_status "Installing ffuf via go..."
        go install github.com/ffuf/ffuf/v2@latest || print_warning "Failed to install ffuf via go"
    fi
fi

# Verify installations
echo ""
echo "=========================================="
echo "Installation Verification"
echo "=========================================="

# Check Python3
if command_exists python3; then
    print_status "✓ Python3: $(python3 --version)"
else
    print_error "✗ Python3 not found"
fi

# Check pip3
if command_exists pip3; then
    print_status "✓ pip3: $(pip3 --version)"
else
    print_error "✗ pip3 not found"
fi

# Check VS Code
if command_exists code; then
    print_status "✓ Visual Studio Code: $(code --version | head -n1)"
else
    print_error "✗ Visual Studio Code not found"
fi

# Check Ghidra
if snap list | grep -q ghidra; then
    print_status "✓ Ghidra installed via snap"
else
    print_error "✗ Ghidra not found"
fi

# Check JADX
if command_exists jadx; then
    print_status "✓ JADX: $(jadx --version 2>/dev/null || echo 'installed')"
else
    print_error "✗ JADX not found"
fi

# Check Wine
if command_exists wine; then
    print_status "✓ Wine: $(wine --version)"
else
    print_error "✗ Wine not found"
fi

# Check tmux
if command_exists tmux; then
    print_status "✓ tmux: $(tmux -V)"
else
    print_error "✗ tmux not found"
fi

# Check nmap
if command_exists nmap; then
    print_status "✓ nmap: $(nmap --version | head -n1)"
else
    print_error "✗ nmap not found"
fi

# Check Java
if command_exists java; then
    print_status "✓ Java (default): $(java -version 2>&1 | head -n1)"
    if command -v java-17-openjdk >/dev/null 2>&1 || [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
        print_status "✓ Java 17: OpenJDK 17 installed"
    fi
    if command -v java-21-openjdk >/dev/null 2>&1 || [ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]; then
        print_status "✓ Java 21: OpenJDK 21 installed"
    fi
else
    print_error "✗ Java not found"
fi

# Check metasploit (if installed)
if command_exists msfconsole; then
    print_status "✓ Metasploit Framework installed"
else
    print_warning "⚠ Metasploit Framework not found - may need manual installation"
fi

# Check aircrack-ng
if command_exists aircrack-ng; then
    print_status "✓ aircrack-ng: $(aircrack-ng --help 2>&1 | head -n1 | grep -o 'Aircrack-ng [0-9.]*' || echo 'installed')"
else
    print_error "✗ aircrack-ng not found"
fi

# Check hydra
if command_exists hydra; then
    print_status "✓ Hydra: $(hydra -h 2>&1 | head -n1 | grep -o 'Hydra v[0-9.]*' || echo 'installed')"
else
    print_error "✗ Hydra not found"
fi

# Check MITM tools
if command_exists mitmproxy; then
    print_status "✓ mitmproxy: $(mitmproxy --version 2>/dev/null || echo 'installed')"
else
    print_error "✗ mitmproxy not found"
fi

# Check Frida
if command_exists frida; then
    print_status "✓ Frida: $(frida --version 2>/dev/null || echo 'installed')"
else
    print_error "✗ Frida not found"
fi

# Check Android tools
if command_exists adb; then
    print_status "✓ ADB: $(adb --version 2>/dev/null | head -n1 || echo 'installed')"
else
    print_error "✗ ADB not found"
fi

# Check Android Studio
if snap list | grep -q android-studio; then
    print_status "✓ Android Studio installed via snap"
else
    print_warning "⚠ Android Studio not found - may need manual installation"
fi

# Check YARA
if command_exists yara; then
    print_status "✓ YARA: $(yara --version 2>/dev/null || echo 'installed')"
else
    print_error "✗ YARA not found"
fi

# Check hex editors
if command_exists hexedit; then
    print_status "✓ hexedit installed"
else
    print_error "✗ hexedit not found"
fi

# Check radare2
if command_exists radare2; then
    print_status "✓ radare2: $(r2 -version 2>/dev/null | head -n1 || echo 'installed')"
else
    print_error "✗ radare2 not found"
fi

# Check CyberChef launcher
if [ -f "/usr/local/bin/cyberchef" ]; then
    print_status "✓ CyberChef launcher installed"
else
    print_error "✗ CyberChef launcher not found"
fi

echo ""
print_status "Setup completed! You may need to restart your terminal or log out and back in for all changes to take effect."
print_status "To configure Wine, run: winecfg"
print_status "To start JADX GUI, run: jadx-gui"

echo ""
print_warning "Additional Manual Setup Required:"
print_warning "1. Java Version Switching:"
print_warning "   sudo update-alternatives --config java  # Switch between Java versions"
print_warning "   sudo update-alternatives --config javac # Switch between Java compilers"
print_warning "2. Android Security Tools:"
print_warning "   - Set up Android emulator or real device with root access"
print_warning "   - Install KernelSU for rooted device management (preferred over Magisk)"
print_warning "   - Configure frida-server: frida-server-android arm64"
print_warning "3. MITM & Interception Tools:"
print_warning "   - Download Burp Suite Community: https://portswigger.net/burp/communitydownload"
print_warning "   - Download HttpToolkit: https://httptoolkit.tech/"
print_warning "4. Advanced Reverse Engineering:"
print_warning "   - Download IDA Pro (commercial): https://hex-rays.com/ida-pro/"
print_warning "   - Download 010 Editor (commercial): https://www.sweetscape.com/010editor/"
print_warning "   - Install ImHex (if not available): https://github.com/WerWolv/ImHex"
print_warning "5. Detection & Analysis:"
print_warning "   - Set up Virus Total API account and integrate API key"
print_warning "   - Configure SNORT rules for your network"
print_warning "   - Download additional YARA rules for specific threats"
print_warning "6. Metasploit Framework:"
print_warning "   curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && chmod 755 msfinstall && ./msfinstall"
print_warning "7. Additional Mobile Security:"
print_warning "   - Set up Android device with production build (not userdebug)"
print_warning "   - Configure device for security testing with proper root access"
print_warning "8. Everything Else:"
print_warning "   - Always be ready to learn and adapt tools for specific scenarios"
print_warning "   - radare2 is cool for advanced binary analysis"
print_warning "   - medusa is a heavier alternative to frida for some use cases"

echo ""
print_status "Manual Installation Commands for Missing Tools:"
echo "# JADX is now installed system-wide and available via:"
echo "jadx --version                           # Check JADX CLI version"
echo "jadx-gui                                 # Launch JADX GUI"
echo "jadx /path/to/app.apk                    # Decompile APK file"
echo ""
echo "# Switch Java versions:"
echo "sudo update-alternatives --config java   # Choose default Java version"
echo "sudo update-alternatives --config javac  # Choose default Java compiler"
echo ""
echo "# Install Metasploit Framework:"
echo "curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && chmod 755 msfinstall && ./msfinstall"
echo ""
echo "# Install WPScan (Ruby gem):"
echo "sudo gem install wpscan"
echo ""
echo "# Mobile Security Setup:"
echo "# 1. Root Android device with KernelSU (preferred):"
echo "#    Download from: https://kernelsu.org/"
echo "# 2. Set up Frida server on Android:"
echo "frida-server-android arm64  # Download frida-server"
echo "adb push frida-server-*-android-arm64 /data/local/tmp/frida-server"
echo "adb shell 'su -c \"/data/local/tmp/frida-server &\"'"
echo ""
echo "# Advanced Tools (Commercial):"
echo "# - IDA Pro: https://hex-rays.com/ida-pro/"
echo "# - 010 Editor: https://www.sweetscape.com/010editor/"
echo "# - Burp Suite Pro: https://portswigger.net/burp/pro"
echo ""
echo "# Detection Tools Setup:"
echo "# - Virus Total API: https://www.virustotal.com/gui/join-us"
echo "# - SNORT rules: https://www.snort.org/downloads#rule-downloads"
echo "# - Additional YARA rules: https://github.com/Yara-Rules/rules"
echo ""
echo "# Add Go tools to PATH:"
echo "echo 'export PATH=\$PATH:~/go/bin' >> ~/.bashrc"

echo ""
print_status "Useful Commands Reference:"
echo "# Essential Analysis Commands:"
echo "tmux - Terminal multiplexer"
echo "jadx sample.apk - Java/Android decompilation ⭐ MOST IMPORTANT"
echo "jadx-gui - Launch JADX graphical interface ⭐"
echo "radare2 binary - Advanced binary analysis (r2 is cool!)"
echo "cyberchef - Web-based data manipulation and analysis"
echo "ghidra - Advanced reverse engineering (GUI)"
echo ""
echo "# Network & Web Testing:"
echo "nmap -sS target - TCP SYN scan"
echo "mitmproxy -p 8080 - HTTP/HTTPS interception"
echo "sqlmap -u 'URL' --dbs - SQL injection testing"
echo "hydra -l user -P passwords.txt target ssh - Brute force SSH"
echo ""
echo "# Mobile & Android Security:"
echo "adb devices - List connected Android devices"
echo "frida-ps -U - List processes on USB device"
echo "frida -U -l script.js package.name - Runtime manipulation"
echo ""
echo "# WiFi Security:"
echo "aircrack-ng -w wordlist capture.cap - Crack WiFi"
echo "wifite --kill - Automated WiFi attacks"
echo ""
echo "# Detection & Analysis:"
echo "yara rules.yar suspicious_file - Malware pattern matching"
echo "clamscan -r /path/to/scan - Antivirus scanning"
echo "rkhunter --check - Rootkit detection"
echo "pipal wordlist.txt - Password analysis and statistics"
echo ""
echo "# Other Frameworks:"
echo "recon-ng - Web reconnaissance framework"
echo "msfconsole - Metasploit console (if installed)"

echo ""
print_status "To reload shell environment for pipx: exec \$SHELL"

echo ""
print_header "Tool Directory Structure"
print_status "All tools have been organized in /opt/security-tools/"
echo ""
echo "📁 /opt/security-tools/"
echo "├── 🔍 network-recon/          - Network reconnaissance tools"
echo "├── 🌐 web-testing/            - Web application security tools"
echo "├── 🔓 password-cracking/      - Password & hash cracking tools"
echo "├── 📡 wifi-hacking/           - WiFi security testing tools"
echo "├── ⚙️  binary-analysis/        - Reverse engineering & binary analysis ⭐"
echo "│   ├── jadx/                 - Java decompiler (MOST IMPORTANT) ⭐"
echo "│   ├── android/              - Android analysis tools"
echo "│   └── cyberchef/            - Web-based data manipulation"
echo "├── 🔧 hardware-embedded/      - Hardware & embedded security tools"
echo "├── 🕵️  post-exploitation/      - Post-exploitation tools"
echo "├── 🔬 digital-forensics/      - Digital forensics tools"
echo "├── 🚫 mitm-interception/      - MITM & interception tools"
echo "│   ├── frida/                - Dynamic instrumentation"
echo "│   ├── captures/             - Network captures"
echo "│   └── certificates/         - Proxy certificates"
echo "├── 🛡️  detection-analysis/     - Detection & analysis tools"
echo "│   ├── yara-rules/           - YARA malware detection rules"
echo "│   ├── scan-results/         - Antivirus scan results"
echo "│   └── snort-logs/           - Network intrusion logs"
echo "├── 💻 development/            - Development tools & environments"
echo "└── 📚 documentation/          - Tool documentation & guides"
echo ""
print_status "Mobile Security Focus Areas:"
echo "🤖 Android Analysis: JADX ⭐, Android Studio, ADB, Frida"
echo "🔍 Static Analysis: Ghidra, radare2 (r2 is cool!), strings, objdump"
echo "🌐 Dynamic Analysis: Frida, mitmproxy, Burp Suite"
echo "📱 Device Requirements: Rooted Android with KernelSU (preferred)"
echo "🔧 Scripting: Python, Kotlin, JavaScript/Node.js"
echo ""
print_status "Each directory contains a README.md with tool descriptions and usage examples"
print_status "Access tools via: ls /opt/security-tools/[category]/"
print_status "View documentation: cat /opt/security-tools/[category]/README.md"

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
