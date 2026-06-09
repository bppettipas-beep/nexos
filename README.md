# NexOS — Gaming-Focused Linux

A custom bootable Linux ISO based on Ubuntu 24.04 LTS.  
Drop it into VirtualBox and go. No Ubuntu install required.

**Dark neon aesthetic · KDE Plasma 6 · Smooth animations · First-boot wizard · Gaming-ready**

---

## Quick Start

1. **Build the ISO** (pick one method below)
2. **In VirtualBox:** New VM → mount `nexos.iso` → boot
3. **Wizard opens** → create your account, pick accent color, choose apps
4. Done

---

## Building the ISO

### Option A — Docker (recommended for Windows)

Requires [Docker Desktop](https://www.docker.com/products/docker-desktop/) with WSL2 backend.

```bash
# From the NexOS folder:
docker build -t nexos-builder .
mkdir output
docker run --privileged -v "%CD%\output:/output" nexos-builder
```

On **Mac/Linux**:
```bash
docker run --privileged -v "$(pwd)/output:/output" nexos-builder
```

`nexos.iso` appears in the `output/` folder when done.  
Build time: ~60–90 min | Space needed: ~20 GB

---

### Option B — WSL2 (Windows Subsystem for Linux)

Open Ubuntu in WSL2:
```bash
cd /mnt/c/Users/YourName/Desktop/NexOS
sudo bash build/build.sh
```
ISO is written to the NexOS folder when done.

---

### Option C — Native Ubuntu/Debian

```bash
sudo bash build/build.sh
```

---

## VirtualBox Setup

After building `nexos.iso`:

| Setting | Value |
|---|---|
| Type | Linux, Ubuntu 64-bit |
| RAM | 4096 MB+ (8192 recommended) |
| Disk | 50 GB dynamically allocated |
| Video Memory | 128 MB |
| 3D Acceleration | Enabled |
| Network | NAT |
| Storage | Mount nexos.iso in optical drive |

Boot the VM → NexOS SDDM login screen → log in as **nexos** (password: **nexos**) → setup wizard launches automatically.

---

## What's in the ISO

| Component | Details |
|---|---|
| Base | Ubuntu 24.04 LTS (noble) |
| Desktop | KDE Plasma 6 |
| Login screen | Custom SDDM — animated glow, clock, neon theme |
| Theme | NexOS dark neon (cyan + purple accents) |
| Animations | Blur, Magic Lamp minimize, Wobbly Windows, Slide |
| Icons | Papirus Dark |
| Cursor | Bibata Modern Classic |
| Fonts | JetBrains Mono system-wide |
| Gaming | Steam, Lutris, Wine, GameMode, MangoHud, Vulkan |
| Performance | Low swappiness, zram, inotify tuning |
| Apps | Firefox, VLC, htop, neofetch |
| Flatpak | Configured (for Discord, Heroic, Bottles) |
| VirtualBox | Guest Additions pre-installed |

---

## First Boot Wizard

The wizard runs automatically when you log in to the live session:

1. **Welcome** — feature overview
2. **Profile** — create your username + password
3. **Appearance** — pick accent color (Cyan, Purple, Pink, Green, Orange, Gold)
4. **Apps** — toggle Steam, Lutris, Discord, OBS, Heroic, Bottles
5. **Installing** — applies everything live, then reboots

The live user (`nexos` / `nexos`) has full sudo access.

---

## File Structure

```
NexOS/
├── build/
│   ├── Dockerfile          ← Docker build environment
│   ├── build.sh            ← Main ISO build script
│   ├── chroot-setup.sh     ← Runs inside chroot (installs everything)
│   └── grub.cfg            ← Boot menu
├── first-boot/
│   └── wizard.py           ← Setup wizard (Python/Tkinter)
├── themes/
│   └── sddm/
│       └── Main.qml        ← Login screen (QML)
└── README.md
```

---

## Customization After Setup

### Change accent color
System Settings → Colors & Themes → Colors → select NexOS and edit

### Install more apps from the live session
```bash
# Heroic Games Launcher (Epic/GOG)
flatpak install flathub com.heroicgameslauncher.hgl

# ProtonUp-Qt (manage Proton/Wine-GE versions)
flatpak install flathub net.davidotek.pupgui2

# Discord
flatpak install flathub com.discordapp.Discord
```

### Boost CPU for gaming
```bash
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### Enable MangoHud for any game
```bash
MANGOHUD=1 %command%   # add to Steam launch options
# or launch directly:
mangohud ./game
```

---

## Troubleshooting

**Black screen on boot in VirtualBox:**  
Settings → Display → increase Video Memory to 128 MB, enable 3D acceleration

**SDDM theme not showing:**  
The nexos theme is configured in `/etc/sddm.conf.d/nexos.conf` — check it's present in the live session

**Wizard didn't launch:**
```bash
sudo python3 /opt/nexos-setup/wizard.py
```

**Steam not working:**
```bash
sudo dpkg --add-architecture i386
sudo apt-get update && sudo apt-get install steam
```

**Docker build fails with permission error:**  
Make sure you're using `--privileged` — squashfs and chroot mounts require it

**Out of disk space during build:**  
Need ~20 GB free. Point `WORK` to a different drive:
```bash
WORK=/mnt/bigdrive/nexos-build sudo bash build/build.sh
```
