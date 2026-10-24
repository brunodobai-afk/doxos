# DOXos — Those Who Dare
> *A minimalist, lightning-fast Debian-based operating system designed for gamers and purists.*

```text
        ██████╗   ██████╗  ██╗  ██╗  ██████╗  ███████╗
        ██╔══██╗ ██╔═══██╗ ╚██╗██╔╝ ██╔═══██╗ ██╔════╝
        ██║  ██║ ██║   ██║  ╚███╔╝  ██║   ██║ ███████╗
        ██║  ██║ ██║   ██║  ██╔██╗  ██║   ██║ ╚════██║
        ██████╔╝ ╚██████╔╝ ██╔╝ ██╗ ╚██████╔╝ ███████║
        ╚═════╝   ╚═════╝  ╚═╝  ╚═╝  ╚═════╝  ╚══════╝

                     .-''''-.     .-''''-.
                   .'        '. .'        '.
                  /            X            \
                 |            / \            |
                  \          /   \          /
                   '.______.'     '.______.'

                   T H O S E   W H O   D A R E
               ─────────────────────────────────
                     [  К   И   Н   О  ]
```

---

## ⚡ What is DOXos?

**DOXos** combines the rock-solid simplicity and unbloated philosophy of **Slackware** with the gaming-ready responsiveness of **PikaOS**, running on the battle-tested foundation of **Debian GNU/Linux**.

- **Aesthetic**: Stark Black & White monochrome palette. High contrast, distraction-free.
- **Desktop**: Tuned XFCE 4.18 desktop environment (idles around ~450MB RAM, boots in seconds).
- **Audio Cue**: Distinctive **3-Beep** tone upon reaching graphical desktop (supports both physical PC speaker buzzer and PipeWire/ALSA sound cards).
- **Fastfetch**: Pre-configured with the official DOXos infinity logo and the **КИНО** (Kino) reference.
- **Gaming & Media Stack**:
  - **Steam** with 32-bit `i386` Vulkan & Mesa drivers pre-configured.
  - **Brave Browser** installed via official upstream repository.
  - **GNOME Software (Debian App Store)** with Flatpak integration.
  - **Calamares GUI Installer** for 1-click installation to SSD/HDD.
  - Low-latency kernel parameters (`vm.max_map_count = 2147483642`, BBR TCP congestion control, `gamemode`).

---

## 🚀 How to Build the ISO

### Method 1: Automated via GitHub Actions (Recommended for Windows)
You don't need a local Linux machine to build the ISO!
1. Initialize a git repository and push this directory to your GitHub account:
   ```bash
   git init
   git add .
   git commit -m "feat: initial DOXos release files"
   git remote add origin https://github.com/<your-username>/doxos.git
   git branch -M main
   git push -u origin main
   ```
2. Go to the **Actions** tab in your GitHub repository.
3. The build pipeline will automatically start, assemble the Debian rootfs, compress the image, and output **`DOXos-1.0-amd64.iso`** as a downloadable artifact.

---

### Method 2: Local Build in WSL2 (Windows Subsystem for Linux)
If you have WSL2 installed with Ubuntu or Debian:
1. Open your WSL2 terminal as root:
   ```bash
   cd /mnt/c/Users/bruno/.gemini/antigravity/scratch/doxos
   sudo bash build.sh
   ```
2. The script will produce `DOXos-1.0-amd64.iso` in the project root directory.

---

## 🧪 Testing the ISO

### In VirtualBox / QEMU
To test run DOXos with 4GB RAM and 4 CPU cores:
```bash
qemu-system-x86_64 -enable-kvm -m 4G -smp 4 \
    -cdrom DOXos-1.0-amd64.iso \
    -boot d -vga virtio -audiodev id=snd0,driver=pa -device AC97,audiodev=snd0
```

### On Real Hardware (Bare Metal)
Write the `.iso` file to a USB drive using:
- **Ventoy** (simply drag-and-drop the `.iso` onto the USB)
- **Rufus** (select DD image or ISO image mode)

---

## 🔑 Default Credentials (Live Session)

| Account | Username | Password | Privileges |
| :--- | :--- | :--- | :--- |
| **Live User** | `dox` | `dox` | Passwordless `sudo` |
| **Root** | `root` | `root` | Full Administrator |
