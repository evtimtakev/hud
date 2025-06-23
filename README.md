# OpenAuto Community Edition on Raspberry Pi OS

This guide explains how to install and auto-start OpenAuto Community Edition on a Raspberry Pi running Raspberry Pi OS. OpenAuto turns your Pi into an Android Auto head unit emulator.

---

## Prerequisites

- Raspberry Pi 4 or 5 (Pi 5 recommended)
- Raspberry Pi OS (32-bit or 64-bit, latest version)
- Internet connection
- USB sound card (recommended for audio in/out)
- Microphone and speakers (for full Android Auto experience)

---

## 1. Update Your System

```
sudo apt update
sudo apt upgrade -y
```

---

## 2. Install Dependencies

```
sudo apt install -y cmake g++ qtbase5-dev qtdeclarative5-dev \
  qt5-qmake qtbase5-private-dev libqt5svg5-dev \
  libssl-dev libboost-all-dev libusb-1.0-0-dev \
  libcurl4-openssl-dev pulseaudio
```

---

## 3. Download and Build OpenAuto

```
git clone https://github.com/f1xpl/openauto.git
cd openauto
mkdir build && cd build
cmake ..
make -j$(nproc)
```

---

## 4. Run OpenAuto

```
./autoapp
```

You should see the OpenAuto interface. Connect your phone via USB and enable Android Auto.

---

## 5. Auto-Start OpenAuto on Boot

### Option A: Systemd Service (Recommended for Kiosk/Headless Mode)

1. Create a systemd service file:
   ```bash
   sudo nano /etc/systemd/system/openauto.service
   ```
2. Paste the following (replace `pi` with your username if different, and adjust the path if needed):
   ```ini
   [Unit]
   Description=OpenAuto
   After=graphical.target

   [Service]
   User=pi
   Environment=DISPLAY=:0
   WorkingDirectory=/home/pi/openauto/build
   ExecStart=/home/pi/openauto/build/autoapp
   Restart=always

   [Install]
   WantedBy=graphical.target
   ```
3. Enable and start the service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable openauto.service
   sudo systemctl start openauto.service
   ```

### Option B: Desktop Autostart (if using Raspberry Pi OS Desktop)

1. Create a `.desktop` file:
   ```bash
   nano ~/.config/autostart/openauto.desktop
   ```
2. Paste:
   ```ini
   [Desktop Entry]
   Type=Application
   Name=OpenAuto
   Exec=/home/pi/openauto/build/autoapp
   ```

---

## 6. (Optional) Boot Directly to OpenAuto (Kiosk Mode)

You can configure Raspberry Pi OS to boot without the desktop and launch OpenAuto directly for a true automotive experience. If you want these instructions, let me know!

---

## Notes

- For more features, consider [OpenAuto Pro](https://bluewavestudio.io/index.php/bluewave-shop/openauto-pro-detail).
- For troubleshooting and advanced configuration, see the [OpenAuto GitHub](https://github.com/f1xpl/openauto).

---

Enjoy your new Raspberry Pi-powered Android Auto head unit! 