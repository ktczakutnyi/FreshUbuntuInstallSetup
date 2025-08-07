# FreshUbuntuInstallSetup
# Ubuntu 24.04 Security Tools Setup Script

A comprehensive security toolkit installer for Ubuntu 24.04 LTS, specializing in mobile security analysis, Android reverse engineering, and penetration testing tools.

## 🎯 Overview

This script automatically installs and configures a complete security analysis environment with over 50 tools organized into specialized categories. It focuses on mobile security, Android reverse engineering, and comprehensive penetration testing capabilities.

## 🚀 Quick Start

```bash
# Clone or download the script
cd /home/nuclear/startUp
chmod +x ubuntu24-setup.sh

# Run the installation (requires sudo)
./ubuntu24-setup.sh
```

## 📁 Directory Structure

All tools are organized in `/opt/security-tools/` with the following structure:

```
📁 /opt/security-tools/
├── 🔍 network-recon/          - Network reconnaissance tools
├── 🌐 web-testing/            - Web application security tools
├── 🔓 password-cracking/      - Password & hash cracking tools
├── 📡 wifi-hacking/           - WiFi security testing tools
├── ⚙️  binary-analysis/        - Reverse engineering & binary analysis ⭐
│   ├── jadx/                 - Java decompiler (MOST IMPORTANT) ⭐
│   ├── android/              - Android analysis tools
│   └── cyberchef/            - Web-based data manipulation
├── 🔧 hardware-embedded/      - Hardware & embedded security tools
├── 🕵️  post-exploitation/      - Post-exploitation tools
├── 🔬 digital-forensics/      - Digital forensics tools
├── 🛡️  mitm-interception/      - MITM & interception tools
│   ├── frida/                - Dynamic instrumentation
│   ├── captures/             - Network captures
│   └── certificates/         - Proxy certificates
├── 🚫 detection-analysis/     - Detection & analysis tools
│   ├── yara-rules/           - YARA malware detection rules
│   ├── scan-results/         - Antivirus scan results
│   └── snort-logs/           - Network intrusion logs
├── 💻 development/            - Development tools & environments
└── 📚 documentation/          - Tool documentation & guides
```

Each directory contains a `README.md` file with detailed tool descriptions and usage examples.

## 🛠️ What Gets Installed Automatically

### ⭐ Core Mobile Security Tools
- **JADX v1.5.2** - Java/Android decompiler (MOST IMPORTANT)
- **Android Studio** - Full Android IDE
- **ADB/fastboot** - Android debugging tools
- **Ghidra** - NSA's reverse engineering framework
- **radare2** - Advanced binary analysis (r2 is cool!)

### 🌐 Network & Web Security
- **nmap** - Network scanning
- **nikto** - Web vulnerability scanner
- **sqlmap** - SQL injection testing
- **SpiderFoot** - OSINT automation
- **recon-ng** - Web reconnaissance framework

### 📡 WiFi Security
- **aircrack-ng** - WiFi security testing suite
- **wifite** - Automated WiFi attacks
- **kismet** - Wireless network detector
- **reaver** - WPS attack tool

### 🔓 Password Cracking
- **hashcat** - Advanced password recovery
- **hydra** - Network login cracker
- **john** - John the Ripper
- **pipal** - Password analysis tool

### 🛡️ Detection & Analysis
- **YARA** - Malware pattern matching
- **ClamAV** - Antivirus engine
- **SNORT** - Network intrusion detection
- **rkhunter/chkrootkit** - Rootkit detection

### 🔧 Development Environment
- **Python 3.12.3** with pip
- **Java 17 & 21** (OpenJDK)
- **Go** programming language
- **Wine 10.0** - Windows compatibility
- **tmux** with mouse mode enabled

## 🎮 tmux Enhanced Configuration

The script configures tmux with powerful productivity features:

