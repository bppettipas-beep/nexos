#!/usr/bin/env python3
"""NexOS First Boot Setup Wizard"""

import tkinter as tk
from tkinter import ttk
import subprocess
import threading
import os
import sys
import time

# ── Palette ──────────────────────────────────────────────
BG      = "#08080f"
BG2     = "#0d0d1a"
BG3     = "#121228"
ACCENT  = "#00f5ff"
ACCENT2 = "#bf5fff"
RED     = "#ff2d78"
GREEN   = "#00c875"
TEXT    = "#d8d8f0"
DIM     = "#686890"
WHITE   = "#ffffff"

ACCENT_CHOICES = {
    "Cyan":   "#00f5ff",
    "Purple": "#bf5fff",
    "Pink":   "#ff2d78",
    "Green":  "#00c875",
    "Orange": "#ff8c00",
    "Gold":   "#ffd700",
}

class NexWizard:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("NexOS Setup")
        self.root.geometry("920x640")
        self.root.resizable(False, False)
        self.root.configure(bg=BG)
        self.root.overrideredirect(True)

        # Center on screen
        self.root.update_idletasks()
        sw = self.root.winfo_screenwidth()
        sh = self.root.winfo_screenheight()
        self.root.geometry(f"920x640+{(sw-920)//2}+{(sh-640)//2}")

        self.step = 0
        self.data = {
            "username": "",
            "password": "",
            "display_name": "",
            "accent": "Cyan",
            "install_steam":   True,
            "install_lutris":  True,
            "install_discord": False,
            "install_obs":     False,
            "install_heroic":  False,
            "install_bottles": False,
        }
        self._drag = {"x": 0, "y": 0}

        self._build()
        self.root.attributes("-alpha", 0.0)
        self._fade(0.0)

    # ── Animation ─────────────────────────────────────────

    def _fade(self, a=0.0):
        a = min(a + 0.06, 1.0)
        self.root.attributes("-alpha", a)
        if a < 1.0:
            self.root.after(16, lambda: self._fade(a))

    # ── Layout ────────────────────────────────────────────

    def _build(self):
        # Title bar
        bar = tk.Frame(self.root, bg="#030308", height=38)
        bar.pack(fill="x")
        bar.pack_propagate(False)
        bar.bind("<ButtonPress-1>",   self._drag_start)
        bar.bind("<B1-Motion>",       self._drag_move)

        tk.Label(bar, text="  NEXOS  ·  FIRST BOOT SETUP",
                 bg="#030308", fg=ACCENT,
                 font=("JetBrains Mono", 10, "bold")).pack(side="left", padx=16)

        tk.Button(bar, text="✕", bg="#030308", fg=DIM,
                  font=("JetBrains Mono", 12), relief="flat", bd=0,
                  cursor="hand2", activebackground="#030308", activeforeground=RED,
                  command=self.root.quit).pack(side="right", padx=14)

        # Body: sidebar + content
        body = tk.Frame(self.root, bg=BG)
        body.pack(fill="both", expand=True)

        # Sidebar
        self.sidebar = tk.Frame(body, bg="#06060e", width=210)
        self.sidebar.pack(side="left", fill="y")
        self.sidebar.pack_propagate(False)

        lf = tk.Frame(self.sidebar, bg="#06060e", pady=28)
        lf.pack(fill="x")
        tk.Label(lf, text="NEX", bg="#06060e", fg=ACCENT,
                 font=("JetBrains Mono", 26, "bold")).pack()
        tk.Frame(lf, bg=ACCENT, height=2, width=70).pack(pady=2)
        tk.Label(lf, text="OS", bg="#06060e", fg=ACCENT2,
                 font=("JetBrains Mono", 13)).pack()

        self._steps_ui = []
        for i, (num, label) in enumerate([
            ("01", "Welcome"),
            ("02", "Profile"),
            ("03", "Appearance"),
            ("04", "Apps"),
            ("05", "Installing"),
        ]):
            row = tk.Frame(self.sidebar, bg="#06060e", pady=9, padx=18)
            row.pack(fill="x")
            n = tk.Label(row, text=num, bg="#06060e", fg=DIM,
                         font=("JetBrains Mono", 8), width=3)
            n.pack(side="left")
            l = tk.Label(row, text=label.upper(), bg="#06060e", fg=DIM,
                         font=("JetBrains Mono", 9))
            l.pack(side="left", padx=6)
            self._steps_ui.append((row, n, l))

        tk.Frame(body, bg="#16162a", width=1).pack(side="left", fill="y")

        # Content area
        self.content = tk.Frame(body, bg=BG)
        self.content.pack(side="left", fill="both", expand=True)

        # Bottom progress bar
        self.prog_var = tk.DoubleVar(value=0)
        ttk.Style().configure("N.Horizontal.TProgressbar",
                              troughcolor=BG3, background=ACCENT,
                              borderwidth=0, thickness=3)
        ttk.Progressbar(self.root, variable=self.prog_var,
                        maximum=100,
                        style="N.Horizontal.TProgressbar").pack(side="bottom", fill="x")

        self._show(0)

    def _drag_start(self, e):
        self._drag["x"] = e.x
        self._drag["y"] = e.y

    def _drag_move(self, e):
        dx, dy = e.x - self._drag["x"], e.y - self._drag["y"]
        self.root.geometry(f"+{self.root.winfo_x()+dx}+{self.root.winfo_y()+dy}")

    # ── Step routing ──────────────────────────────────────

    def _show(self, n):
        self.step = n
        for w in self.content.winfo_children():
            w.destroy()
        self.prog_var.set(n * 25)
        self._update_sidebar(n)
        [self._welcome, self._profile, self._appearance,
         self._apps, self._installing][n]()

    def _update_sidebar(self, active):
        for i, (row, num, lbl) in enumerate(self._steps_ui):
            if i < active:
                row.config(bg="#06060e"); num.config(fg=GREEN, bg="#06060e"); lbl.config(fg=GREEN, bg="#06060e")
            elif i == active:
                row.config(bg="#0e0e20"); num.config(fg=ACCENT, bg="#0e0e20"); lbl.config(fg=WHITE, bg="#0e0e20")
            else:
                row.config(bg="#06060e"); num.config(fg=DIM, bg="#06060e"); lbl.config(fg=DIM, bg="#06060e")

    # ── Shared widgets ────────────────────────────────────

    def _header(self, title, sub=""):
        f = tk.Frame(self.content, bg=BG, pady=28, padx=36)
        f.pack(fill="x")
        tk.Label(f, text=title, bg=BG, fg=WHITE,
                 font=("JetBrains Mono", 20, "bold")).pack(anchor="w")
        if sub:
            tk.Label(f, text=sub, bg=BG, fg=DIM,
                     font=("JetBrains Mono", 10)).pack(anchor="w", pady=(3, 0))
        tk.Frame(self.content, bg="#16162a", height=1).pack(fill="x", padx=36)

    def _nav(self, back=None, nxt=None, nxt_label="NEXT →"):
        f = tk.Frame(self.content, bg=BG, pady=20, padx=36)
        f.pack(side="bottom", fill="x")
        if back:
            self._btn(f, "← BACK", back, sec=True).pack(side="left")
        if nxt:
            self._btn(f, nxt_label, nxt).pack(side="right")

    def _btn(self, parent, text, cmd, sec=False):
        bg     = BG3 if sec else ACCENT
        fg     = TEXT if sec else "#000000"
        hover  = "#1c1c3a" if sec else "#00d8ee"
        b = tk.Label(parent, text=text, bg=bg, fg=fg,
                     font=("JetBrains Mono", 10, "bold"),
                     cursor="hand2", padx=18, pady=10)
        b.bind("<Enter>",    lambda e: b.config(bg=hover))
        b.bind("<Leave>",    lambda e: b.config(bg=bg))
        b.bind("<Button-1>", lambda e: cmd())
        return b

    def _entry(self, parent, label, var, show=None):
        wrap = tk.Frame(parent, bg=BG2, padx=14, pady=10)
        wrap.pack(fill="x", pady=4)
        tk.Label(wrap, text=label.upper(), bg=BG2, fg=ACCENT,
                 font=("JetBrains Mono", 8), pady=(0,)).pack(anchor="w")
        border = tk.Frame(wrap, bg=BG3)
        border.pack(fill="x", pady=(6, 0))
        kw = dict(textvariable=var, background=BG3, foreground=WHITE,
                  insertbackground=ACCENT,
                  font=("JetBrains Mono", 12), relief="flat", bd=0)
        if show:
            kw["show"] = show
        e = tk.Entry(border, **kw)
        e.pack(fill="x", padx=10, pady=8)
        e.bind("<FocusIn>",  lambda ev: border.config(bg=ACCENT))
        e.bind("<FocusOut>", lambda ev: border.config(bg=BG3))
        return e

    def _toast(self, msg):
        win = tk.Toplevel(self.root)
        win.overrideredirect(True)
        win.configure(bg=BG)
        win.geometry(f"380x140+{self.root.winfo_x()+270}+{self.root.winfo_y()+250}")
        win.grab_set()
        tk.Frame(win, bg=RED, height=3).pack(fill="x")
        tk.Label(win, text=msg, bg=BG, fg=WHITE,
                 font=("JetBrains Mono", 11), wraplength=320,
                 pady=20).pack()
        self._btn(win, "OK", win.destroy).pack(pady=(0, 14))

    # ── Steps ─────────────────────────────────────────────

    def _welcome(self):
        self._header("Welcome to NexOS", "Your gaming-focused Linux experience")
        body = tk.Frame(self.content, bg=BG, padx=36, pady=10)
        body.pack(fill="both", expand=True)

        for icon, title, desc in [
            ("⚡", "Optimized Performance",
             "Tuned kernel, zram, and CPU governors — smooth at all times"),
            ("🎮", "Gaming Ready",
             "Steam, Lutris, Wine, GameMode, and MangoHud pre-configured"),
            ("✨", "Beautiful UI",
             "Custom KDE Plasma with blur, animations, and neon aesthetics"),
            ("🔧", "Fully Customizable",
             "Change colors, layouts, and behavior in a few clicks"),
        ]:
            card = tk.Frame(body, bg=BG2, padx=14, pady=12)
            card.pack(fill="x", pady=4)
            tk.Label(card, text=icon, bg=BG2, font=("", 18)).pack(side="left", padx=(0, 12))
            tf = tk.Frame(card, bg=BG2)
            tf.pack(side="left", fill="x", expand=True)
            tk.Label(tf, text=title, bg=BG2, fg=WHITE,
                     font=("JetBrains Mono", 11, "bold")).pack(anchor="w")
            tk.Label(tf, text=desc, bg=BG2, fg=DIM,
                     font=("JetBrains Mono", 9), wraplength=470).pack(anchor="w")

        self._nav(nxt=lambda: self._show(1), nxt_label="LET'S GO →")

    def _profile(self):
        self._header("Create Your Profile", "Set up your NexOS account")
        body = tk.Frame(self.content, bg=BG, padx=36, pady=14)
        body.pack(fill="both", expand=True)

        self._uv = tk.StringVar(value=self.data["username"])
        self._dv = tk.StringVar(value=self.data["display_name"])
        self._pv = tk.StringVar()
        self._cv = tk.StringVar()

        self._entry(body, "Username",         self._uv)
        self._entry(body, "Display Name",     self._dv)
        self._entry(body, "Password",         self._pv, show="•")
        self._entry(body, "Confirm Password", self._cv, show="•")

        tk.Label(body, text="⚠  Lowercase letters, numbers, underscores only",
                 bg=BG, fg=DIM, font=("JetBrains Mono", 8)).pack(anchor="w", pady=(6, 0))

        def go():
            u = self._uv.get().strip().lower()
            p = self._pv.get()
            c = self._cv.get()
            if not u:
                return self._toast("Please enter a username")
            if len(u) < 3 or not u.replace("_", "").isalnum():
                return self._toast("Username: 3+ chars, letters/numbers/underscores only")
            if len(p) < 6:
                return self._toast("Password must be at least 6 characters")
            if p != c:
                return self._toast("Passwords do not match")
            self.data.update(username=u, password=p,
                             display_name=self._dv.get().strip() or u)
            self._show(2)

        self._nav(back=lambda: self._show(0), nxt=go)

    def _appearance(self):
        self._header("Choose Your Style", "Pick an accent color and layout")
        body = tk.Frame(self.content, bg=BG, padx=36, pady=14)
        body.pack(fill="both", expand=True)

        tk.Label(body, text="ACCENT COLOR", bg=BG, fg=DIM,
                 font=("JetBrains Mono", 8)).pack(anchor="w")

        self._accent_v = tk.StringVar(value=self.data["accent"])
        row = tk.Frame(body, bg=BG, pady=10)
        row.pack(fill="x")

        preview_lbl = tk.Label(body, bg=BG, fg=ACCENT_CHOICES[self.data["accent"]],
                               font=("JetBrains Mono", 12),
                               text=f"● {self.data['accent']}")
        preview_lbl.pack(anchor="w", pady=(0, 14))

        for name, color in ACCENT_CHOICES.items():
            def pick(n=name, c=color):
                self._accent_v.set(n)
                self.data["accent"] = n
                preview_lbl.config(fg=c, text=f"● {n}")
            btn = tk.Frame(row, bg=color, width=44, height=44, cursor="hand2")
            btn.pack(side="left", padx=5)
            btn.bind("<Button-1>", lambda e, fn=pick: fn())
            tk.Label(row, text=name, bg=BG, fg=DIM,
                     font=("JetBrains Mono", 7)).pack(side="left", padx=(0, 8))

        # Layout
        tk.Frame(body, bg="#16162a", height=1).pack(fill="x", pady=10)
        tk.Label(body, text="TASKBAR STYLE", bg=BG, fg=DIM,
                 font=("JetBrains Mono", 8)).pack(anchor="w")

        self._layout_v = tk.StringVar(value="bottom")
        lrow = tk.Frame(body, bg=BG, pady=8)
        lrow.pack(fill="x")

        for label, val in [("Bottom Bar", "bottom"), ("Top Bar", "top"),
                            ("Floating Dock", "float")]:
            tk.Radiobutton(lrow, text=label, variable=self._layout_v, value=val,
                           bg=BG2, fg=TEXT, selectcolor=BG3,
                           activebackground=BG2, activeforeground=WHITE,
                           font=("JetBrains Mono", 10),
                           padx=14, pady=8).pack(side="left", padx=4)

        self._nav(back=lambda: self._show(1), nxt=lambda: self._show(3))

    def _apps(self):
        self._header("Choose Your Apps", "Select additional software to install")
        body = tk.Frame(self.content, bg=BG, padx=36, pady=14)
        body.pack(fill="both", expand=True)

        self._app_vars = {}
        for key, name, desc, default in [
            ("install_steam",   "Steam",                "Gaming platform with thousands of titles", True),
            ("install_lutris",  "Lutris",               "Open gaming platform for GOG, Epic, and more", True),
            ("install_discord", "Discord",              "Voice, video, and text chat for gamers", False),
            ("install_obs",     "OBS Studio",           "Free streaming and recording software", False),
            ("install_heroic",  "Heroic Games Launcher","GOG and Epic launcher for Linux", False),
            ("install_bottles", "Bottles",              "Run Windows apps on Linux easily", False),
        ]:
            v = tk.BooleanVar(value=self.data.get(key, default))
            self._app_vars[key] = v
            card = tk.Frame(body, bg=BG2, padx=14, pady=9)
            card.pack(fill="x", pady=3)
            cb = tk.Checkbutton(card, variable=v, bg=BG2,
                                activebackground=BG2, selectcolor=BG3,
                                fg=ACCENT, activeforeground=ACCENT)
            cb.pack(side="left")
            tf = tk.Frame(card, bg=BG2)
            tf.pack(side="left", padx=(8, 0))
            tk.Label(tf, text=name, bg=BG2, fg=WHITE,
                     font=("JetBrains Mono", 11, "bold")).pack(anchor="w")
            tk.Label(tf, text=desc, bg=BG2, fg=DIM,
                     font=("JetBrains Mono", 9)).pack(anchor="w")

        def go():
            for k, v in self._app_vars.items():
                self.data[k] = v.get()
            self._show(4)

        self._nav(back=lambda: self._show(2), nxt=go, nxt_label="INSTALL →")

    def _installing(self):
        self._header("Setting Up NexOS", "Please wait while we configure your system…")
        body = tk.Frame(self.content, bg=BG, padx=36, pady=16)
        body.pack(fill="both", expand=True)

        self._status  = tk.StringVar(value="Initializing…")
        self._substatus = tk.StringVar(value="")

        tk.Label(body, textvariable=self._status,  bg=BG, fg=WHITE,
                 font=("JetBrains Mono", 13)).pack(anchor="w")
        tk.Label(body, textvariable=self._substatus, bg=BG, fg=DIM,
                 font=("JetBrains Mono", 9)).pack(anchor="w", pady=(2, 0))

        self._step_prog = tk.DoubleVar(value=0)
        ttk.Style().configure("S.Horizontal.TProgressbar",
                              troughcolor=BG3, background=ACCENT,
                              borderwidth=0, thickness=5)
        ttk.Progressbar(body, variable=self._step_prog, maximum=100,
                        style="S.Horizontal.TProgressbar",
                        length=560).pack(fill="x", pady=16)

        log_frame = tk.Frame(body, bg=BG3)
        log_frame.pack(fill="both", expand=True)
        self._log = tk.Text(log_frame, bg=BG3, fg="#606080",
                            font=("JetBrains Mono", 9), relief="flat",
                            bd=0, wrap="word", state="disabled")
        sb = tk.Scrollbar(log_frame, command=self._log.yview, bg=BG3)
        self._log.configure(yscrollcommand=sb.set)
        sb.pack(side="right", fill="y")
        self._log.pack(fill="both", expand=True, padx=10, pady=10)

        threading.Thread(target=self._run_setup, daemon=True).start()

    # ── Installation logic ────────────────────────────────

    def _log_line(self, msg):
        def _do():
            self._log.configure(state="normal")
            self._log.insert("end", f"  {msg}\n")
            self._log.see("end")
            self._log.configure(state="disabled")
        self.root.after(0, _do)

    def _set_status(self, msg, sub=""):
        self.root.after(0, lambda: self._status.set(msg))
        self.root.after(0, lambda: self._substatus.set(sub))

    def _set_prog(self, n):
        self.root.after(0, lambda: self._step_prog.set(n))

    def _run(self, cmd):
        try:
            r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=300)
            for line in (r.stdout + r.stderr).strip().split("\n")[-4:]:
                if line.strip():
                    self._log_line(line)
            return r.returncode == 0
        except Exception as e:
            self._log_line(f"Error: {e}")
            return False

    def _run_setup(self):
        d = self.data
        user = d["username"]
        pw   = d["password"]
        name = d.get("display_name", user)
        acc  = ACCENT_CHOICES.get(d.get("accent", "Cyan"), ACCENT)

        # 1 — Create user
        self._set_status("Creating user account…", f"/{user}")
        self._log_line(f"Creating user: {user}")
        self._run(f"useradd -m -s /bin/bash -G sudo,audio,video,plugdev,input {user} 2>/dev/null || true")
        self._run(f'echo "{user}:{pw}" | chpasswd')
        self._run(f"chfn -f '{name}' {user} 2>/dev/null || true")
        self._run(f"usermod -aG gamemode {user} 2>/dev/null || true")
        self._log_line("✓ User created")
        self._set_prog(14)

        # 2 — Apply theme
        self._set_status("Applying NexOS theme…", "KDE color scheme + fonts")
        for group, key, val in [
            ("General",  "ColorScheme",       "NexOS"),
            ("Icons",    "Theme",             "Papirus-Dark"),
            ("General",  "font",              f"JetBrains Mono,10,-1,5,50,0,0,0,0,0"),
            ("General",  "fixed",             f"JetBrains Mono,10,-1,5,50,0,0,0,0,0"),
            ("General",  "menuFont",          f"JetBrains Mono,10,-1,5,50,0,0,0,0,0"),
            ("General",  "toolBarFont",       f"JetBrains Mono,9,-1,5,50,0,0,0,0,0"),
            ("KDE",      "AnimationDurationFactor", "0.5"),
        ]:
            self._run(f"sudo -u {user} kwriteconfig5 --file kdeglobals "
                      f"--group {group} --key {key} '{val}' 2>/dev/null")

        self._run(f"sudo -u {user} kwriteconfig5 --file kcminputrc "
                  f"--group Mouse --key cursorTheme Bibata-Modern-Classic 2>/dev/null")
        self._log_line("✓ Theme applied")
        self._set_prog(28)

        # 3 — KWin effects
        self._set_status("Enabling animations…", "Blur, magic lamp, wobbly windows")
        for key, val in [
            ("blurEnabled",               "true"),
            ("kwin4_effect_magiclamEnabled", "true"),
            ("slideEnabled",              "true"),
            ("wobblywindowsEnabled",      "true"),
        ]:
            self._run(f"sudo -u {user} kwriteconfig5 --file kwinrc "
                      f"--group Plugins --key {key} {val} 2>/dev/null")
        for key, val in [
            ("Backend",          "OpenGL"),
            ("GLCore",           "true"),
            ("OpenGLIsUnsafe",   "false"),
        ]:
            self._run(f"sudo -u {user} kwriteconfig5 --file kwinrc "
                      f"--group Compositing --key {key} {val} 2>/dev/null")
        self._log_line("✓ Animations enabled")
        self._set_prog(42)

        # 4 — Optional apps
        self._set_status("Installing selected apps…", "This may take a few minutes")
        if d.get("install_steam"):
            self._log_line("Installing Steam…")
            self._run("apt-get install -yq steam-installer 2>/dev/null || apt-get install -yq steam 2>/dev/null")
        if d.get("install_discord"):
            self._log_line("Installing Discord…")
            self._run("flatpak install -y --noninteractive flathub com.discordapp.Discord 2>/dev/null")
        if d.get("install_obs"):
            self._log_line("Installing OBS Studio…")
            self._run("apt-get install -yq obs-studio 2>/dev/null")
        if d.get("install_heroic"):
            self._log_line("Installing Heroic Games Launcher…")
            self._run("flatpak install -y --noninteractive flathub com.heroicgameslauncher.hgl 2>/dev/null")
        if d.get("install_bottles"):
            self._log_line("Installing Bottles…")
            self._run("flatpak install -y --noninteractive flathub com.usebottles.bottles 2>/dev/null")
        self._log_line("✓ Apps installed")
        self._set_prog(62)

        # 5 — SDDM default user
        self._set_status("Configuring login screen…", "Setting default username")
        self._run(f"sed -i 's/^DefaultUser=.*/DefaultUser={user}/' /etc/sddm.conf.d/nexos.conf 2>/dev/null || true")
        self._log_line("✓ Login screen configured")
        self._set_prog(74)

        # 6 — Wallpaper
        self._set_status("Setting wallpaper…")
        self._run(f"sudo -u {user} plasma-apply-wallpaperimage "
                  "/usr/share/wallpapers/NexOS/contents/images/1920x1080.jpg 2>/dev/null || true")
        self._log_line("✓ Wallpaper set")
        self._set_prog(86)

        # 7 — Mark done, remove wizard from autostart
        self._set_status("Finalizing…")
        done_flag = "/opt/nexos-setup/.done"
        self._run(f"touch {done_flag}")
        self._run(f"rm -f /root/.config/autostart/nexos-setup.desktop 2>/dev/null")
        self._run("systemctl disable nexos-setup.service 2>/dev/null || true")
        self._log_line("✓ Setup wizard unregistered")
        self._set_prog(100)

        # Done
        self._set_status("Setup Complete!", f"Welcome to NexOS, {name}!")
        self._log_line("=" * 42)
        self._log_line(f"NexOS is ready!")
        self._log_line(f"Username:  {user}")
        self._log_line("Reboot to start using NexOS.")
        self._log_line("=" * 42)

        self.root.after(400, self._done_buttons)

    def _done_buttons(self):
        f = tk.Frame(self.content, bg=BG, pady=16, padx=36)
        f.pack(side="bottom", fill="x")
        self._btn(f, "EXIT WIZARD", self.root.quit, sec=True).pack(side="right", padx=(8, 0))
        self._btn(f, "REBOOT INTO NEXOS ↗",
                  lambda: (subprocess.Popen(["reboot"]), self.root.quit())).pack(side="right")

    def run(self):
        self.root.mainloop()


if __name__ == "__main__":
    if os.geteuid() != 0:
        # Re-launch with sudo + DISPLAY preserved
        os.execvp("sudo", ["sudo", "-E", sys.executable] + sys.argv)
    NexWizard().run()
