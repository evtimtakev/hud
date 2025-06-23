# Android Auto HUD for Raspberry Pi 5

A complete Android Auto Head-Up Display (HUD) solution for Raspberry Pi 5 optimized for 5-inch displays (800x480) with automatic startup and 180° display rotation.

## Features

- **Android Auto Integration**: Connect your Android phone for seamless car integration
- **180° Display Rotation**: Perfect for dashboard mounting
- **Auto-startup**: Automatically launches on boot
- **Touch Screen Support**: Full touch interface support
- **Audio Integration**: Supports audio output through 3.5mm jack or USB audio
- **Easy Installation**: One-command setup script

## Hardware Requirements

- Raspberry Pi 5 (4GB+ recommended)
- MicroSD card (32GB+ recommended)
- Touch screen display (5" optimized, 800x480, DSI connection)
- USB-C cable for Android phone connection
- Power supply for Raspberry Pi 5
- Optional: External speakers or use HDMI audio

## Software Requirements

- Raspberry Pi OS (64-bit, Bullseye or newer)
- Android phone with Android Auto support
- Internet connection for installation

## Quick Installation

1. Flash Raspberry Pi OS to your SD card
2. Clone this repository:
   ```bash
   git clone <repository-url>
   cd hud
   ```
3. Run the installation script:
   ```bash
   chmod +x install.sh
   sudo ./install.sh
   ```
4. Reboot your Raspberry Pi:
   ```bash
   sudo reboot
   ```

## Manual Installation

If you prefer to install manually, follow the steps in the `docs/manual-install.md` file.

## Configuration

### Display Rotation
The display is automatically configured for 180° rotation. To change this:
1. Edit `/boot/config.txt`
2. Modify the `display_rotate` parameter
3. Reboot

### Audio Configuration
- HDMI audio is enabled by default
- For 3.5mm jack audio, run: `sudo raspi-config` and select audio output

## Usage

1. Connect your Android phone via USB
2. Enable Developer Options on your phone
3. Enable USB Debugging
4. The Android Auto interface should automatically appear
5. Follow the on-screen setup instructions

## Troubleshooting

### Common Issues

1. **OpenAuto binary missing** ("openauto/build/bin folder does not exist"): Run `sudo ./scripts/rebuild-openauto.sh`
2. **Architecture errors** ("unsupported architecture i386"): Run `sudo ./scripts/fix-architecture.sh`
3. **Package installation failures**: Check `docs/troubleshooting-qt5.md` or `docs/troubleshooting-architecture.md`
4. **Display not rotating**: Check `/boot/config.txt` for `display_rotate=2` or run `sudo ./scripts/display-config.sh`
5. **Touch not working**: Ensure touch screen drivers are installed
6. **Android Auto not connecting**: Check USB cable and phone settings
7. **No audio**: Verify audio output settings in `raspi-config`

### Quick Diagnostic Scripts

```bash
# Rebuild OpenAuto completely (fixes missing binary issues)
sudo ./scripts/rebuild-openauto.sh

# Fix package architecture issues
sudo ./scripts/fix-architecture.sh

# Fix OpenAuto build issues (IOPromise.hpp missing)
sudo ./scripts/fix-openauto-build.sh

# Fix AASDK linker errors (cannot find -l aasdk)
sudo ./scripts/fix-aasdk-linker.sh

# Fix C++ syntax errors (Promise.hpp syntax errors)
sudo ./scripts/fix-cpp-syntax.sh

# Check package availability
sudo ./scripts/check-packages.sh

# Service management
sudo ./scripts/android-auto-service.sh status
sudo ./scripts/android-auto-service.sh logs

# Display configuration
sudo ./scripts/display-config.sh
```

### Logs

Check system logs:
```bash
sudo journalctl -u android-auto-hud
sudo dmesg | grep -i usb
```

### Documentation

- Architecture Issues: `docs/troubleshooting-architecture.md`
- OpenAuto Build Issues: `docs/troubleshooting-openauto.md`
- Qt5 Package Issues: `docs/troubleshooting-qt5.md`
- Display Configuration: `docs/display-types.md`
- Manual Installation: `docs/manual-install.md`

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- Android Auto community
- Raspberry Pi Foundation
- OpenAuto Pro developers 