### Features Enabled:
- ✅ **Mouse mode** - Use mouse for scrolling, pane selection, and resizing
- ✅ **256 color support** for better visual experience
- ✅ **Smart navigation** - Alt+arrows for panes, Shift+arrows for windows
- ✅ **Vim-style copy mode** with improved key bindings
- ✅ **10,000 line scrollback buffer**
- ✅ **Custom status bar** with time and date

### tmux Usage:
```bash
# Start tmux
tmux

# Navigation (no prefix needed)
Alt + ←/→/↑/↓     # Navigate between panes
Shift + ←/→       # Switch between windows

# Splitting (prefix + key)
Ctrl+B, then |    # Split horizontally
Ctrl+B, then -    # Split vertically

# Essential commands
Ctrl+B, then d    # Detach from session
tmux attach        # Re-attach to session
tmux list-sessions # List all sessions
Ctrl+B, then r    # Reload config
```

## 🎯 Essential Tool Usage

### 📱 Android Analysis (Most Important)

#### JADX - Java Decompiler ⭐
```bash
# Check version
jadx --version

# Decompile APK (command line)
jadx /path/to/app.apk

# Launch GUI
jadx-gui

# Test with provided sample
jadx /opt/security-tools/binary-analysis/test.apk
```

#### Android Studio & ADB
```bash
# Launch Android Studio
android-studio

# ADB commands
adb devices                    # List connected devices
adb shell                      # Access device shell
adb install app.apk           # Install APK
adb pull /data/app/package.apk # Extract APK from device
adb logcat                    # View device logs
```

### 🔍 Binary Analysis

#### Ghidra (NSA Tool)
```bash
# Launch Ghidra
ghidra

# Command line analysis (if available)
analyzeHeadless /path/to/project ProjectName -import binary.exe
```

#### radare2 (r2 is cool!)
```bash
# Open binary for analysis
r2 binary.exe

# Basic radare2 commands (inside r2)
aaa     # Auto analyze
pdf     # Print disassembly of function
VV      # Visual mode with graphs
q       # Quit

# Command line analysis
r2 -A binary.exe   # Auto-analyze on load
```

#### CyberChef (Web-based)
```bash
# Open CyberChef in browser
cyberchef
```

### 🌐 Network Reconnaissance

#### nmap - Network Scanning
```bash
# Basic scan
nmap target.com

# TCP SYN scan
nmap -sS target.com

# Service version detection
nmap -sV target.com

# Comprehensive scan
nmap -A -T4 target.com

# Scan network range
nmap 192.168.1.0/24
```

#### SpiderFoot - OSINT
```bash
# Command line
spiderfoot -t target.com

# Web interface
spiderfoot-web
# Then open http://127.0.0.1:5001
```

#### recon-ng Framework
```bash
# Start recon-ng
recon-ng

# Inside recon-ng
workspaces create target_workspace
modules search
modules load recon/domains-hosts/brute_hosts
info
options set SOURCE target.com
run
```

### 📡 WiFi Security Testing

#### aircrack-ng Suite
```bash
# Put interface in monitor mode
sudo airmon-ng start wlan0

# Capture packets
sudo airodump-ng wlan0mon

# Capture specific network
sudo airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w capture wlan0mon

# Crack WPA/WPA2
aircrack-ng -w wordlist.txt capture.cap
```

#### wifite - Automated
```bash
# Kill interfering processes and start
sudo wifite --kill

# Target specific network
sudo wifite --wpa --dict /usr/share/wordlists/rockyou.txt
```

### 🔓 Password Cracking

#### hashcat - GPU Acceleration
```bash
# MD5 hash cracking
hashcat -m 0 -a 0 hashes.txt wordlist.txt

# WPA/WPA2 handshake
hashcat -m 2500 -a 0 handshake.hccapx wordlist.txt

# Show cracked passwords
hashcat -m 0 hashes.txt --show
```

