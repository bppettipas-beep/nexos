#!/usr/bin/env bash
# =============================================================
#  NexOS Installer v1.0
#  Transforms Ubuntu 24.04 into a gaming-focused desktop OS
# =============================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

NEXOS_VERSION="1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/nexos-install.log"
ACTUAL_USER="${SUDO_USER:-$USER}"

print_banner() {
    clear
    echo -e "${PURPLE}"
    cat << 'EOF'
    ███╗   ██╗███████╗██╗  ██╗ ██████╗ ███████╗
    ████╗  ██║██╔════╝╚██╗██╔╝██╔═══██╗██╔════╝
    ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
    ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
    ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
    ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
EOF
    echo -e "${CYAN}         Gaming OS Installer v${NEXOS_VERSION}${NC}"
    echo -e "${YELLOW}         Based on Ubuntu 24.04 LTS${NC}"
    echo ""
}

log()   { echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"; }
info()  { echo -e "${CYAN}[→]${NC} $1" | tee -a "$LOG_FILE"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"; }
step()  { echo -e "\n${PURPLE}${BOLD}══════ $1 ══════${NC}\n" | tee -a "$LOG_FILE"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Run with sudo: sudo bash install.sh"
        exit 1
    fi
}

check_ubuntu() {
    if ! command -v lsb_release &>/dev/null; then
        error "lsb_release not found. Is this Ubuntu?"
        exit 1
    fi
    local ver
    ver=$(lsb_release -rs)
    if [[ "$ver" != "24.04" ]]; then
        warn "Designed for 24.04, you have $ver — continuing anyway"
    fi
    log "Ubuntu $ver detected"
}

install_kde() {
    step "KDE Plasma 6 Desktop"

    export DEBIAN_FRONTEND=noninteractive

    info "Disabling snapd..."
    systemctl stop snapd 2>/dev/null || true
    apt-get purge -yq snapd 2>/dev/null || true
    apt-mark hold snapd 2>/dev/null || true

    apt-get update -qq
    apt-get install -yq \
        kde-plasma-desktop \
        sddm \
        plasma-workspace \
        plasma-nm \
        plasma-pa \
        plasma-widgets-addons \
        kdeplasma-addons \
        kwin-x11 \
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
        2>>"$LOG_FILE"

    log "KDE Plasma installed"
}

configure_sddm() {
    step "Display Manager (SDDM)"

    systemctl enable sddm
    systemctl set-default graphical.target
    systemctl disable gdm3 2>/dev/null || true
    systemctl disable lightdm 2>/dev/null || true

    log "SDDM set as default display manager"
}

install_gaming() {
    step "Gaming Tools"

    dpkg --add-architecture i386
    apt-get update -qq

    info "Steam..."
    apt-get install -yq steam-installer 2>>"$LOG_FILE" || \
    apt-get install -yq steam 2>>"$LOG_FILE" || \
    warn "Steam skipped — install manually after boot"

    info "Wine..."
    apt-get install -yq \
        wine \
        wine32:i386 \
        wine64 \
        winetricks \
        2>>"$LOG_FILE" || warn "Wine skipped"

    info "Lutris..."
    apt-get install -yq lutris 2>>"$LOG_FILE" || \
    (add-apt-repository -y ppa:lutris-team/lutris 2>>"$LOG_FILE" && \
     apt-get update -qq && \
     apt-get install -yq lutris 2>>"$LOG_FILE") || \
    warn "Lutris skipped"

    info "GameMode + MangoHud..."
    apt-get install -yq gamemode mangohud 2>>"$LOG_FILE" || true

    info "Vulkan..."
    apt-get install -yq vulkan-tools libvulkan1 mesa-vulkan-drivers 2>>"$LOG_FILE" || true

    usermod -aG gamemode "$ACTUAL_USER" 2>/dev/null || true

    log "Gaming tools installed"
}

install_performance() {
    step "Performance Tools & Tweaks"

    apt-get install -yq preload zram-config cpufrequtils 2>>"$LOG_FILE" || true

    cat > /etc/sysctl.d/99-nexos.conf << 'EOF'
vm.swappiness=10
vm.vfs_cache_pressure=50
fs.inotify.max_user_watches=524288
net.core.netdev_max_backlog=16384
net.core.somaxconn=8192
net.ipv4.tcp_fastopen=3
EOF

    sysctl -p /etc/sysctl.d/99-nexos.conf 2>/dev/null || true

    log "Performance tweaks applied"
}

install_essentials() {
    step "Essential Applications"

    apt-get install -yq \
        firefox \
        vlc \
        htop \
        neofetch \
        curl \
        wget \
        git \
        python3 \
        python3-pip \
        python3-tk \
        fonts-jetbrains-mono \
        fonts-noto \
        fonts-noto-color-emoji \
        flatpak \
        2>>"$LOG_FILE" || true

    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

    log "Essential apps installed"
}

install_theming_deps() {
    step "Theming Dependencies"

    # Kvantum (advanced Qt theming engine)
    apt-get install -yq qt5-style-kvantum qt5-style-kvantum-themes 2>>"$LOG_FILE" || true

    # Papirus icons
    add-apt-repository -y ppa:papirus/papirus 2>>"$LOG_FILE" || true
    apt-get update -qq
    apt-get install -yq papirus-icon-theme 2>>"$LOG_FILE" || true

    # Bibata cursor
    apt-get install -yq bibata-cursor-theme 2>>"$LOG_FILE" || {
        info "Downloading Bibata cursor..."
        local url="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz"
        curl -fsSLo /tmp/bibata.tar.xz "$url" 2>>"$LOG_FILE" && \
        tar xf /tmp/bibata.tar.xz -C /usr/share/icons/ 2>>"$LOG_FILE" && \
        log "Bibata cursor installed" || warn "Bibata skipped"
    }

    log "Theming deps done"
}

create_color_scheme() {
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

    log "Color scheme created"
}

create_sddm_theme() {
    step "SDDM Login Theme"

    local dir="/usr/share/sddm/themes/nexos"
    mkdir -p "$dir"

    cat > "$dir/theme.conf" << 'EOF'
[General]
blur=true
recursiveBlurLoops=4
recursiveBlurRadius=6
showUserRealNameByDefault=false
fontSize=12
EOF

    # Copy SDDM QML from themes dir if present, otherwise inline it
    if [[ -f "$SCRIPT_DIR/themes/sddm/Main.qml" ]]; then
        cp "$SCRIPT_DIR/themes/sddm/Main.qml" "$dir/Main.qml"
    else
        # Inline fallback
        cp /usr/share/sddm/themes/breeze/Main.qml "$dir/Main.qml" 2>/dev/null || \
        cat > "$dir/Main.qml" << 'QMLEOF'
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    color: "#08080f"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Diagonal
            GradientStop { position: 0.0; color: "#08080f" }
            GradientStop { position: 1.0; color: "#04040a" }
        }
    }

    Canvas {
        anchors.fill: parent
        opacity: 0.07
        onPaint: {
            var ctx = getContext("2d")
            ctx.strokeStyle = "#00f5ff"
            ctx.lineWidth = 0.5
            for (var x = 0; x <= width; x += 55) {
                ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
            }
            for (var y = 0; y <= height; y += 55) {
                ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
            }
        }
    }

    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 64 }
        spacing: 6

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#ffffff"
            font.pixelSize: 68
            font.weight: Font.Light
            font.family: "JetBrains Mono"
            text: Qt.formatTime(new Date(), "HH:mm")
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.text = Qt.formatTime(new Date(), "HH:mm") }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: "#00f5ff"
            font.pixelSize: 16
            font.family: "JetBrains Mono"
            text: Qt.formatDate(new Date(), "dddd, MMMM d yyyy")
        }
    }

    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 230 }
        spacing: 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "NEX"
            color: "#00f5ff"
            font.pixelSize: 48
            font.weight: Font.Bold
            font.family: "JetBrains Mono"
            font.letterSpacing: 14
        }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 180; height: 2; color: "#00f5ff"; opacity: 0.7 }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "OS"
            color: "#bf5fff"
            font.pixelSize: 22
            font.family: "JetBrains Mono"
            font.letterSpacing: 22
        }
    }

    Rectangle {
        id: loginBox
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 50
        width: 360
        height: 270
        color: "#0a0a1a"
        opacity: 0.92
        radius: 10
        border.color: "#00f5ff"
        border.width: 1

        ColumnLayout {
            anchors { fill: parent; margins: 28 }
            spacing: 14

            Column {
                Layout.fillWidth: true
                spacing: 5
                Text { text: "USERNAME"; color: "#00f5ff"; font.pixelSize: 9; font.family: "JetBrains Mono"; font.letterSpacing: 2 }
                Rectangle {
                    width: parent.width; height: 40; color: "#0d0d22"; radius: 5
                    border.color: userInput.activeFocus ? "#00f5ff" : "#252545"; border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 180 } }
                    TextInput {
                        id: userInput
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#ffffff"; font.pixelSize: 13; font.family: "JetBrains Mono"
                        text: userModel.lastUser
                        KeyNavigation.tab: passInput
                    }
                }
            }

            Column {
                Layout.fillWidth: true
                spacing: 5
                Text { text: "PASSWORD"; color: "#00f5ff"; font.pixelSize: 9; font.family: "JetBrains Mono"; font.letterSpacing: 2 }
                Rectangle {
                    width: parent.width; height: 40; color: "#0d0d22"; radius: 5
                    border.color: passInput.activeFocus ? "#00f5ff" : "#252545"; border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 180 } }
                    TextInput {
                        id: passInput
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#ffffff"; font.pixelSize: 13; font.family: "JetBrains Mono"
                        echoMode: TextInput.Password
                        Keys.onReturnPressed: sddm.login(userInput.text, passInput.text, session.index)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 42; radius: 5
                color: loginMouse.containsMouse ? "#00d0e0" : "#00f5ff"
                Behavior on color { ColorAnimation { duration: 130 } }
                Text {
                    anchors.centerIn: parent
                    text: "ENTER NEXOS"
                    color: "#000000"; font.pixelSize: 11; font.weight: Font.Bold
                    font.family: "JetBrains Mono"; font.letterSpacing: 2
                }
                MouseArea {
                    id: loginMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.login(userInput.text, passInput.text, session.index)
                }
            }
        }
    }

    Text {
        anchors { horizontalCenter: parent.horizontalCenter; top: loginBox.bottom; topMargin: 14 }
        color: "#ff2d78"; font.pixelSize: 12; font.family: "JetBrains Mono"
        text: sddm.lastError
    }

    ComboBox {
        id: session
        anchors { bottom: parent.bottom; right: parent.right; margins: 18 }
        width: 200; height: 30; model: sessionModel; textRole: "name"
        contentItem: Text {
            leftPadding: 8; text: session.displayText
            color: "#888888"; font.pixelSize: 10; font.family: "JetBrains Mono"
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle { color: "#0d0d20"; radius: 4; border.color: "#252545"; border.width: 1 }
    }

    Component.onCompleted: {
        if (userInput.text) passInput.forceActiveFocus()
        else userInput.forceActiveFocus()
    }
}
QMLEOF
    fi

    # Apply SDDM config
    mkdir -p /etc/sddm.conf.d
    cat > /etc/sddm.conf.d/nexos.conf << 'EOF'
