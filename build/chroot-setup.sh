#!/usr/bin/env bash
# =============================================================
#  NexOS Chroot Setup
#  Runs INSIDE the debootstrap chroot
#  Installs and configures the full NexOS system
# =============================================================
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
export LANG=en_US.UTF-8

log()  { echo -e "\033[0;32m[✓]\033[0m $1"; }
info() { echo -e "\033[0;36m[→]\033[0m $1"; }
step() { echo -e "\n\033[0;35m\033[1m══ $1 ══\033[0m\n"; }

# ── System basics ─────────────────────────────────────────────
step "System Configuration"

echo "nexos" > /etc/hostname
cat > /etc/hosts << 'EOF'
127.0.0.1   localhost
127.0.1.1   nexos
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

locale-gen en_US.UTF-8 2>/dev/null || true
update-locale LANG=en_US.UTF-8 2>/dev/null || true

ln -snf /usr/share/zoneinfo/UTC /etc/localtime
echo "UTC" > /etc/timezone

# APT sources
cat > /etc/apt/sources.list << 'EOF'
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
EOF

apt-get update -qq
log "System configured"

# ── Core packages ─────────────────────────────────────────────
step "Core System Packages"

apt-get install -yq \
    linux-image-generic \
    linux-headers-generic \
    linux-firmware \
    casper \
    lupin-casper \
    discover \
    laptop-detect \
    os-prober \
    grub-common \
    grub-pc \
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub2-common \
    network-manager \
    networkmanager \
    wget \
    curl \
    git \
    vim \
    nano \
    sudo \
    dbus \
    dbus-x11 \
    bash-completion \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    locales \
    tzdata \
    initramfs-tools \
    2>/dev/null

log "Core packages installed"

# ── KDE Plasma 6 ─────────────────────────────────────────────
step "KDE Plasma 6 Desktop"

apt-get install -yq \
    kde-plasma-desktop \
    sddm \
    plasma-workspace \
    plasma-nm \
    plasma-pa \
    plasma-widgets-addons \
    kdeplasma-addons \
    kwin-x11 \
    kwin-wayland \
    konsole \
    dolphin \
    ark \
    kate \
    spectacle \
    okular \
    gwenview \
    kcalc \
    plasma-systemmonitor \
    packagekit-qt5 \
    breeze \
    breeze-gtk-theme \
    plasma-theme-oxygen \
    sddm-theme-breeze \
    2>/dev/null

log "KDE Plasma installed"

# ── Gaming ────────────────────────────────────────────────────
step "Gaming Tools"

dpkg --add-architecture i386
apt-get update -qq

apt-get install -yq \
    gamemode \
    mangohud \
    vulkan-tools \
    libvulkan1 \
    mesa-vulkan-drivers \
    mesa-utils \
    2>/dev/null

# Wine
apt-get install -yq wine wine64 winetricks 2>/dev/null || \
    info "Wine install failed — user can install after boot"

# Steam
apt-get install -yq steam-installer 2>/dev/null || \
apt-get install -yq steam 2>/dev/null || \
    info "Steam install failed — user can install after boot"

# Lutris
apt-get install -yq lutris 2>/dev/null || (
    add-apt-repository -y ppa:lutris-team/lutris 2>/dev/null
    apt-get update -qq
    apt-get install -yq lutris 2>/dev/null
) || info "Lutris skipped"

# Flatpak (for Discord, Heroic, etc.)
apt-get install -yq flatpak 2>/dev/null
flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

log "Gaming tools installed"

# ── Applications ──────────────────────────────────────────────
step "Applications"

apt-get install -yq \
    firefox \
    vlc \
    htop \
    neofetch \
    python3 \
    python3-pip \
    python3-tk \
    fonts-jetbrains-mono \
    fonts-noto \
    fonts-noto-color-emoji \
    2>/dev/null

log "Applications installed"

# ── Performance ───────────────────────────────────────────────
step "Performance Tweaks"

apt-get install -yq preload zram-config cpufrequtils 2>/dev/null || true

