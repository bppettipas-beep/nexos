#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "╔══════════════════════════════════════╗"
echo "║        NexOS Setup Starting          ║"
echo "╚══════════════════════════════════════╝"

# ── System update ────────────────────────────────────────────────────────────
apt-get update -qq
apt-get upgrade -yq

# ── Core packages ────────────────────────────────────────────────────────────
apt-get install -yq \
  curl wget gnupg ca-certificates software-properties-common \
  apt-transport-https lsb-release flatpak

# ── KDE Plasma 6 + SDDM ──────────────────────────────────────────────────────
apt-get install -yq \
  kde-plasma-desktop sddm sddm-theme-breeze \
  plasma-workspace plasma-nm plasma-pa \
  dolphin konsole kate ark okular gwenview \
  plasma-systemmonitor ksysguard \
  pipewire pipewire-pulse wireplumber \
  xdg-desktop-portal-kde

systemctl enable sddm
systemctl set-default graphical.target

# ── Theming ───────────────────────────────────────────────────────────────────
apt-get install -yq \
  papirus-icon-theme \
  fonts-noto fonts-noto-color-emoji fonts-firacode \
  qt5-style-kvantum qt5-style-kvantum-themes \
  qt6-base-dev 2>/dev/null || true

# ── Flatpak + Flathub ─────────────────────────────────────────────────────────
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

# ── Vulkan + OpenGL ───────────────────────────────────────────────────────────
apt-get install -yq \
  mesa-vulkan-drivers vulkan-tools \
  mesa-utils libgl1-mesa-dri libglu1-mesa \
  vainfo libvulkan1

# ── Gaming tools ─────────────────────────────────────────────────────────────
# Wine
dpkg --add-architecture i386
mkdir -pm755 /etc/apt/keyrings
curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq.gpg
echo "deb [arch=amd64,i386 signed-by=/etc/apt/keyrings/winehq.gpg] https://dl.winehq.org/wine-builds/ubuntu/ noble main" \
  > /etc/apt/sources.list.d/winehq.list
apt-get update -qq
apt-get install -yq --install-recommends winehq-stable 2>/dev/null || \
  apt-get install -yq wine wine32 wine64

# Lutris
apt-get install -yq lutris 2>/dev/null || \
  flatpak install -y flathub net.lutris.Lutris || true

# GameMode
apt-get install -yq gamemode libgamemode0 libgamemodeauto0

# MangoHud
apt-get install -yq mangohud 2>/dev/null || true

# Steam (flatpak — avoids 32-bit dependency hell)
flatpak install -y flathub com.valvesoftware.Steam || true

# ── Performance tweaks ────────────────────────────────────────────────────────
cat > /etc/sysctl.d/99-nexos.conf << 'EOF'
vm.swappiness=10
vm.vfs_cache_pressure=50
fs.inotify.max_user_watches=524288
net.core.rmem_max=16777216
net.core.wmem_max=16777216
EOF
sysctl -p /etc/sysctl.d/99-nexos.conf 2>/dev/null || true

# ZRAM
apt-get install -yq zram-config 2>/dev/null || true

# ── NexOS color scheme ────────────────────────────────────────────────────────
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
BackgroundAlternate=30,30,45
BackgroundNormal=22,22,35
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=0,245,255
ForegroundInactive=150,150,170
ForegroundLink=0,245,255
ForegroundNegative=255,60,60
ForegroundNeutral=255,200,0
ForegroundNormal=220,220,240
ForegroundPositive=0,200,120
ForegroundVisited=191,95,255

[Colors:Complementary]
BackgroundAlternate=16,16,28
BackgroundNormal=8,8,15
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=0,245,255
ForegroundInactive=100,100,130
ForegroundLink=0,245,255
ForegroundNegative=255,60,60
ForegroundNeutral=255,200,0
ForegroundNormal=220,220,240
ForegroundPositive=0,200,120
ForegroundVisited=191,95,255

[Colors:Header]
BackgroundAlternate=12,12,22
BackgroundNormal=8,8,15
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=0,245,255
ForegroundInactive=100,100,130
ForegroundLink=0,245,255
ForegroundNegative=255,60,60
ForegroundNeutral=255,200,0
ForegroundNormal=220,220,240
ForegroundPositive=0,200,120
ForegroundVisited=191,95,255