[Theme]
Current=nexos
CursorTheme=Bibata-Modern-Classic

[General]
DisplayServer=x11
InputMethod=

[Users]
DefaultUser=
EOF

    log "SDDM theme installed"
}

create_wallpaper() {
    step "NexOS Wallpaper"

    mkdir -p /usr/share/wallpapers/NexOS/contents/images

    python3 - << 'PYEOF' 2>/dev/null && log "Wallpaper generated" || {
        warn "Pillow not available, using system wallpaper fallback"
        find /usr/share/wallpapers -name "*.jpg" | head -1 | \
            xargs -I{} cp {} /usr/share/wallpapers/NexOS/contents/images/1920x1080.jpg 2>/dev/null || true
    }
import sys
try:
    from PIL import Image, ImageDraw, ImageFilter
except ImportError:
    import subprocess
    subprocess.run(["pip3", "install", "Pillow", "-q"], check=False)
    from PIL import Image, ImageDraw, ImageFilter

w, h = 1920, 1080
img = Image.new("RGB", (w, h), "#08080f")
draw = ImageDraw.Draw(img)

for x in range(0, w, 55):
    draw.line([(x, 0), (x, h)], fill="#0d1020", width=1)
for y in range(0, h, 55):
    draw.line([(0, y), (w, y)], fill="#0d1020", width=1)

overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
d2 = ImageDraw.Draw(overlay)
d2.ellipse([-100, -100, 800, 800], fill=(0, 245, 255, 10))
d2.ellipse([1200, 300, 2100, 1200], fill=(191, 95, 255, 8))
d2.ellipse([700, 500, 1500, 1300], fill=(0, 200, 120, 5))

base = img.convert("RGBA")
base = Image.alpha_composite(base, overlay)
img = base.convert("RGB")

img.save("/usr/share/wallpapers/NexOS/contents/images/1920x1080.jpg", "JPEG", quality=95)
img.save("/usr/share/wallpapers/NexOS/contents/images/3840x2160.jpg", "JPEG", quality=95)
PYEOF

    cat > /usr/share/wallpapers/NexOS/metadata.json << 'EOF'
{
    "KPlugin": {
        "Authors": [{"Name": "NexOS"}],
        "Id": "NexOS",
        "License": "CC-BY-4.0",
        "Name": "NexOS Default"
    }
}
EOF
}

