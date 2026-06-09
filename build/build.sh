#!/usr/bin/env bash
# =============================================================
#  NexOS ISO Builder
#  Produces a bootable nexos.iso (~3–4 GB)
#  Must run as root on Ubuntu/Debian (or inside Docker)
# =============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
PURPLE='\033[0;35m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WORK="${WORK:-/tmp/nexos-build}"
CHROOT="$WORK/chroot"
ISO_DIR="$WORK/iso"
OUT="${OUT:-$PROJECT_DIR}"
ISO_OUT="$OUT/nexos.iso"

log()   { echo -e "${GREEN}[✓]${NC} $1"; }
info()  { echo -e "${CYAN}[→]${NC} $1"; }
step()  { echo -e "\n${PURPLE}${BOLD}══ $1 ══${NC}\n"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ── Guard ─────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && error "Must run as root: sudo bash build/build.sh"

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
    echo -e "${CYAN}  ISO Builder v1.0${NC}"
    echo -e "${YELLOW}  Output: $ISO_OUT${NC}\n"
}

# ── Host dependencies ─────────────────────────────────────────
install_build_deps() {
    step "Build Dependencies"
    apt-get update -qq
    apt-get install -yq \
        debootstrap \
        squashfs-tools \
        xorriso \
        grub-pc-bin \
        grub-efi-amd64-bin \
        grub-efi-amd64-signed \
        mtools \
        dosfstools \
        xz-utils \
        curl \
        wget \
        python3 \
        python3-pip \
        2>/dev/null
    log "Build deps ready"
}

# ── Clean slate ───────────────────────────────────────────────
cleanup_mounts() {
    for mp in "$CHROOT/dev/pts" "$CHROOT/dev" \
              "$CHROOT/proc" "$CHROOT/sys" "$CHROOT/run"; do
        mountpoint -q "$mp" 2>/dev/null && umount -lf "$mp" || true
    done
}

trap cleanup_mounts EXIT

# ── Bootstrap ─────────────────────────────────────────────────
do_debootstrap() {
    step "Ubuntu Noble Debootstrap"

    if [[ -d "$CHROOT/etc" ]]; then
        info "Chroot already exists, skipping debootstrap"
        return 0
    fi

    mkdir -p "$CHROOT" "$ISO_DIR/casper" "$ISO_DIR/boot/grub" \
             "$ISO_DIR/.disk" "$ISO_DIR/EFI/boot"

    info "Bootstrapping Ubuntu 24.04 noble..."
    debootstrap \
        --arch=amd64 \
        --include=apt-transport-https,ca-certificates,curl,gnupg \
        noble \
        "$CHROOT" \
        http://archive.ubuntu.com/ubuntu/

    log "Bootstrap complete"
}

# ── Bind mounts ───────────────────────────────────────────────
bind_mounts() {
    for mp in dev dev/pts proc sys run; do
        mkdir -p "$CHROOT/$mp"
        mountpoint -q "$CHROOT/$mp" 2>/dev/null && continue
        mount --bind "/$mp" "$CHROOT/$mp"
    done
    log "Virtual filesystems mounted"
}

# ── Copy project files into chroot ────────────────────────────
copy_project_files() {
    step "Copy NexOS Files"

    mkdir -p "$CHROOT/opt/nexos-setup"

    # First-boot wizard
    cp "$PROJECT_DIR/first-boot/wizard.py" "$CHROOT/opt/nexos-setup/wizard.py" 2>/dev/null || \
        info "wizard.py not found, skipping"

    # SDDM theme
    mkdir -p "$CHROOT/tmp/nexos-sddm"
    cp "$PROJECT_DIR/themes/sddm/Main.qml" "$CHROOT/tmp/nexos-sddm/" 2>/dev/null || \
        info "SDDM Main.qml not found, using inline fallback"

    # Chroot setup script
    cp "$SCRIPT_DIR/chroot-setup.sh" "$CHROOT/tmp/chroot-setup.sh"
    chmod +x "$CHROOT/tmp/chroot-setup.sh"

    log "Project files copied"
}

# ── Run setup inside chroot ───────────────────────────────────
run_chroot_setup() {
    step "Chroot Configuration"
    info "This takes 20–50 minutes — installing KDE, gaming tools, theming…"

    # Copy DNS for package downloads
    cp /etc/resolv.conf "$CHROOT/etc/resolv.conf" 2>/dev/null || true

    chroot "$CHROOT" /bin/bash /tmp/chroot-setup.sh

    log "Chroot setup complete"
}