#### hydra - Network Login
```bash
# SSH brute force
hydra -l admin -P passwords.txt target ssh

# HTTP form brute force
hydra -l admin -P passwords.txt target.com http-post-form "/login:user=^USER^&pass=^PASS^:Invalid"

# FTP brute force
hydra -L users.txt -P passwords.txt target ftp
```

#### john - John the Ripper
```bash
# Crack password hashes
john --wordlist=wordlist.txt hashes.txt

# Show cracked passwords
john --show hashes.txt

# Generate wordlist with rules
john --wordlist=base.txt --rules --stdout > generated.txt
```

### 🌐 Web Application Testing

#### sqlmap - SQL Injection
```bash
# Basic injection test
sqlmap -u "http://target.com/page.php?id=1"

# Enumerate databases
sqlmap -u "http://target.com/page.php?id=1" --dbs

# Dump specific table
sqlmap -u "http://target.com/page.php?id=1" -D database -T users --dump

# POST data injection
sqlmap -u "http://target.com/login" --data="user=admin&pass=test"
```

### 🛡️ Detection & Analysis

#### YARA - Malware Detection
```bash
# Scan file with rules
yara rules.yar suspicious_file

# Recursive directory scan
yara -r rules.yar /path/to/scan/

# Use downloaded rule repository
yara /opt/security-tools/detection-analysis/yara-rules/yara-rules-repo/malware/*.yar sample.exe
```

#### ClamAV - Antivirus
```bash
# Update virus definitions
sudo freshclam

# Scan directory
clamscan -r /path/to/scan

# Scan and move infected files
clamscan -r --infected --move=/quarantine /path/to/scan
```

### 🔧 Hardware & Embedded

#### esptool - ESP32/ESP8266
```bash
# Read flash
esptool.py --port /dev/ttyUSB0 read_flash 0x00000 0x400000 flash_dump.bin

# Flash firmware
esptool.py --port /dev/ttyUSB0 write_flash 0x00000 firmware.bin
```

## ⚠️ Manual Setup Required

### 1. Install Missing Frida
```bash
# Install Frida tools
python3 -m pip install frida-tools --break-system-packages

# Verify installation
frida --version
```

### 2. Metasploit Framework
```bash
# Download and install Metasploit
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod 755 msfinstall
./msfinstall

# Start Metasploit
msfconsole
```

### 3. Mobile Security Setup

#### Root Android Device with KernelSU (Preferred)
1. Download KernelSU from: https://kernelsu.org/
2. Follow device-specific installation instructions
3. Verify root access: `adb shell su`

#### Setup Frida Server on Android
```bash
# Download frida-server for your device architecture
frida-server-android arm64

# Push to device
adb push frida-server-*-android-arm64 /data/local/tmp/frida-server

# Make executable and run
adb shell "su -c 'chmod +x /data/local/tmp/frida-server'"
adb shell "su -c '/data/local/tmp/frida-server &'"

# Test connection
frida-ps -U
```

### 4. Burp Suite Community
```bash
# Download from: https://portswigger.net/burp/communitydownload
# Install Java if needed, then run:
java -jar burpsuite_community_*.jar
```

### 5. Additional Go Tools
```bash
# Add Go tools to PATH
echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verify amass installation
amass --version
```

## 🔧 Configuration Files

### Java Version Switching
```bash
# Switch between Java versions
sudo update-alternatives --config java
sudo update-alternatives --config javac

# Check current version
java -version
javac -version
```

### Wine Configuration
```bash
# Configure Wine
winecfg

# Install Windows applications
wine setup.exe
```

## 📚 Documentation & Learning Resources

### Tool Documentation
Each category directory contains detailed README.md files:
```bash
# View network tools documentation
cat /opt/security-tools/network-recon/README.md

# View binary analysis guide
cat /opt/security-tools/binary-analysis/README.md

# View WiFi hacking documentation
cat /opt/security-tools/wifi-hacking/README.md
```

### Example Analysis Workflows