install_first_boot_wizard() {
    step "First Boot Wizard"

    mkdir -p /opt/nexos-setup

    # Copy wizard from script dir or write inline
    if [[ -f "$SCRIPT_DIR/first-boot/wizard.py" ]]; then
        cp "$SCRIPT_DIR/first-boot/wizard.py" /opt/nexos-setup/wizard.py
    else
        # The wizard is embedded via heredoc in first-boot/wizard.py
        # If running standalone, the file must be present. Error out.
        error "first-boot/wizard.py not found. Run from the NexOS project directory."
        exit 1
    fi

    chmod +x /opt/nexos-setup/wizard.py

    # Wrapper that ensures DISPLAY is set
    cat > /opt/nexos-setup/launch.sh << 'EOF'
#!/bin/bash
export DISPLAY="${DISPLAY:-:0}"
export XAUTHORITY="${XAUTHORITY:-/home/$(whoami)/.Xauthority}"
exec /usr/bin/python3 /opt/nexos-setup/wizard.py
EOF
    chmod +x /opt/nexos-setup/launch.sh

    # Autostart for root session (runs before user is created)
    mkdir -p /root/.config/autostart
    cat > /root/.config/autostart/nexos-setup.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=NexOS Setup
Exec=/opt/nexos-setup/launch.sh
X-KDE-autostart-phase=2
StartupNotify=false
EOF

    # Systemd fallback
    cat > /etc/systemd/system/nexos-setup.service << 'EOF'
[Unit]
Description=NexOS First Boot Setup
ConditionPathExists=/opt/nexos-setup/wizard.py
ConditionPathExists=!/opt/nexos-setup/.done
After=graphical.target sddm.service
Wants=graphical.target

[Service]
Type=simple
ExecStart=/opt/nexos-setup/launch.sh
Environment=DISPLAY=:0
User=root
RemainAfterExit=no

[Install]
WantedBy=graphical.target
EOF

    systemctl enable nexos-setup.service 2>/dev/null || true

    log "First boot wizard installed at /opt/nexos-setup/"
}