# ── Generate wallpaper ────────────────────────────────────────
generate_wallpaper() {
    step "Wallpaper"

    mkdir -p "$CHROOT/usr/share/wallpapers/NexOS/contents/images"

    chroot "$CHROOT" python3 - << 'PYEOF' 2>/dev/null || true
try:
    from PIL import Image, ImageDraw
except ImportError:
    import subprocess; subprocess.run(["pip3","install","Pillow","-q"], check=False)
    from PIL import Image, ImageDraw

w, h = 1920, 1080
img = Image.new("RGB", (w, h), "#08080f")
d = ImageDraw.Draw(img)
for x in range(0, w, 55): d.line([(x,0),(x,h)], fill="#0c0c1a", width=1)
for y in range(0, h, 55): d.line([(0,y),(w,y)], fill="#0c0c1a", width=1)

ov = Image.new("RGBA", (w, h), (0,0,0,0))
d2 = ImageDraw.Draw(ov)
d2.ellipse([-50,-50,750,750], fill=(0,245,255,9))
d2.ellipse([1200,300,2050,1150], fill=(191,95,255,7))
d2.ellipse([700,500,1450,1250], fill=(0,200,120,5))

base = img.convert("RGBA")
result = Image.alpha_composite(base, ov).convert("RGB")
result.save("/usr/share/wallpapers/NexOS/contents/images/1920x1080.jpg","JPEG",quality=95)
result.save("/usr/share/wallpapers/NexOS/contents/images/3840x2160.jpg","JPEG",quality=95)
print("Wallpaper generated")
PYEOF

    cat > "$CHROOT/usr/share/wallpapers/NexOS/metadata.json" << 'EOF'
{"KPlugin":{"Authors":[{"Name":"NexOS"}],"Id":"NexOS","License":"CC-BY-4.0","Name":"NexOS Default"}}
EOF
    log "Wallpaper done"
}

# ── Generate GRUB background ──────────────────────────────────
generate_grub_bg() {
    python3 - << 'PYEOF' 2>/dev/null || true
try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    import subprocess; subprocess.run(["pip3","install","Pillow","-q"], check=False)
    from PIL import Image, ImageDraw

import os
os.makedirs(f"{os.environ.get('ISO_DIR','/tmp/nexos-build/iso')}/boot/grub", exist_ok=True)

w, h = 1920, 1080
img = Image.new("RGB", (w, h), "#05050c")
d = ImageDraw.Draw(img)

for x in range(0, w, 60): d.line([(x,0),(x,h)], fill="#09091a", width=1)
for y in range(0, h, 60): d.line([(0,y),(w,y)], fill="#09091a", width=1)

ov = Image.new("RGBA", (w, h), (0,0,0,0))
d2 = ImageDraw.Draw(ov)
d2.ellipse([0,0,600,600], fill=(0,245,255,7))
d2.ellipse([1400,500,2100,1200], fill=(191,95,255,6))

base = img.convert("RGBA")
result = Image.alpha_composite(base, ov).convert("RGB")
out = os.environ.get("ISO_DIR", "/tmp/nexos-build/iso")
result.save(f"{out}/boot/grub/nexos-grub.png", "PNG")
print("GRUB background generated")
PYEOF
}

# ── Package list for manifest ─────────────────────────────────
generate_manifest() {
    step "Filesystem Manifest"
    chroot "$CHROOT" dpkg-query -W --showformat='${Package} ${Version}\n' \
        > "$ISO_DIR/casper/filesystem.manifest"
    log "Manifest written"
}

# ── Squashfs ──────────────────────────────────────────────────
make_squashfs() {
    step "SquashFS Filesystem"
    info "Compressing filesystem — this can take 10–20 min…"

    [[ -f "$ISO_DIR/casper/filesystem.squashfs" ]] && \
        rm -f "$ISO_DIR/casper/filesystem.squashfs"

    mksquashfs "$CHROOT" "$ISO_DIR/casper/filesystem.squashfs" \
        -comp xz -Xbcj x86 \
        -e boot \
        -noappend \
        2>/dev/null

    printf '%s' "$(du -sx --block-size=1 "$CHROOT" | cut -f1)" \
        > "$ISO_DIR/casper/filesystem.size"

    log "SquashFS created: $(du -sh "$ISO_DIR/casper/filesystem.squashfs" | cut -f1)"
}

# ── Kernel + initrd ───────────────────────────────────────────
copy_kernel() {
    step "Kernel & Initrd"

    vmlinuz=$(find "$CHROOT/boot" -name "vmlinuz-*" | sort -V | tail -1)
    initrd=$(find  "$CHROOT/boot" -name "initrd.img-*" | sort -V | tail -1)

    [[ -z "$vmlinuz" ]] && error "No kernel found in chroot"
    [[ -z "$initrd"  ]] && error "No initrd found in chroot"

    cp "$vmlinuz" "$ISO_DIR/casper/vmlinuz"
    cp "$initrd"  "$ISO_DIR/casper/initrd"

    log "Kernel: $(basename "$vmlinuz")"
    log "Initrd: $(basename "$initrd")"
}

