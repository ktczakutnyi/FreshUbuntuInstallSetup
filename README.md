# 🛡️ Ubuntu 24.04 Comprehensive Security Tools

> **Run:** `chmod +x setup-security-tools-full.sh && ./setup-security-tools-full.sh 2>&1 | tee install.log`  
> Must be run as a **normal user with sudo** — not root.  
> Expect 45–90 minutes depending on internet speed.

---

## Table of Contents

- [Quick Command Reference](#quick-command-reference)
- [Directory Structure](#directory-structure)
- [Tool Index by Category](#tool-index-by-category)
  - [Network Reconnaissance](#network-reconnaissance)
  - [Web Application Security](#web-application-security)
  - [Password Cracking & Wordlists](#password-cracking--wordlists)
  - [Exploitation & Metasploit](#exploitation--metasploit)
  - [Post-Exploitation & C2](#post-exploitation--c2)
  - [WiFi & Wireless](#wifi--wireless)
  - [RF / SDR](#rf--sdr)
  - [CAN Bus & Automotive](#can-bus--automotive)
  - [Hardware & Embedded](#hardware--embedded)
  - [Reverse Engineering](#reverse-engineering)
  - [Android / Mobile](#android--mobile)
  - [MITM & Interception](#mitm--interception)
  - [Digital Forensics](#digital-forensics)
  - [Blue Team & Defensive](#blue-team--defensive)
  - [CTF Tools](#ctf-tools)
- [Custom Helper Scripts](#custom-helper-scripts)
- [Useful Links](#useful-links)
- [Post-Install Steps](#post-install-steps)
- [Manual Downloads](#manual-downloads)

---

## Quick Command Reference

```bash
ctf-tools          # Full CTF cheatsheet in terminal
can-setup          # CAN bus interface setup guide
esp32-dump         # ESP32 flash dump helper
serial-connect     # Quick picocom serial connect
i2c-decode         # I2C hex bytes to ASCII
ctf-decode         # ROT/base64/hex/auto decoder
pcap-analyze       # PCAP triage helper
docker-forensics   # Docker layer inspection
aperisolve         # Open aperisolve.com steg tool
dcode              # Open dcode.fr cipher tool
cyberchef          # Open CyberChef in browser
kali               # Launch full Kali Linux Docker container
spiderfoot-web     # SpiderFoot OSINT web UI
frida-server-android [arch]  # Download Frida server for Android
```

---

## Directory Structure

```
/opt/security-tools/
├── network-recon/          Recon tools, SpiderFoot, recon-ng
├── web-testing/            Web attack tools
├── password-cracking/
│   ├── wordlists/          SecLists, rockyou.txt
│   ├── hashfiles/          Hash dumps
│   └── pipal/              Password analysis
├── wifi-hacking/
│   ├── captures/           .cap/.pcapng files
│   ├── handshakes/         WPA handshakes
│   └── eaphammer/          EAP attack toolkit
├── rf-sdr/
│   ├── captures/           IQ captures
│   ├── recordings/         Audio recordings
│   └── MOBILE_APPS_REFERENCE.md  ← Mobile app list for field work
├── canbus/
│   ├── TruckDevil/         J1939 truck hacking tool
│   ├── ICSim/              CAN dashboard simulator
│   ├── caringcaribou/      UDS/CAN scanner
│   ├── UDSim/              UDS ECU simulator
│   ├── c0f/                CAN bus fingerprinting
│   └── awesome-canbus-refs/ Reference commands
├── hardware-embedded/
│   ├── firmware/           Firmware dumps
│   │   ├── firmwalker/     Firmware string scanner
│   │   └── fat/            Firmware analysis toolkit
│   ├── serial-logs/        UART captures
│   ├── can-logs/           CAN captures
│   ├── jtag-swd/
│   │   └── JTAGenum/       JTAG pin finder
│   └── buspirate/          Bus Pirate scripts
├── reverse-engineering/
│   ├── pwndbg/             GDB enhancer
│   └── bytecode-viewer.jar Java bytecode viewer
├── binary-analysis/
│   ├── samples/            Binary samples
│   ├── android/
│   │   └── MobSF/          Mobile Security Framework
│   └── firmware/
├── post-exploitation/
│   ├── Responder/          LLMNR/NBT-NS poisoner
│   ├── PEASS-ng/           PrivEsc scripts (linpeas/winpeas)
│   ├── linux-exploit-suggester/
│   └── PowerSploit/        PowerShell post-ex
├── c2-frameworks/
│   └── empire/             PowerShell Empire
├── digital-forensics/
│   ├── cases/              Case working directory
│   ├── memory/             Memory dumps
│   └── chainsaw/           Windows event log analysis
├── ctf/
│   ├── crypto/             Crypto challenge working dir
│   ├── pwn/                PWN challenge working dir
│   ├── web/
│   │   └── QUICKREF.md     Web CTF commands
│   ├── forensics/
│   │   └── stego-toolkit/  Steg scripts
│   └── misc/
├── blue-team/
│   ├── logs/               Log collection
│   ├── rules/              Detection rules
│   └── alerts/             Alert staging
├── detection-analysis/
│   ├── yara-rules/
│   │   ├── yara-community/ Community YARA rules
│   │   └── signature-base/ Neo23x0 rules
│   ├── sigma-rules/        Sigma detection rules
│   ├── scan-results/
│   └── quarantine/
├── exploits/
│   └── exploitdb/          ExploitDB local mirror
└── wordlists/
    ├── SecLists/            ~1GB Daniel Miessler list
    └── rockyou.txt          Classic wordlist

$HOME/go/bin/               Go-installed tools (nuclei, subfinder, etc.)
```

---

## Tool Index by Category

### Network Reconnaissance

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| nmap | apt | `nmap -sS -sV target` | Port scan |
| masscan | apt | `masscan -p1-65535 target` | Fast mass scan |
| netdiscover | apt | `netdiscover -r 192.168.1.0/24` | ARP discovery |
| arp-scan | apt | `arp-scan -l` | LAN discovery |
| nikto | apt | `nikto -h http://target` | Web server scan |
| gobuster | go | `gobuster dir -u http://t -w wl.txt` | Dir brute force |
| ffuf | go | `ffuf -w wl.txt -u http://t/FUZZ` | Fast fuzzer |
| subfinder | go | `subfinder -d domain.com` | Subdomain enum |
| httpx | go | `httpx -l hosts.txt` | HTTP probing |
| nuclei | go | `nuclei -t templates/ -u target` | Vuln scanner |
| naabu | go | `naabu -host target` | Port scanner |
| dnsx | go | `dnsx -l domains.txt` | DNS toolkit |
| amass | go/apt | `amass enum -d domain.com` | Attack surface |
| theHarvester | apt | `theHarvester -d domain -b all` | OSINT |
| recon-ng | git | `recon-ng` | Recon framework |
| spiderfoot | git | `spiderfoot-web` → http://127.0.0.1:5001 | OSINT platform |
| dmitry | apt | `dmitry -winsepfb target` | Info gathering |
| enum4linux | apt | `enum4linux -a target` | SMB/LDAP enum |
| smbmap | apt | `smbmap -H target` | SMB enumeration |
| wafw00f | pip | `wafw00f http://target` | WAF detection |
| whatweb | apt | `whatweb http://target` | Tech fingerprint |
| fierce | apt | `fierce --domain target.com` | DNS recon |
| ike-scan | apt | `ike-scan target` | VPN scan |
| p0f | apt | `p0f -i eth0` | Passive OS detect |

### Web Application Security

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| sqlmap | apt | `sqlmap -u 'http://t/?id=1' --dbs` | SQL injection |
| ffuf | go | `ffuf -w wl.txt -u http://t/FUZZ` | Fuzzing |
| feroxbuster | github .deb | `feroxbuster -u http://target` | Dir buster |
| wpscan | gem | `wpscan --url http://target` | WordPress scan |
| zaproxy | apt | `zaproxy` | OWASP ZAP |
| dalfox | go | `dalfox url http://target` | XSS scanner |
| gospider | go | `gospider -s http://target` | Web crawler |
| commix | pip | `commix --url http://t/?p=INJECT` | Cmd injection |
| sqlitebrowser | apt | `sqlitebrowser db.sqlite` | SQLite GUI |
| curl | apt | `curl -v -X POST -d 'data' http://t` | HTTP requests |
| burpsuite | manual | Download from portswigger.net | Intercept proxy |

**CTF Web links from notes:**
- https://medium.com/quiknapp/fuzz-faster-with-ffuf-c18c031fc480
- https://cantreally.cyou/
- `cat /opt/security-tools/ctf/web/QUICKREF.md`

### Password Cracking & Wordlists

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| hashcat | apt | `hashcat -m 0 -a 0 hashes.txt rockyou.txt` | GPU cracker |
| john | apt | `john --wordlist=rockyou.txt hashes.txt` | CPU cracker |
| hydra | apt | `hydra -l admin -P rockyou.txt ssh://target` | Network brute |
| medusa | apt | `medusa -h target -u admin -P wl.txt -M ssh` | Network brute |
| crunch | apt | `crunch 8 8 -t @@@@@@%%` | Wordlist gen |
| cewl | apt | `cewl http://target -d 2` | Site wordlist |
| pipal | git+ruby | `pipal passwords.txt` | Password stats |
| name-that-hash | pip | `nth --text 'hash'` | Hash identify |
| hashid | pip | `hashid 'hash'` | Hash identify |
| SecLists | git | `/opt/security-tools/wordlists/SecLists/` | ~1GB wordlists |
| rockyou.txt | apt | `/opt/security-tools/wordlists/rockyou.txt` | Classic list |

**Common hashcat modes:**
```bash
hashcat -m 0    # MD5
hashcat -m 100  # SHA1
hashcat -m 1800 # sha512crypt (Linux passwords)
hashcat -m 1000 # NTLM
hashcat -m 2500 # WPA-PBKDF2
```

### Exploitation & Metasploit

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| metasploit | curl installer | `msfconsole` | Full framework |
| msfvenom | metasploit | `msfvenom -p payload LHOST=x -f elf` | Payload gen |
| searchsploit | apt | `searchsploit apache 2.4` | ExploitDB search |
| impacket | pip+apt | `impacket-psexec domain/user@target` | Windows attacks |
| crackmapexec | pip | `crackmapexec smb target -u user -p pass` | AD testing |
| bloodhound | pip | `bloodhound-python -d domain -u user` | AD enumeration |
| responder | git+apt | `responder -I eth0 -wF` | LLMNR poisoner |
| chisel | go | `chisel server --reverse` | TCP tunneling |
| ligolo-ng | go | `ligolo-proxy -selfcert` | Tunneling |
| pwntools | pip | `from pwn import *` | CTF exploit dev |
| ROPgadget | pip | `ROPgadget --binary ./binary` | ROP gadget find |
| ropper | pip | `ropper -f binary` | ROP gadget find |
| one_gadget | gem | `one_gadget /lib/libc.so.6` | libc one-shot |
| angr | pip | `import angr` | Binary analysis |
| GEF | wget | GDB: `gef` | GDB enhancer |

### Post-Exploitation & C2

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| linpeas | git | `linpeas` | Linux privesc |
| winpeas | git | (Windows binary) | Windows privesc |
| evil-winrm | gem | `evil-winrm -i target -u user -p pass` | WinRM shell |
| sliver | curl installer | `sliver-server` | Modern C2 |
| empire | git | `cd /opt/.../empire && ./install.sh` | PS Empire |
| sshuttle | apt | `sshuttle -r user@target 0/0` | VPN over SSH |
| proxychains4 | apt | `proxychains4 nmap target` | SOCKS proxy |
| weevely | apt | `weevely generate pass shell.php` | PHP webshell |
| updog | pip | `updog -p 80` | Quick file server |
| netcat | apt | `nc -lvnp 4444` | Reverse shell |

### WiFi & Wireless

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| aircrack-ng | apt | `aircrack-ng -w wl.txt capture.cap` | WEP/WPA crack |
| airmon-ng | apt | `airmon-ng start wlan0` | Monitor mode |
| airodump-ng | apt | `airodump-ng wlan0mon` | Capture traffic |
| aireplay-ng | apt | `aireplay-ng -0 1 -a BSSID wlan0mon` | Deauth |
| wifite | apt | `wifite --kill` | Automated WiFi |
| reaver | apt | `reaver -i wlan0mon -b BSSID -vv` | WPS attack |
| pixiewps | apt | `pixiewps ...` | WPS pixie dust |
| bully | apt | `bully wlan0mon -b BSSID` | WPS attack |
| kismet | kismet repo | `kismet` | WiFi/BT sniffer |
| bettercap | go/apt | `bettercap -iface wlan0` | Network attack |
| hcxtools | apt | `hcxpcapngtool -o hash.hc22000 cap.pcapng` | PMKID attacks |
| wifipumpkin3 | pip | `wifipumpkin3` | Evil AP |
| eaphammer | git | `./eaphammer -i wlan0 --essid Corp` | EAP attacks |
| macchanger | apt | `macchanger -r wlan0` | Spoof MAC |
| cowpatty | apt | `cowpatty -f wl.txt -r cap.pcap -s SSID` | WPA crack |

### RF / SDR

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| gqrx | apt | `gqrx` | SDR GUI receiver |
| gnuradio | apt | `gnuradio-companion` | SDR flowgraphs |
| urh | pip | `urh` | Signal analysis |
| inspectrum | apt | `inspectrum file.cfile` | Signal analysis |
| rtl_test | apt | `rtl_test` | Test RTL-SDR |
| hackrf_info | apt | `hackrf_info` | HackRF status |
| rtl_433 | build | `rtl_433` | 433MHz decoder |
| multimon-ng | apt | `multimon-ng -t wav -a ALL file.wav` | Protocol decode |
| direwolf | apt | `direwolf` | APRS/packet radio |
| dump1090 | apt | `dump1090 --interactive` | ADS-B (planes) |
| audacity | apt | `audacity` | Audio analysis |
| sox | apt | `sox in.wav out.wav rate 22050` | Audio convert |
| morse2ascii | apt | `morse2ascii < morse.txt` | Morse decode |
| ubertooth-util | apt | `ubertooth-util -v` | Bluetooth sniff |
| sigrok-cli | apt | `sigrok-cli -d fx2lafw` | Logic analyzer |
| pulseview | apt | `pulseview` | Logic analyzer GUI |

**Mobile apps for field work (from CTF notes):**
```
Bluetooth:  nRF Connect, AirGuard, Flipper app
WiFi:       WiFi Analyzer, WiFiman, Aruba Utilities
Mesh/LoRa:  Meshtastic, goTenna
PTT:        Zello
SDR:        SDR Touch (Android + OTG)
```
See: `/opt/security-tools/rf-sdr/MOBILE_APPS_REFERENCE.md`

**Fox hunt workflow:**
1. Find active peak frequency in gqrx/urh
2. Decode Morse with `multimon-ng` or audacity
3. Use directional antenna + kismet for WiFi hunt
4. nRF Connect for BLE beacon hunting

### CAN Bus & Automotive

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| candump | apt (can-utils) | `candump can0` | Sniff all frames |
| cansend | apt | `cansend can0 123#DEADBEEF` | Send frame |
| cansniffer | apt | `cansniffer can0` | Live filter view |
| cangen | apt | `cangen can0 -g 10 -L 8` | Generate traffic |
| canplayer | apt | `canplayer -I log.log` | Replay capture |
| canbusload | apt | `canbusload can0@500000` | Bus load % |
| TruckDevil | git | `truckdevil -i can0` | J1939 heavy truck |
| CaringCaribou | git+pip | `cc discovery` | UDS/CAN scanner |
| ICSim | git+build | `./icsim vcan0` | Dashboard sim |
| UDSim | git | UDS ECU simulator | |
| canmatrix | pip | `import canmatrix` | DBC file handling |
| python-can | pip | `import can` | CAN interface |
| cantools | pip | `cantools decode db.dbc frame` | DBC decode |
| c0f | git | CAN fingerprinting | |
| scapy | pip | `from scapy.layers.can import *` | CAN in Scapy |

**Virtual CAN setup (for testing):**
```bash
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
candump vcan0 &          # terminal 1 - watch
cansend vcan0 123#DEAD   # terminal 2 - send
```

**References from CTF notes:**
- https://github.com/LittleBlondeDevil/TruckDevil
- https://github.com/iDoka/awesome-canbus
- https://python-can.readthedocs.io/en/stable/

### Hardware & Embedded

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| esptool | pip | `esptool.py --port /dev/ttyUSB0 read_flash 0 0x400000 dump.bin` | ESP32/8266 flash |
| picocom | apt | `picocom /dev/ttyUSB0 -b 115200` | Serial terminal |
| minicom | apt | `minicom -D /dev/ttyUSB0 -b 115200` | Serial terminal |
| screen | apt | `screen /dev/ttyUSB0 115200` | Serial terminal |
| putty | apt | `putty` | Serial/SSH GUI |
| cutecom | apt | `cutecom` | Serial GUI |
| avrdude | apt | `avrdude -c usbtiny -p atmega328p` | AVR programmer |
| openocd | apt | `openocd -f interface/stlink.cfg` | JTAG/SWD debug |
| flashrom | apt | `flashrom -p ch341a_spi -r dump.bin` | Flash chip read |
| arduino-cli | curl | `arduino-cli compile` | Arduino CLI |
| platformio | pip | `pio run` | Embedded IDE |
| sigrok-cli | apt | `sigrok-cli -d fx2lafw --samples 1M` | Logic analyzer |
| pulseview | apt | `pulseview` | Logic analyzer GUI |
| i2c-tools | apt | `i2cdetect -y 1` | I2C scan |
| binwalk | apt+pip | `binwalk -e firmware.bin` | Firmware extract |
| firmwalker | git | `bash firmwalker.sh /extracted/` | Firmware scan |
| JTAGenum | git | Arduino sketch for JTAG enumeration | |

**ESP32 quick workflow (from CTF notes):**
```bash
# Find port
lsusb
ls /dev/tty*

# Dump flash (4MB)
python3 -m esptool --port /dev/ttyUSB0 -b 115200 read_flash 0 0x400000 flashdump.bin
# or use helper:
esp32-dump /dev/ttyUSB0 115200 flashdump.bin

# Analyze
strings flashdump.bin | grep -i flag
binwalk flashdump.bin
binwalk -e flashdump.bin
ghidra  # for full disassembly

# Common baud rates to try: 9600 115200 57600 38400 19200 4800 1200
```

**Logic Analyzer I2C decode (from CTF notes):**
```bash
# Decode captured I2C hex bytes to ASCII
i2c-decode '42 44 47 49 49 4D 4F 3F'
# Output: BDGIIMO?

i2c-decode '4B 4B 55 78 36 76 73 30'
# Output: KKUx6vs0
```

### Reverse Engineering

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| ghidra | snap | `ghidra` | NSA RE suite |
| radare2 | apt | `r2 binary` | CLI RE framework |
| rizin | apt | `rizin binary` | r2 fork |
| rizin-cutter | apt | `cutter` | Rizin GUI |
| jadx | github | `jadx app.apk` | Java/Android decompile |
| jadx-gui | github | `jadx-gui` | JADX GUI |
| gdb + GEF | apt+wget | `gdb binary` | Debugger |
| pwndbg | git | `gdb binary` (auto loads) | GDB enhancer |
| imhex | github .deb | `imhex` | Hex editor |
| ghex | apt | `ghex file.bin` | Hex editor |
| bless | apt | `bless file.bin` | Hex editor |
| xxd | apt | `xxd file.bin` | Hex dump |
| strings | apt | `strings -a binary` | Extract strings |
| binwalk | apt | `binwalk -e firmware.bin` | Extract embedded |
| frida | pip | `frida-ps -U` | Dynamic instrumentation |
| angr | pip | `import angr` | Binary analysis |
| capstone | pip | `from capstone import *` | Disassembler |
| keystone | pip | `from keystone import *` | Assembler |
| unicorn | pip | `from unicorn import *` | CPU emulator |
| volatility3 | pip | `vol -f mem.dmp windows.pslist` | Memory forensics |
| bytecode-viewer | github .jar | `java -jar bytecode-viewer.jar` | Java decompile |
| strace | apt | `strace ./binary` | Syscall trace |
| ltrace | apt | `ltrace ./binary` | Library trace |
| objdump | apt | `objdump -d binary` | Disassemble |
| readelf | apt | `readelf -a binary` | ELF info |
| file | apt | `file binary` | Identify filetype |
| upx | apt | `upx -d packed_binary` | UPX unpack |

### Android / Mobile

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| adb | apt | `adb devices` | Android bridge |
| fastboot | apt | `fastboot devices` | Bootloader |
| jadx | github | `jadx app.apk` | Decompile APK |
| jadx-gui | github | `jadx-gui` | GUI decompile |
| frida | pip | `frida -U -l script.js package` | Dynamic hooks |
| objection | pip | `objection -g package explore` | Frida wrapper |
| apkleaks | pip | `apkleaks -f app.apk` | APK secret scan |
| mobsf | git | `mobsf` → http://127.0.0.1:8000 | Full mobile scan |
| apksigner | apt | `apksigner verify app.apk` | APK signing |
| android-studio | snap | `android-studio` | IDE + AVD |

**Android frida-server setup:**
```bash
frida-server-android arm64      # Download server binary
adb push frida-server-*-android-arm64 /data/local/tmp/frida-server
adb shell 'su -c "/data/local/tmp/frida-server &"'
frida-ps -U                     # Verify connection
```

### MITM & Interception

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| mitmproxy | pip/apt | `mitmproxy -p 8080` | TLS intercept |
| mitmweb | pip/apt | `mitmweb -p 8080` | Web UI |
| bettercap | go/apt | `bettercap -iface eth0` | Network attack |
| ettercap | apt | `ettercap -G` | MITM GUI |
| mitm6 | pip | `mitm6 -d domain.local` | IPv6 MITM |
| responder | git | `responder -I eth0 -wF` | Credential capture |
| dsniff | apt | `dsniff -i eth0` | Credential sniff |
| burpsuite | manual | http://burp → 8080 proxy | Web intercept |

### Digital Forensics

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| volatility3 | pip | `vol -f mem.dmp windows.pslist` | Memory analysis |
| autopsy | apt/github | `autopsy` | GUI forensics |
| sleuthkit | apt | `mmls disk.img` | Disk analysis |
| bulk_extractor | apt | `bulk_extractor -o out/ disk.img` | Data carving |
| foremost | apt | `foremost -i file -o out/` | File carve |
| testdisk | apt | `testdisk disk.img` | Partition recovery |
| scalpel | apt | `scalpel -o out/ disk.img` | File carve |
| chainsaw | cargo build | `chainsaw hunt /evtx/ -s sigma/` | Event log analysis |
| exiftool | apt | `exiftool file` | Metadata |
| wireshark | apt | `wireshark cap.pcap` | PCAP GUI |
| tshark | apt | `tshark -r cap.pcap -Y 'http'` | PCAP CLI |
| pcap-analyze | script | `pcap-analyze file.pcap` | Triage helper |
| docker-forensics | script | `docker-forensics image:tag` | Docker inspection |
| oletools | pip | `olevba malware.doc` | Office malware |
| dc3dd | apt | `dc3dd if=/dev/sda of=disk.img` | Forensic copy |

**PCAP CTF workflow (from SHMOOCON notes):**
```bash
pcap-analyze capture.pcap          # Automated triage
tshark -r cap.pcap -Y 'http' -T fields -e http.request.uri
tshark -r cap.pcap --export-objects "http,./objects"
wireshark cap.pcap                 # GUI analysis
# Follow TCP stream → right click stream → Follow → TCP Stream
```

**Docker forensics (from SHMOOCON notes):**
```bash
docker-forensics image:tag
docker history --no-trunc image:tag
docker save image | tar xv
# Look for: env vars, secrets, hardcoded creds, layer commands
```

### Blue Team & Defensive

| Tool | How Installed | Command | Notes |
|------|--------------|---------|-------|
| suricata | apt | `suricata -c /etc/suricata/suricata.yaml -i eth0` | IDS/IPS |
| zeek | apt | `zeek -i eth0` | Network monitor |
| snort | apt | `snort -A console -i eth0 -c /etc/snort/snort.conf` | IDS |
| yara | apt | `yara rules.yar suspicious_file` | Malware scan |
| sigma-cli | pip | `sigma convert -t splunk rule.yml` | Detection rules |
| velociraptor | github binary | `velociraptor gui` | DFIR platform |
| clamav | apt | `clamscan -r /path/` | Antivirus |
| rkhunter | apt | `rkhunter --check` | Rootkit detect |
| chkrootkit | apt | `chkrootkit` | Rootkit detect |
| lynis | apt | `lynis audit system` | Security audit |
| fail2ban | apt | `fail2ban-client status` | Intrusion prevent |
| aide | apt | `aide --check` | File integrity |
| auditd | apt | `auditd` | Audit daemon |

**YARA rules locations:**
```
/opt/security-tools/detection-analysis/yara-rules/yara-community/
/opt/security-tools/detection-analysis/yara-rules/signature-base/
```

### CTF Tools

#### Steganography

| Tool | Command | Notes |
|------|---------|-------|
| aperisolve | `aperisolve [img]` | Opens aperisolve.com |
| stegseek | `stegseek image.jpg rockyou.txt` | Fast steghide crack |
| steghide | `steghide extract -sf image.jpg` | Extract hidden data |
| stegsnow | `stegsnow -C image.txt` | Whitespace steg |
| outguess | `outguess -r image.jpg out.txt` | Extract data |
| exiftool | `exiftool image.jpg` | Metadata |
| binwalk | `binwalk -e image.jpg` | Embedded files |
| strings | `strings image.jpg \| grep flag` | String search |
| zbarimg | `zbarimg image.png` | QR/barcode decode |
| imagemagick | `identify -verbose image.jpg` | Image info |

**Aperisolve** (from your notes): https://www.aperisolve.com/  
Submit image → runs stegdetect, zsteg, exiftool, strings, binwalk automatically.

#### Crypto / Encoding (from THOTCON notes)

```bash
# Base64
echo 'RmxhZ3tiYXNlNjRfaXNfZWFzeX0=' | base64 -d
# → flag{base64_is_easy}

# ROT13
echo 'Ykj pynih fgl' | tr 'A-Za-z' 'N-ZA-Mn-za-m'

# Auto-try all ROT values
ctf-decode 'Ftue ue FTAFOAZ' auto
# tries ROT1-25 automatically, ROT12 gives the answer

# Binary decode
ctf-decode '01100010...' binary

# RSA CTF attacks
RSACTFTool --publickey public.pem --attack all

# XOR analysis
xortool -x -c ' ' encrypted.bin

# CyberChef (from notes): https://gchq.github.io/CyberChef/
cyberchef
# dcode.fr cipher identifier:
dcode
```

#### PWN / Binary Exploitation

```bash
checksec binary                    # Check protections
ROPgadget --binary binary          # Find gadgets
one_gadget /lib/x86_64-linux-gnu/libc.so.6  # One-shot ROP
gdb binary                        # Debug (GEF auto-loads)
pwntools:
  from pwn import *
  elf = ELF('./binary')
  p = process('./binary')
  p.sendline(cyclic(200))
```

---

## Custom Helper Scripts

All installed to `/usr/local/bin/` and callable from anywhere:

| Script | Usage | Description |
|--------|-------|-------------|
| `ctf-tools` | `ctf-tools` | Full CTF cheatsheet in terminal |
| `ctf-decode` | `ctf-decode 'text' [method]` | ROT/base64/hex/auto decoder |
| `esp32-dump` | `esp32-dump [port] [baud] [out]` | ESP32 flash dump |
| `serial-connect` | `serial-connect [port] [baud]` | Quick picocom connect |
| `i2c-decode` | `i2c-decode '42 44 47...'` | I2C hex → ASCII |
| `can-setup` | `can-setup` | CAN interface setup guide |
| `pcap-analyze` | `pcap-analyze file.pcap` | PCAP triage |
| `docker-forensics` | `docker-forensics image:tag` | Docker layer forensics |
| `aperisolve` | `aperisolve [img]` | Open aperisolve.com |
| `dcode` | `dcode` | Open dcode.fr |
| `cyberchef` | `cyberchef` | Open CyberChef |
| `kali` | `kali` | Launch Kali Linux Docker |
| `spiderfoot` | `spiderfoot` | CLI SpiderFoot |
| `spiderfoot-web` | `spiderfoot-web` | Web UI SpiderFoot |
| `recon-ng` | `recon-ng` | Recon-ng framework |
| `pipal` | `pipal passwords.txt` | Password analysis |
| `truckdevil` | `truckdevil -i can0` | J1939 truck hacking |
| `linpeas` | `linpeas` | Linux privilege escalation |
| `frida-server-android` | `frida-server-android arm64` | Download Android frida-server |
| `mobsf` | `mobsf` | Mobile Security Framework |

---

## Useful Links

From CTF notes and research:

| Link | What It's For |
|------|--------------|
| https://gchq.github.io/CyberChef/ | Encoding/decoding/crypto swiss army knife |
| https://www.dcode.fr/ | Cipher identification and decoding |
| https://www.aperisolve.com/ | All-in-one steganography analysis |
| https://cantreally.cyou/ | CTF writeups (SHMOOCON etc.) |
| https://github.com/iDoka/awesome-canbus | CAN bus tool list |
| https://python-can.readthedocs.io/en/stable/ | python-can docs |
| https://github.com/LittleBlondeDevil/TruckDevil | J1939 truck hacking |
| https://medium.com/quiknapp/fuzz-faster-with-ffuf-c18c031fc480 | ffuf guide |
| https://portswigger.net/burp/communitydownload | Burp Suite |
| https://httptoolkit.tech/ | HTTP debugging proxy |
| https://ghidra-sre.org/ | Ghidra RE |
| https://kernelsu.org/ | Android root (preferred over Magisk) |
| https://flipperzero.one/ | Flipper Zero |
| https://www.carhackingvillage.com/ | Car hacking resources |
| https://solvers.battelle.org/cyber-challenge/ | Battelle CTF |
| https://www.virustotal.com/ | Malware analysis |
| https://snort.org/downloads#rule-downloads | Snort rules |

---

## Post-Install Steps

```bash
# 1. Reload shell (PATH changes won't apply until you do this)
exec $SHELL
# or log out and back in

# 2. Verify key tools
ctf-tools

# 3. CAN bus virtual interface (for testing without hardware)
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0

# 4. RTL-SDR udev rules (use dongle without sudo)
sudo cp /usr/lib/udev/rules.d/rtl-sdr.rules /etc/udev/rules.d/ 2>/dev/null || true
sudo udevadm control --reload-rules && sudo udevadm trigger

# 5. Run full Kali toolset via Docker
kali

# 6. Install more Kali tools interactively
sudo katoolin3

# 7. Switch Java version if needed
sudo update-alternatives --config java

# 8. Configure Wine for Windows binaries
winecfg

# 9. Update ClamAV signatures
sudo freshclam

# 10. Update Metasploit
msfupdate

# 11. Update Nuclei templates
nuclei -update-templates

# 12. Android frida-server
frida-server-android arm64
```

---

## Manual Downloads

These can't be automated (commercial, complex installers, or hardware-specific):

| Tool | URL | Notes |
|------|-----|-------|
| Burp Suite Pro | https://portswigger.net/burp/pro | Best web proxy |
| IDA Pro | https://hex-rays.com/ida-pro/ | Gold standard RE |
| Binary Ninja | https://binary.ninja/ | Modern RE |
| 010 Editor | https://www.sweetscape.com/010editor/ | Commercial hex editor |
| HttpToolkit | https://httptoolkit.tech/ | HTTP debugging |
| HackRF firmware | https://github.com/greatscottgadgets/hackrf/releases | If needed |
| Flipper Zero | https://flipperzero.one/ | Multi-tool hardware |
| Proxmark3 | https://github.com/RfidResearchGroup/proxmark3 | RFID/NFC |
| Bus Pirate | http://dangerousprototypes.com/docs/Bus_Pirate | Hardware debug |
| Arduino IDE | https://www.arduino.cc/en/software | If arduino-cli not enough |
| VirusTotal API | https://www.virustotal.com/gui/join-us | Free API key |
| Snort rules | https://www.snort.org/downloads#rule-downloads | Community rules |

---

*Generated alongside `setup-security-tools-full.sh` — run `ctf-tools` in terminal for a quick reference.*