configure_kde_defaults() {
    step "KDE Default Configuration"

    # Global init script — runs once per new user session
    cat > /etc/profile.d/nexos-kde-init.sh << 'BASHEOF'
#!/bin/bash
FLAG="$HOME/.config/.nexos-initialized"
[[ -f "$FLAG" ]] && return 0

# Color scheme
kwriteconfig5 --file kdeglobals --group General --key ColorScheme NexOS 2>/dev/null
kwriteconfig5 --file kdeglobals --group Icons --key Theme "Papirus-Dark" 2>/dev/null
kwriteconfig5 --file kcminputrc --group Mouse --key cursorTheme "Bibata-Modern-Classic" 2>/dev/null

# Fonts
for key in font fixed menuFont toolBarFont smallestReadableFont; do
    kwriteconfig5 --file kdeglobals --group General --key "$key" "JetBrains Mono,10,-1,5,50,0,0,0,0,0" 2>/dev/null
done

# Faster animations
kwriteconfig5 --file kdeglobals --group KDE --key AnimationDurationFactor 0.5 2>/dev/null

# KWin compositing & effects
kwriteconfig5 --file kwinrc --group Compositing --key Backend OpenGL 2>/dev/null
kwriteconfig5 --file kwinrc --group Compositing --key GLCore true 2>/dev/null
kwriteconfig5 --file kwinrc --group Compositing --key OpenGLIsUnsafe false 2>/dev/null
kwriteconfig5 --file kwinrc --group Plugins --key blurEnabled true 2>/dev/null
kwriteconfig5 --file kwinrc --group Plugins --key kwin4_effect_magiclamEnabled true 2>/dev/null
kwriteconfig5 --file kwinrc --group Plugins --key slideEnabled true 2>/dev/null
kwriteconfig5 --file kwinrc --group Plugins --key wobblywindowsEnabled true 2>/dev/null
kwriteconfig5 --file kwinrc --group Effect-Wobbly --key Stiffness 10 2>/dev/null

# Wallpaper
plasma-apply-wallpaperimage /usr/share/wallpapers/NexOS/contents/images/1920x1080.jpg 2>/dev/null || true

touch "$FLAG"
BASHEOF

    chmod +x /etc/profile.d/nexos-kde-init.sh
    log "KDE defaults configured"
}