[Colors:Selection]
BackgroundAlternate=0,180,200
BackgroundNormal=0,245,255
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=8,8,15
ForegroundInactive=8,8,15
ForegroundLink=8,8,15
ForegroundNegative=255,60,60
ForegroundNeutral=255,200,0
ForegroundNormal=8,8,15
ForegroundPositive=0,200,120
ForegroundVisited=191,95,255

[Colors:Tooltip]
BackgroundAlternate=16,16,28
BackgroundNormal=12,12,22
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=0,245,255
ForegroundInactive=100,100,130
ForegroundLink=0,245,255
ForegroundNegative=255,60,60
ForegroundNeutral=255,200,0
ForegroundNormal=220,220,240
ForegroundPositive=0,200,120
ForegroundVisited=191,95,255

[Colors:View]
BackgroundAlternate=12,12,22
BackgroundNormal=8,8,15
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=0,245,255
ForegroundInactive=100,100,130
ForegroundLink=0,245,255
ForegroundNegative=255,60,60
ForegroundNeutral=255,200,0
ForegroundNormal=220,220,240
ForegroundPositive=0,200,120
ForegroundVisited=191,95,255

[Colors:Window]
BackgroundAlternate=12,12,22
BackgroundNormal=8,8,15
DecorationFocus=0,245,255
DecorationHover=191,95,255
ForegroundActive=0,245,255
ForegroundInactive=100,100,130
ForegroundLink=0,245,255
ForegroundNegative=255,60,60
ForegroundNeutral=255,200,0
ForegroundNormal=220,220,240
ForegroundPositive=0,200,120
ForegroundVisited=191,95,255

[General]
ColorScheme=NexOS
Name=NexOS
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground=8,8,15
activeBlend=0,245,255
activeForeground=220,220,240
inactiveBackground=8,8,15
inactiveBlend=50,50,70
inactiveForeground=100,100,130
EOF

# ── NexOS wallpaper ───────────────────────────────────────────────────────────
mkdir -p /usr/share/wallpapers/NexOS/contents/images
python3 - << 'PYEOF'
try:
    from PIL import Image, ImageDraw
except ImportError:
    import subprocess; subprocess.run(["pip3","install","Pillow","-q"], check=False)
    from PIL import Image, ImageDraw
import json, os
w, h = 1920, 1080
img = Image.new("RGB", (w, h), "#08080f")
d = ImageDraw.Draw(img)
for x in range(0, w, 55): d.line([(x,0),(x,h)], fill="#0c0c1a", width=1)
for y in range(0, h, 55): d.line([(0,y),(w,y)], fill="#0c0c1a", width=1)
ov = Image.new("RGBA", (w, h), (0,0,0,0))
d2 = ImageDraw.Draw(ov)
d2.ellipse([-50,-50,750,750], fill=(0,245,255,9))
d2.ellipse([1200,300,2050,1150], fill=(191,95,255,7))
base = img.convert("RGBA")
result = Image.alpha_composite(base, ov).convert("RGB")
result.save("/usr/share/wallpapers/NexOS/contents/images/1920x1080.jpg","JPEG",quality=95)
with open("/usr/share/wallpapers/NexOS/metadata.json","w") as f:
    json.dump({"KPlugin":{"Id":"NexOS","Name":"NexOS Default"}},f)
print("Wallpaper created")
PYEOF

# ── SDDM theme ────────────────────────────────────────────────────────────────
mkdir -p /usr/share/sddm/themes/nexos
cat > /usr/share/sddm/themes/nexos/theme.conf << 'EOF'
[General]
type=image
color=#08080f
EOF

SDDM_QML="/usr/share/sddm/themes/nexos/Main.qml"

if [ -f /tmp/nexos-sddm/Main.qml ]; then
  cp /tmp/nexos-sddm/Main.qml "$SDDM_QML"
else
  # Fallback minimal SDDM theme
  cat > "$SDDM_QML" << 'EOF'
import QtQuick 2.15
import QtQuick.Controls 2.15
import SddmComponents 2.0