#### Android APK Analysis Workflow
```bash
# 1. Extract APK from device or download
adb pull /data/app/com.example.app/base.apk app.apk

# 2. Static analysis with JADX ⭐
jadx app.apk                 # Command line
jadx-gui                     # GUI analysis

# 3. Binary analysis
file app.apk
unzip app.apk -d extracted/
strings extracted/classes.dex

# 4. Dynamic analysis (requires rooted device)
frida-ps -U                  # List processes
frida -U -f com.example.app  # Hook application
```

#### Web Application Testing Workflow
```bash
# 1. Reconnaissance
nmap -sV target.com
nikto -h target.com

# 2. Directory enumeration
dirb http://target.com /usr/share/wordlists/dirb/common.txt

# 3. SQL injection testing
sqlmap -u "http://target.com/login.php" --forms --batch

# 4. Manual testing with Burp Suite
# Configure browser proxy to 127.0.0.1:8080
# Launch Burp Suite and intercept traffic
```

## 🚨 Security & Legal Considerations

### ⚠️ Important Legal Notice
- **Only use these tools on systems you own or have explicit permission to test**
- **Unauthorized access to computer systems is illegal**
- **Always follow responsible disclosure practices**
- **Respect privacy and data protection laws**

### Best Practices
- Test in isolated environments first
- Keep tools updated regularly
- Use VPNs for anonymity when legally testing
- Document all testing activities
- Follow your organization's security policies

## 🔧 Troubleshooting

### Common Issues

#### JADX Not Found
```bash
# Check installation
which jadx
jadx --version

# If not found, add to PATH
echo 'export PATH=$PATH:/opt/jadx/bin' >> ~/.bashrc
source ~/.bashrc
```

#### Android Device Not Detected
```bash
# Check USB debugging
adb devices

# Restart ADB server
adb kill-server
adb start-server

# Check device permissions
lsusb
```

#### Frida Connection Issues
```bash
# Check frida-server is running on device
adb shell "su -c 'ps | grep frida'"

# Restart frida-server
adb shell "su -c 'killall frida-server'"
adb shell "su -c '/data/local/tmp/frida-server &'"
```

#### WiFi Monitor Mode Issues
```bash
# Kill interfering processes
sudo airmon-ng check kill

# Restart network manager after testing
sudo systemctl restart NetworkManager
```

## 🆕 Updates & Maintenance

### Keeping Tools Updated
```bash
# Update system packages
sudo apt update && sudo apt upgrade

# Update Python packages
python3 -m pip install --upgrade pip --break-system-packages
python3 -m pip list --outdated --break-system-packages

# Update Go tools
go install -a github.com/owasp-amass/amass/v4/cmd/amass@latest

# Update YARA rules
cd /opt/security-tools/detection-analysis/yara-rules/yara-rules-repo
sudo git pull
```

### Backup Important Configurations
```bash
# Backup tmux configuration
cp ~/.tmux.conf ~/tmux-backup.conf

# Backup tool configurations
tar -czf security-tools-backup.tar.gz /opt/security-tools/*/README.md
```

## 📞 Support & Contributing

### Getting Help
- Check tool-specific documentation in `/opt/security-tools/[category]/README.md`
- Consult official tool documentation
- Join security communities and forums
- Practice in legal testing environments

### Script Features
- ✅ Ubuntu 24.04 LTS compatibility
- ✅ Comprehensive error handling
- ✅ Organized directory structure
- ✅ Non-interactive installation
- ✅ Mouse-enabled tmux configuration
- ✅ Latest tool versions (JADX 1.5.2, etc.)
- ✅ Mobile security focus
- ✅ Detailed documentation

---

**Remember: With great power comes great responsibility. Use these tools ethically and legally!**

## 🏷️ Script Information
- **Version**: Ubuntu 24.04 Security Tools Setup v1.0
- **Focus**: Mobile Security & Android Reverse Engineering
- **Tools**: 50+ security tools across 11 categories
- **Most Important Tool**: JADX v1.5.2 ⭐
- **Last Updated**: August 2025