cat > /etc/sysctl.d/99-nexos.conf << 'EOF'
vm.swappiness=10
vm.vfs_cache_pressure=50
fs.inotify.max_user_watches=524288
net.core.netdev_max_backlog=16384
net.core.somaxconn=8192
net.ipv4.tcp_fastopen=3
EOF

log "Performance tweaks written"

# ── Theming ───────────────────────────────────────────────────
step "Theming"

# Kvantum
apt-get install -yq qt5-style-kvantum qt5-style-kvantum-themes 2>/dev/null || true

# Papirus icons
add-apt-repository -y ppa:papirus/papirus 2>/dev/null || true
apt-get update -qq
apt-get install -yq papirus-icon-theme 2>/dev/null || true

# Bibata cursor
apt-get install -yq bibata-cursor-theme 2>/dev/null || {
    curl -fsSLo /tmp/bibata.tar.xz \
        "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz" \
        2>/dev/null && \
    tar xf /tmp/bibata.tar.xz -C /usr/share/icons/ 2>/dev/null && \
    log "Bibata cursor installed" || info "Bibata cursor skipped"
}

log "Theming packages installed"

# ── NexOS Color Scheme ────────────────────────────────────────
step "NexOS Color Scheme"

mkdir -p /usr/share/color-schemes
cat > /usr/share/color-schemes/NexOS.colors << 'EOF'
[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=30,30,48
BackgroundNormal=22,22,38
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=0,245,255
ForegroundInactive=110,110,150
ForegroundLink=0,245,255
ForegroundNegative=255,45,78
ForegroundNeutral=255,170,0
ForegroundNormal=220,220,240
ForegroundPositive=0,200,100
ForegroundVisited=150,100,255

[Colors:Complementary]
BackgroundAlternate=18,18,32
BackgroundNormal=10,10,20
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=0,245,255
ForegroundInactive=90,90,130
ForegroundLink=0,245,255
ForegroundNegative=255,45,78
ForegroundNeutral=255,170,0
ForegroundNormal=220,220,240
ForegroundPositive=0,200,100
ForegroundVisited=150,100,255

[Colors:Header]
BackgroundAlternate=15,15,28
BackgroundNormal=8,8,18
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=0,245,255
ForegroundInactive=90,90,130
ForegroundLink=0,245,255
ForegroundNegative=255,45,78
ForegroundNeutral=255,170,0
ForegroundNormal=220,220,240
ForegroundPositive=0,200,100
ForegroundVisited=150,100,255

[Colors:Selection]
BackgroundAlternate=0,180,200
BackgroundNormal=0,245,255
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=0,0,0
ForegroundInactive=0,0,0
ForegroundLink=0,0,0
ForegroundNegative=255,45,78
ForegroundNeutral=255,170,0
ForegroundNormal=0,0,0
ForegroundPositive=0,200,100
ForegroundVisited=0,0,0

[Colors:Tooltip]
BackgroundAlternate=8,8,18
BackgroundNormal=12,12,24
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=0,245,255
ForegroundInactive=90,90,130
ForegroundLink=0,245,255
ForegroundNegative=255,45,78
ForegroundNeutral=255,170,0
ForegroundNormal=220,220,240
ForegroundPositive=0,200,100
ForegroundVisited=150,100,255

[Colors:View]
BackgroundAlternate=14,14,26
BackgroundNormal=8,8,18
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=0,245,255
ForegroundInactive=90,90,130
ForegroundLink=0,245,255
ForegroundNegative=255,45,78
ForegroundNeutral=255,170,0
ForegroundNormal=220,220,240
ForegroundPositive=0,200,100
ForegroundVisited=150,100,255

[Colors:Window]
BackgroundAlternate=14,14,26
BackgroundNormal=8,8,18
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=0,245,255
ForegroundInactive=90,90,130
ForegroundLink=0,245,255
ForegroundNegative=255,45,78
ForegroundNeutral=255,170,0
ForegroundNormal=220,220,240
ForegroundPositive=0,200,100
ForegroundVisited=150,100,255

[General]
ColorScheme=NexOS
Name=NexOS
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground=8,8,18
activeBlend=8,8,18
activeForeground=0,245,255
inactiveBackground=8,8,18
inactiveBlend=8,8,18
inactiveForeground=70,70,100
EOF

log "Color scheme installed"

# ── SDDM Theme ────────────────────────────────────────────────
step "SDDM Login Theme"

SDDM_DIR="/usr/share/sddm/themes/nexos"
mkdir -p "$SDDM_DIR"

cat > "$SDDM_DIR/theme.conf" << 'EOF'
[General]
blur=true
recursiveBlurLoops=4
recursiveBlurRadius=6
showUserRealNameByDefault=false
EOF

# Use copied QML if available, else inline
if [[ -f /tmp/nexos-sddm/Main.qml ]]; then
    cp /tmp/nexos-sddm/Main.qml "$SDDM_DIR/Main.qml"
    log "SDDM QML copied from project"
else
    info "Using fallback SDDM theme"
    cp /usr/share/sddm/themes/breeze/Main.qml "$SDDM_DIR/Main.qml" 2>/dev/null || true
fi

mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/nexos.conf << 'EOF'
[Theme]
Current=nexos
CursorTheme=Bibata-Modern-Classic

[General]
DisplayServer=x11
InputMethod=

[Autologin]
User=nexos
Session=plasma
Relogin=false
EOF

log "SDDM theme configured"

# ── Casper live system ────────────────────────────────────────
step "Live System (Casper)"

cat > /etc/casper.conf << 'EOF'
export USERNAME=nexos
export USERFULLNAME="NexOS Live"
export HOST=nexos
export BUILD_SYSTEM=Ubuntu
export FLAVOUR=NexOS
EOF

# Remove old casper username file if present
rm -f /etc/casper-login 2>/dev/null || true

log "Casper configured"

# ── Live user ─────────────────────────────────────────────────
step "Live User"

# Create live user — casper also does this at boot but we need it for
# first-boot wizard autostart and SDDM autologin fallback
if ! id nexos &>/dev/null; then
    useradd -m -s /bin/bash -G \
        sudo,audio,video,plugdev,input,dialout,cdrom,floppy,tape,dip \
        nexos
fi
echo "nexos:nexos" | chpasswd
echo "nexos ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nexos
chmod 440 /etc/sudoers.d/nexos

log "Live user 'nexos' (password: nexos)"

# ── First-boot Wizard ─────────────────────────────────────────
step "First-Boot Wizard"

mkdir -p /opt/nexos-setup

# Launcher wrapper
cat > /opt/nexos-setup/launch.sh << 'EOF'
#!/bin/bash
export DISPLAY="${DISPLAY:-:0}"
exec /usr/bin/python3 /opt/nexos-setup/wizard.py
EOF
chmod +x /opt/nexos-setup/launch.sh

# Autostart for the nexos live user
mkdir -p /home/nexos/.config/autostart
cat > /home/nexos/.config/autostart/nexos-setup.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=NexOS Setup
Exec=/opt/nexos-setup/launch.sh
Icon=system-software-install
X-KDE-autostart-phase=2
StartupNotify=false
EOF

chown -R nexos:nexos /home/nexos/.config

# Desktop shortcut
mkdir -p /home/nexos/Desktop
cat > /home/nexos/Desktop/nexos-install.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Install NexOS to Disk
Comment=Install NexOS permanently to your hard drive
Exec=/opt/nexos-setup/launch.sh
Icon=drive-harddisk
Terminal=false
Categories=System;
EOF
chmod +x /home/nexos/Desktop/nexos-install.desktop
chown nexos:nexos /home/nexos/Desktop/nexos-install.desktop

log "First-boot wizard configured"

# ── KDE user defaults ─────────────────────────────────────────
step "KDE Desktop Defaults"

cat > /etc/profile.d/nexos-kde-init.sh << 'BASHEOF'
#!/bin/bash
FLAG="$HOME/.config/.nexos-initialized"
[[ -f "$FLAG" ]] && return 0

kwriteconfig5 --file kdeglobals --group General    --key ColorScheme NexOS 2>/dev/null
kwriteconfig5 --file kdeglobals --group Icons      --key Theme Papirus-Dark 2>/dev/null
kwriteconfig5 --file kdeglobals --group KDE        --key AnimationDurationFactor 0.5 2>/dev/null
kwriteconfig5 --file kcminputrc --group Mouse      --key cursorTheme Bibata-Modern-Classic 2>/dev/null

for key in font fixed menuFont toolBarFont smallestReadableFont; do
    kwriteconfig5 --file kdeglobals --group General --key "$key" \
        "JetBrains Mono,10,-1,5,50,0,0,0,0,0" 2>/dev/null
done

kwriteconfig5 --file kwinrc --group Compositing --key Backend OpenGL 2>/dev/null
kwriteconfig5 --file kwinrc --group Compositing --key GLCore true 2>/dev/null
kwriteconfig5 --file kwinrc --group Compositing --key OpenGLIsUnsafe false 2>/dev/null
kwriteconfig5 --file kwinrc --group Plugins --key blurEnabled true 2>/dev/null
kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_magiclamEnabled true 2>/dev/null
kwriteconfig5 --file kwinrc --group Plugins --key slideEnabled true 2>/dev/null
kwriteconfig5 --file kwinrc --group Plugins --key wobblywindowsEnabled true 2>/dev/null

plasma-apply-wallpaperimage \
    /usr/share/wallpapers/NexOS/contents/images/1920x1080.jpg 2>/dev/null || true

touch "$FLAG"
BASHEOF
chmod +x /etc/profile.d/nexos-kde-init.sh

log "KDE defaults script installed"

# ── Branding ─────────────────────────────────────────────────
step "NexOS Branding"

cat > /etc/os-release << 'EOF'
NAME="NexOS"
PRETTY_NAME="NexOS 1.0 (Based on Ubuntu 24.04)"
ID=nexos
ID_LIKE=ubuntu
VERSION="1.0"
VERSION_ID="1.0"
HOME_URL=""
UBUNTU_CODENAME=noble
EOF

cat > /etc/motd << 'EOF'

  ███╗   ██╗███████╗██╗  ██╗ ██████╗ ███████╗
  ████╗  ██║██╔════╝╚██╗██╔╝██╔═══██╗██╔════╝
  ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
  ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
  ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
  NexOS v1.0  |  type 'neofetch'

EOF

log "Branding applied"

# ── Services ──────────────────────────────────────────────────
step "Service Configuration"

systemctl enable sddm             2>/dev/null || true
systemctl enable NetworkManager   2>/dev/null || true
systemctl set-default graphical.target 2>/dev/null || true
systemctl disable systemd-networkd 2>/dev/null || true

log "Services configured"

# ── VirtualBox Guest Additions ────────────────────────────────
step "VirtualBox Guest Additions"

apt-get install -yq \
    virtualbox-guest-utils \
    virtualbox-guest-x11 \
    2>/dev/null && log "VirtualBox guest additions installed" || \
    info "VirtualBox guest additions skipped (will install at runtime if needed)"

# ── Rebuild initramfs ─────────────────────────────────────────
step "Initramfs"

update-initramfs -u -k all 2>/dev/null || update-initramfs -u 2>/dev/null
log "Initramfs updated"

# ── Cleanup ───────────────────────────────────────────────────
step "Cleanup"

apt-get autoremove -yq 2>/dev/null || true
apt-get autoclean   -yq 2>/dev/null || true
apt-get clean          2>/dev/null || true

# Remove build artifacts from chroot
rm -rf /tmp/*                2>/dev/null || true
rm -rf /var/lib/apt/lists/*  2>/dev/null || true
rm -f  /etc/resolv.conf      2>/dev/null || true

cat > /etc/resolv.conf << 'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# History
truncate -s0 /root/.bash_history 2>/dev/null || true

log "Cleanup done"

echo ""
echo -e "\033[0;32m\033[1m  NexOS chroot setup complete!\033[0m"
echo ""