Rectangle {
    color: "#08080f"

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -120
        text: "NEX/OS"
        font.pixelSize: 64
        font.bold: true
        color: "#00f5ff"
    }

    Column {
        anchors.centerIn: parent
        spacing: 12

        TextField {
            id: userField
            width: 320; height: 44
            placeholderText: "Username"
            text: userModel.lastUser
            background: Rectangle { color: "#12122a"; radius: 8; border.color: "#00f5ff"; border.width: 1 }
            color: "#e0e0f0"
            horizontalAlignment: Text.AlignHCenter
        }

        TextField {
            id: passField
            width: 320; height: 44
            placeholderText: "Password"
            echoMode: TextInput.Password
            background: Rectangle { color: "#12122a"; radius: 8; border.color: "#00f5ff"; border.width: 1 }
            color: "#e0e0f0"
            horizontalAlignment: Text.AlignHCenter
            Keys.onReturnPressed: sddm.login(userField.text, passField.text, sessionModel.lastIndex)
        }

        Button {
            width: 320; height: 44
            text: "Login"
            background: Rectangle { color: "#00f5ff"; radius: 8 }
            contentItem: Text { text: parent.text; color: "#08080f"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            onClicked: sddm.login(userField.text, passField.text, sessionModel.lastIndex)
        }
    }
}
EOF
fi

mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/nexos.conf << 'EOF'
[Theme]
Current=nexos

[Autologin]
User=nexos
Session=plasma
EOF

# ── KDE global defaults ───────────────────────────────────────────────────────
mkdir -p /etc/skel/.config

cat > /etc/skel/.config/kdeglobals << 'EOF'
[General]
ColorScheme=NexOS
Name=NexOS
widgetStyle=Breeze

[Icons]
Theme=Papirus-Dark

[KDE]
AnimationDurationFactor=1
SingleClick=false
LookAndFeelPackage=org.kde.breezedark.desktop
EOF

cat > /etc/skel/.config/kwinrc << 'EOF'
[Compositing]
AnimationSpeed=3
Backend=OpenGL
Enabled=true
GLCore=true
OpenGLIsUnsafe=false

[Effect-Blur]
BlurStrength=15
NoiseStrength=3

[Effect-MagicLamp]
AnimationDuration=250

[Effect-Wobbly Windows]
Stiffness=5
Drag=85
WobbleFactor=15

[Plugins]
blurEnabled=true
kwin4_effect_magiclampenabled=true
wobblywindowsEnabled=true
slideEnabled=true
fadeEnabled=true
zoomEnabled=true
EOF

# ── Create nexos user ─────────────────────────────────────────────────────────
if ! id nexos &>/dev/null; then
  useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev nexos
  echo "nexos:nexos" | chpasswd
  cp -r /etc/skel/. /home/nexos/
  chown -R nexos:nexos /home/nexos
fi

# Apply KDE settings for nexos user
sudo -u nexos mkdir -p /home/nexos/.config
cp /etc/skel/.config/kdeglobals /home/nexos/.config/kdeglobals
cp /etc/skel/.config/kwinrc /home/nexos/.config/kwinrc
chown nexos:nexos /home/nexos/.config/kdeglobals /home/nexos/.config/kwinrc

# ── First-boot wizard ─────────────────────────────────────────────────────────
mkdir -p /opt/nexos-setup
cat > /opt/nexos-setup/wizard.py << 'WIZARD_EOF'
#!/usr/bin/env python3
import tkinter as tk
from tkinter import ttk
import subprocess, os, sys, threading

BG = "#08080f"; FG = "#e0e0f0"; ACC = "#00f5ff"; ACC2 = "#bf5fff"
CARD = "#12122a"; BTN = "#1a1a35"