# ── GRUB bootloader ───────────────────────────────────────────
setup_grub() {
    step "GRUB Bootloader"

    cp "$SCRIPT_DIR/grub.cfg" "$ISO_DIR/boot/grub/grub.cfg"

    # Copy unicode font
    grub_font=$(find /usr/share/grub -name "unicode.pf2" 2>/dev/null | head -1)
    [[ -n "$grub_font" ]] && cp "$grub_font" "$ISO_DIR/boot/grub/unicode.pf2"

    # BIOS core image
    grub-mkstandalone \
        --format=i386-pc \
        --output="$WORK/core.img" \
        --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
        --modules="linux16 linux normal iso9660 biosdisk search" \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=$ISO_DIR/boot/grub/grub.cfg" \
        2>/dev/null

    cat /usr/lib/grub/i386-pc/cdboot.img "$WORK/core.img" > "$WORK/bios.img"
    cp "$WORK/bios.img" "$ISO_DIR/boot/grub/bios.img"

    # EFI image
    grub-mkstandalone \
        --format=x86_64-efi \
        --output="$WORK/bootx64.efi" \
        --install-modules="linux normal iso9660 gfxmenu gfxterm search" \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=$ISO_DIR/boot/grub/grub.cfg" \
        2>/dev/null

    # EFI FAT image
    local efi_img="$ISO_DIR/EFI/efiboot.img"
    dd if=/dev/zero of="$efi_img" bs=1M count=4 2>/dev/null
    mkfs.vfat "$efi_img" 2>/dev/null
    mmd -i "$efi_img" ::/EFI ::/EFI/BOOT
    mcopy -i "$efi_img" "$WORK/bootx64.efi" ::/EFI/BOOT/BOOTx64.EFI

    log "GRUB configured (BIOS + EFI)"
}

# ── Disk label ────────────────────────────────────────────────
write_disk_info() {
    local date
    date=$(date +%Y%m%d)
    echo "NexOS 1.0 - Release amd64 ($date)" > "$ISO_DIR/.disk/info"
    echo "http://nexos.github.io"             > "$ISO_DIR/.disk/release_notes_url"

    # md5 checksums
    (cd "$ISO_DIR" && find . -type f -not -name "md5sum.txt" \
        -exec md5sum {} \; > md5sum.txt 2>/dev/null)
}

# ── Final ISO ─────────────────────────────────────────────────
make_iso() {
    step "Building ISO"
    info "Output: $ISO_OUT"

    xorriso -as mkisofs \
        -iso-level 3 \
        -full-iso9660-filenames \
        -volid "NEXOS_1_0" \
        -appid "NexOS 1.0" \
        -publisher "NexOS Project" \
        -preparer "NexOS ISO Builder" \
        --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
        --protective-msdos-label \
        -partition_offset 16 \
        -eltorito-boot boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --grub2-boot-info \
        -eltorito-alt-boot \
        -e EFI/efiboot.img \
        -no-emul-boot \
        -append_partition 2 0xef "$ISO_DIR/EFI/efiboot.img" \
        -output "$ISO_OUT" \
        "$ISO_DIR" \
        2>&1 | grep -v "^$" || true

    log "ISO created: $ISO_OUT"
    log "Size: $(du -sh "$ISO_OUT" | cut -f1)"
}

# ── Main ──────────────────────────────────────────────────────
main() {
    print_banner

    echo -e "${CYAN}  Build steps:${NC}"
    echo -e "  1. Install host build tools"
    echo -e "  2. debootstrap Ubuntu 24.04 noble"
    echo -e "  3. Install KDE Plasma, gaming tools, theming"
    echo -e "  4. Build squashfs + ISO"
    echo ""
    echo -e "${YELLOW}  Required: ~20 GB free disk space | 60+ min${NC}"
    echo ""
    if [[ "${CI:-}" != "true" ]]; then
        read -rp "$(echo -e "${CYAN}  Proceed? [y/N]: ${NC}")" yn
        [[ "$yn" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
    fi

    export ISO_DIR

    install_build_deps
    do_debootstrap
    bind_mounts
    copy_project_files
    run_chroot_setup
    generate_wallpaper
    cleanup_mounts
    generate_grub_bg
    generate_manifest
    make_squashfs
    copy_kernel
    setup_grub
    write_disk_info
    make_iso

    echo ""
    echo -e "${PURPLE}${BOLD}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  nexos.iso is ready!${NC}"
    echo -e "${PURPLE}${BOLD}═══════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${CYAN}In VirtualBox:${NC}"
    echo -e "  1. New VM → Linux 64-bit, 4+ GB RAM, 50+ GB disk"
    echo -e "  2. Settings → Storage → mount nexos.iso"
    echo -e "  3. Boot → NexOS live session loads"
    echo -e "  4. Run installer from the desktop to install to disk"
    echo ""
}

main "$@"