install_vbox_additions() {
    step "VirtualBox Guest Additions"

    if dmidecode -s system-product-name 2>/dev/null | grep -qi "virtualbox" || \
       lspci 2>/dev/null | grep -qi "virtualbox"; then

        info "VirtualBox VM detected"
        apt-get install -yq \
            virtualbox-guest-utils \
            virtualbox-guest-x11 \
            linux-headers-generic \
            2>>"$LOG_FILE" || warn "Guest additions install failed"

        usermod -aG vboxsf "$ACTUAL_USER" 2>/dev/null || true
        log "VirtualBox Guest Additions installed"
    else
        info "Not running in VirtualBox, skipping"
    fi
}

apply_branding() {
    step "NexOS Branding"

    cat > /etc/os-release << 'EOF'
NAME="NexOS"
PRETTY_NAME="NexOS 1.0 (Based on Ubuntu 24.04)"
ID=nexos
ID_LIKE=ubuntu
VERSION="1.0"
VERSION_ID="1.0"
HOME_URL=""
LOGO=nexos-logo
UBUNTU_CODENAME=noble
EOF

    cat > /etc/issue << 'EOF'

  NexOS v1.0  |  Gaming-Focused Linux
  Based on Ubuntu 24.04 LTS

EOF

    cat > /etc/motd << 'EOF'

  ███╗   ██╗███████╗██╗  ██╗ ██████╗ ███████╗
  ████╗  ██║██╔════╝╚██╗██╔╝██╔═══██╗██╔════╝
  ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
  ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
  ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
  NexOS v1.0  |  type 'neofetch' for system info

EOF

    log "Branding applied"
}

print_done() {
    echo ""
    echo -e "${PURPLE}${BOLD}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  NexOS Installation Complete!${NC}"
    echo -e "${PURPLE}${BOLD}══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}  Installed:${NC}"
    echo -e "  ${GREEN}✓${NC}  KDE Plasma 6 with NexOS theme"
    echo -e "  ${GREEN}✓${NC}  SDDM login screen (neon dark)"
    echo -e "  ${GREEN}✓${NC}  Gaming tools (Steam, Lutris, Wine, GameMode, MangoHud)"
    echo -e "  ${GREEN}✓${NC}  Performance optimizations"
    echo -e "  ${GREEN}✓${NC}  First-boot setup wizard"
    echo -e "  ${GREEN}✓${NC}  NexOS branding & wallpaper"
    echo ""
    echo -e "${YELLOW}  What to do now:${NC}"
    echo -e "  ${BOLD}sudo reboot${NC}"
    echo ""
    echo -e "  On reboot → SDDM login → sign in as ${BOLD}root${NC} (temporary)"
    echo -e "  → Setup wizard opens → create your account → reboot again"
    echo ""
    echo -e "${CYAN}  Full log: ${NC}$LOG_FILE"
    echo ""
}

main() {
    print_banner
    check_root
    check_ubuntu

    echo -e "${CYAN}  This will install NexOS on top of Ubuntu.${NC}"
    echo -e "${YELLOW}  Estimated time: 15–35 min (depending on connection).${NC}"
    echo ""
    read -rp "$(echo -e "${CYAN}  Proceed? [y/N]: ${NC}")" confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

    echo "" | tee "$LOG_FILE"

    install_kde
    configure_sddm
    install_gaming
    install_performance
    install_essentials
    install_theming_deps
    create_color_scheme
    create_sddm_theme
    create_wallpaper
    install_first_boot_wizard
    configure_kde_defaults
    install_vbox_additions
    apply_branding

    print_done
}

main "$@"