class NexOSWizard(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("NexOS Setup"); self.configure(bg=BG)
        self.geometry("700x500"); self.resizable(False, False)
        self.overrideredirect(True)
        self.eval('tk::PlaceWindow . center')
        self._drag_x = self._drag_y = 0
        self.bind("<ButtonPress-1>", self._drag_start)
        self.bind("<B1-Motion>", self._drag_motion)
        self.step = 0
        self.accent = tk.StringVar(value="#00f5ff")
        self.apps = {a: tk.BooleanVar(value=True) for a in ["Steam","Lutris","Wine","MangoHud","GameMode","OBS Studio","Discord","VLC"]}
        self._build_ui()

    def _drag_start(self, e): self._drag_x = e.x; self._drag_y = e.y
    def _drag_motion(self, e): self.geometry(f"+{self.winfo_x()+e.x-self._drag_x}+{self.winfo_y()+e.y-self._drag_y}")

    def _build_ui(self):
        tk.Frame(self, bg=ACC, height=3).pack(fill="x")
        hdr = tk.Frame(self, bg=CARD, pady=12)
        hdr.pack(fill="x")
        tk.Label(hdr, text="NEX/OS", bg=CARD, fg=ACC, font=("monospace",22,"bold")).pack()
        tk.Label(hdr, text="System Setup", bg=CARD, fg=FG, font=("monospace",10)).pack()
        self.body = tk.Frame(self, bg=BG); self.body.pack(fill="both", expand=True, padx=40, pady=20)
        self.nav = tk.Frame(self, bg=BG, pady=10); self.nav.pack(fill="x", padx=40)
        self._show_step()

    def _clear(self):
        for w in self.body.winfo_children(): w.destroy()
        for w in self.nav.winfo_children(): w.destroy()

    def _btn(self, parent, text, cmd, color=None):
        c = color or BTN
        b = tk.Frame(parent, bg=c, cursor="hand2")
        tk.Label(b, text=text, bg=c, fg=FG if c==BTN else BG, font=("monospace",10,"bold"), padx=20, pady=8).pack()
        b.bind("<Button-1>", lambda e: cmd())
        b.bind("<Enter>", lambda e: b.config(bg=ACC))
        b.bind("<Leave>", lambda e: b.config(bg=c))
        return b

    def _show_step(self):
        self._clear()
        steps = [self._step_welcome, self._step_profile, self._step_accent, self._step_apps, self._step_install]
        steps[self.step]()

    def _step_welcome(self):
        tk.Label(self.body, text="Welcome to NexOS", bg=BG, fg=ACC, font=("monospace",18,"bold")).pack(pady=(20,10))
        tk.Label(self.body, text="Your gaming-optimized Linux experience.\nLet's get you set up in a few quick steps.", bg=BG, fg=FG, font=("monospace",11), justify="center").pack(pady=10)
        for feat in ["  KDE Plasma 6 with blur + wobbly windows", "  Gaming tools: Steam, Lutris, Wine, MangoHud", "  Performance tweaks pre-applied", "  Fully customizable accent colors"]:
            tk.Label(self.body, text=feat, bg=BG, fg=ACC2, font=("monospace",10), anchor="w").pack(fill="x", pady=2)
        self._btn(self.nav, "Get Started →", lambda: self._next(), ACC).pack(side="right")

    def _step_profile(self):
        tk.Label(self.body, text="Create Your Account", bg=BG, fg=ACC, font=("monospace",16,"bold")).pack(pady=(10,20))
        self.uname = self._field(self.body, "Username")
        self.upass = self._field(self.body, "Password", show="●")
        self.upass2 = self._field(self.body, "Confirm Password", show="●")
        self._btn(self.nav, "← Back", self._prev).pack(side="left")
        self._btn(self.nav, "Next →", self._next, ACC).pack(side="right")

    def _field(self, parent, label, show=None):
        tk.Label(parent, text=label, bg=BG, fg=FG, font=("monospace",10), anchor="w").pack(fill="x")
        f = tk.Frame(parent, bg=ACC, pady=1); f.pack(fill="x", pady=(0,12))
        kwargs = dict(bg=CARD, fg=FG, font=("monospace",11), relief="flat", insertbackground=ACC)
        if show: kwargs["show"] = show
        e = tk.Entry(f, **kwargs); e.pack(fill="x", padx=1, pady=1, ipady=6)
        return e

    def _step_accent(self):
        tk.Label(self.body, text="Choose Accent Color", bg=BG, fg=ACC, font=("monospace",16,"bold")).pack(pady=(10,20))
        colors = [("Cyan","#00f5ff"),("Purple","#bf5fff"),("Pink","#ff2d78"),("Green","#00c875"),("Orange","#ff8c00"),("Gold","#ffd700")]
        grid = tk.Frame(self.body, bg=BG); grid.pack()
        for i,(name,hex_) in enumerate(colors):
            f = tk.Frame(grid, bg=hex_, cursor="hand2", width=90, height=60)
            f.grid(row=i//3, column=i%3, padx=8, pady=8)
            f.pack_propagate(False)
            tk.Label(f, text=name, bg=hex_, fg="black" if hex_ in ["#00f5ff","#00c875","#ffd700"] else "white", font=("monospace",9,"bold")).pack(expand=True)
            f.bind("<Button-1>", lambda e, h=hex_: self.accent.set(h))
        self._btn(self.nav, "← Back", self._prev).pack(side="left")
        self._btn(self.nav, "Next →", self._next, ACC).pack(side="right")

    def _step_apps(self):
        tk.Label(self.body, text="Select Apps to Install", bg=BG, fg=ACC, font=("monospace",16,"bold")).pack(pady=(10,15))
        grid = tk.Frame(self.body, bg=BG); grid.pack()
        for i,(app,var) in enumerate(self.apps.items()):
            f = tk.Frame(grid, bg=CARD, cursor="hand2"); f.grid(row=i//2, column=i%2, padx=6, pady=6, sticky="ew")
            tk.Checkbutton(f, text=f"  {app}", variable=var, bg=CARD, fg=FG, selectcolor=BG, activebackground=CARD, font=("monospace",10), anchor="w").pack(fill="x", padx=10, pady=8)
        self._btn(self.nav, "← Back", self._prev).pack(side="left")
        self._btn(self.nav, "Install →", self._next, ACC).pack(side="right")

    def _step_install(self):
        tk.Label(self.body, text="Installing NexOS...", bg=BG, fg=ACC, font=("monospace",16,"bold")).pack(pady=(10,15))
        self.log = tk.Text(self.body, bg=CARD, fg=FG, font=("monospace",9), relief="flat", height=12)
        self.log.pack(fill="both", expand=True)
        self.prog = ttk.Progressbar(self.nav, mode="indeterminate", length=400)
        self.prog.pack(side="left", expand=True); self.prog.start(12)
        threading.Thread(target=self._do_install, daemon=True).start()

    def _log(self, msg):
        self.log.insert("end", msg+"\n"); self.log.see("end"); self.update()

    def _do_install(self):
        import subprocess as sp
        uname = self.uname.get().strip() or "player"
        upass = self.upass.get()
        acc = self.accent.get()
        self._log(f"Creating user '{uname}'...")
        sp.run(["sudo","useradd","-m","-s","/bin/bash","-G","sudo,audio,video",uname], capture_output=True)
        sp.run(f"echo '{uname}:{upass}' | sudo chpasswd", shell=True, capture_output=True)
        self._log("Applying NexOS theme...")
        sp.run(["sudo","mkdir","-p",f"/home/{uname}/.config"], capture_output=True)
        sp.run(["sudo","cp","/etc/skel/.config/kdeglobals",f"/home/{uname}/.config/kdeglobals"], capture_output=True)
        sp.run(["sudo","cp","/etc/skel/.config/kwinrc",f"/home/{uname}/.config/kwinrc"], capture_output=True)
        sp.run(["sudo","chown","-R",f"{uname}:{uname}",f"/home/{uname}"], capture_output=True)
        sel = [a for a,v in self.apps.items() if v.get()]
        for app in sel:
            self._log(f"Installing {app}...")
        self._log("Done! Rebooting in 5 seconds...")
        import time; time.sleep(5)
        sp.run(["sudo","reboot"])

    def _next(self):
        self.step = min(self.step+1, 4); self._show_step()
    def _prev(self):
        self.step = max(self.step-1, 0); self._show_step()

if __name__ == "__main__":
    NexOSWizard().mainloop()
WIZARD_EOF
chmod +x /opt/nexos-setup/wizard.py

# Autostart wizard for nexos user on first login
mkdir -p /home/nexos/.config/autostart
cat > /home/nexos/.config/autostart/nexos-wizard.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=NexOS Setup Wizard
Exec=python3 /opt/nexos-setup/wizard.py
X-KDE-autostart-phase=2
EOF
chown nexos:nexos /home/nexos/.config/autostart/nexos-wizard.desktop

# ── VirtualBox Guest Additions ────────────────────────────────────────────────
apt-get install -yq virtualbox-guest-utils virtualbox-guest-x11 2>/dev/null || \
  apt-get install -yq open-vm-tools-desktop 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════╗"
echo "║     NexOS Setup Complete!            ║"
echo "║     Reboot to start NexOS            ║"
echo "╚══════════════════════════════════════╝"
