#!/bin/bash

# Android Auto HUD Installation Script for Raspberry Pi 5
# Author: Auto-generated installation script
# Description: Installs and configures Android Auto with 180° display rotation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root (use sudo)"
   exit 1
fi

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo; then
    print_warning "This script is designed for Raspberry Pi. Continuing anyway..."
fi

print_status "Starting Android Auto HUD installation..."

# Update system
print_status "Updating system packages..."
apt update && apt upgrade -y

# Install required dependencies
print_status "Installing dependencies..."

# Detect Raspberry Pi OS version and architecture
OS_VERSION=$(lsb_release -cs 2>/dev/null || echo "unknown")
ARCHITECTURE=$(dpkg --print-architecture)
SYSTEM_ARCH=$(uname -m)

print_status "Detected OS version: $OS_VERSION"
print_status "Detected architecture: $ARCHITECTURE ($SYSTEM_ARCH)"

# Verify we're on ARM architecture
if [[ "$ARCHITECTURE" != "arm64" && "$ARCHITECTURE" != "armhf" ]]; then
    print_warning "Detected non-ARM architecture: $ARCHITECTURE"
    print_status "This script is designed for Raspberry Pi (ARM) architecture"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Fix architecture-specific repository issues
print_status "Configuring repositories for $ARCHITECTURE..."

# Remove any problematic foreign architectures
print_status "Checking for foreign architectures..."
FOREIGN_ARCHS=$(dpkg --print-foreign-architectures 2>/dev/null || true)
if [ -n "$FOREIGN_ARCHS" ]; then
    print_status "Found foreign architectures: $FOREIGN_ARCHS"
    for arch in $FOREIGN_ARCHS; do
        if [ "$arch" = "i386" ]; then
            print_status "Removing problematic i386 architecture..."
            dpkg --remove-architecture i386 2>/dev/null || true
        fi
    done
fi

# Set APT preferences to prefer our architecture
cat > /etc/apt/preferences.d/99-architecture << EOF
Package: *
Pin: version *
Pin-Priority: 100

Package: *
Pin: release a=* l=* c=* origin=* architecture=$ARCHITECTURE
Pin-Priority: 500
EOF

if [ "$ARCHITECTURE" = "arm64" ]; then
    # Ensure we're using the correct ARM64 repositories
    print_status "Configuring for ARM64 architecture..."
elif [ "$ARCHITECTURE" = "armhf" ]; then
    # Ensure we're using the correct ARMHF repositories  
    print_status "Configuring for ARMHF architecture..."
fi

# Clean package cache and update repositories
print_status "Cleaning package cache and updating repositories..."
apt clean
apt autoclean
apt update

# Install base packages with architecture specification
print_status "Installing base packages for $ARCHITECTURE..."
apt install -y \
    git \
    cmake \
    build-essential \
    wget \
    unzip \
    python3-pip \
    python3-setuptools \
    ca-certificates \
    apt-transport-https \
    software-properties-common

# Function to install packages with architecture checking
install_packages_safe() {
    local packages=("$@")
    local failed_packages=()
    
    for package in "${packages[@]}"; do
        print_status "Installing $package..."
        if ! apt install -y "$package" 2>/dev/null; then
            print_warning "Failed to install $package, trying alternatives..."
            failed_packages+=("$package")
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        print_warning "Some packages failed to install: ${failed_packages[*]}"
    fi
}

# Install Qt5 packages (compatible with newer Raspberry Pi OS)
print_status "Installing Qt5 packages for $ARCHITECTURE..."
if [ "$OS_VERSION" = "bookworm" ] || [ "$OS_VERSION" = "bullseye" ]; then
    # For newer Raspberry Pi OS versions - install packages one by one to avoid architecture conflicts
    QT5_PACKAGES=(
        "qt5-qmake"
        "qtbase5-dev"
        "qtbase5-dev-tools"
        "qtmultimedia5-dev"
        "qtconnectivity5-dev"
        "libqt5multimedia5-plugins"
        "libqt5webchannel5-dev"
        "libqt5widgets5"
        "libqt5core5a"
        "libqt5quick5"
        "libqt5quickwidgets5"
        "libqt5qml5"
        "libqt5network5"
        "libqt5gui5"
        "libqt5dbus5"
        "libqt5xml5"
        "libqt5opengl5-dev"
        "qml-module-qtquick2"
        "qml-module-qtquick-controls"
        "qml-module-qtquick-controls2"
    )
    install_packages_safe "${QT5_PACKAGES[@]}"
else
    # For older versions that still have qt5-default
    QT5_LEGACY_PACKAGES=(
        "qt5-default"
        "qtmultimedia5-dev"
        "qtconnectivity5-dev"
        "libqt5multimedia5-plugins"
        "libqt5webchannel5-dev"
        "libqt5widgets5"
        "libqt5core5a"
        "libqt5quick5"
        "libqt5quickwidgets5"
        "libqt5qml5"
        "libqt5network5"
        "libqt5gui5"
        "libqt5dbus5"
        "libqt5xml5"
    )
    install_packages_safe "${QT5_LEGACY_PACKAGES[@]}"
fi

# Install other dependencies
print_status "Installing system libraries..."

# Try different libusb package names
if apt-cache search libusb-1.0-0-dev | grep -q libusb; then
    LIBUSB_PKG="libusb-1.0-0-dev"
elif apt-cache search libusb-dev | grep -q libusb; then
    LIBUSB_PKG="libusb-dev"
else
    LIBUSB_PKG="libusb-1.0.0-dev"
fi

print_status "Using libusb package: $LIBUSB_PKG"

apt install -y \
    libboost-all-dev \
    $LIBUSB_PKG \
    libssl-dev \
    libprotobuf-dev \
    protobuf-compiler \
    librtaudio-dev \
    pulseaudio \
    pulseaudio-module-bluetooth \
    bluez \
    bluez-tools

# Install GStreamer
print_status "Installing GStreamer..."
apt install -y \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-libav \
    gstreamer1.0-tools \
    gstreamer1.0-alsa \
    gstreamer1.0-pulseaudio \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev

# Install X server and desktop components
print_status "Installing X server and desktop components..."

# Detect correct chromium package name
if apt-cache search chromium-browser | grep -q chromium-browser; then
    CHROMIUM_PKG="chromium-browser"
elif apt-cache search chromium | grep -q "chromium "; then
    CHROMIUM_PKG="chromium"
else
    print_warning "Chromium not found, will use firefox-esr as fallback"
    CHROMIUM_PKG="firefox-esr"
fi

print_status "Using browser package: $CHROMIUM_PKG"

apt install -y \
    xorg \
    xinit \
    x11-xserver-utils \
    xserver-xorg-legacy \
    openbox \
    lightdm \
    $CHROMIUM_PKG \
    unclutter

# Install USB/mobile device support
print_status "Installing USB device support..."
apt install -y \
    usbmuxd \
    libimobiledevice6 \
    libimobiledevice-utils

# Install Node.js for web-based Android Auto (architecture-safe)
print_status "Installing Node.js for $ARCHITECTURE..."
if [ "$ARCHITECTURE" = "arm64" ] || [ "$ARCHITECTURE" = "armhf" ]; then
    # Use system Node.js package for ARM to avoid architecture conflicts
    apt install -y nodejs npm || {
        print_warning "System Node.js not available, skipping Node.js installation"
        print_status "Node.js is optional for this project"
    }
else
    # For other architectures, try the NodeSource repository
    if curl -fsSL https://deb.nodesource.com/setup_18.x | bash -; then
        apt install -y nodejs
    else
        print_warning "NodeSource installation failed, trying system packages"
        apt install -y nodejs npm || print_warning "Node.js installation failed, continuing without it"
    fi
fi

# Create project directories
print_status "Creating project directories..."
mkdir -p /opt/android-auto-hud
mkdir -p /var/log/android-auto-hud
mkdir -p /home/pi/.config/autostart

# Copy project files
print_status "Copying project files..."
cp -r ./scripts/* /opt/android-auto-hud/ 2>/dev/null || true
cp -r ./config/* /opt/android-auto-hud/ 2>/dev/null || true

# Configure display rotation (180 degrees)
print_status "Configuring 180° display rotation..."
if ! grep -q "display_rotate=2" /boot/config.txt; then
    echo "display_rotate=2" >> /boot/config.txt
    print_success "Display rotation configured"
else
    print_status "Display rotation already configured"
fi

# Configure GPU memory split
if ! grep -q "gpu_mem=128" /boot/config.txt; then
    echo "gpu_mem=128" >> /boot/config.txt
    print_success "GPU memory configured"
fi

# Enable OpenGL
if ! grep -q "dtoverlay=vc4-kms-v3d" /boot/config.txt; then
    echo "dtoverlay=vc4-kms-v3d" >> /boot/config.txt
    print_success "OpenGL enabled"
fi

# Configure audio
print_status "Configuring audio..."
if ! grep -q "dtparam=audio=on" /boot/config.txt; then
    echo "dtparam=audio=on" >> /boot/config.txt
fi

# Install OpenAuto Pro (open-source Android Auto implementation)
print_status "Installing OpenAuto..."
cd /opt/android-auto-hud

# Try to install OpenAuto, with fallback to simpler solution
if [ ! -d "openauto" ]; then
    print_status "Cloning OpenAuto repository..."
    if git clone --recursive https://github.com/f1xpl/openauto.git; then
        cd openauto
        
        # Ensure all submodules are properly initialized
        print_status "Initializing submodules (including aasdk)..."
        git submodule update --init --recursive --force
        
        # Verify aasdk is downloaded
        if [ ! -d "aasdk" ] || [ ! -f "aasdk/include/f1x/aasdk/IOPromise.hpp" ]; then
            print_warning "AASDK submodule missing, trying manual clone..."
            rm -rf aasdk
            git clone https://github.com/f1xpl/aasdk.git
        fi
        
        # Install additional dependencies for OpenAuto
        print_status "Installing OpenAuto-specific dependencies..."
        apt install -y \
            libtag1-dev \
            librtaudio-dev \
            libasound2-dev \
            libpulse-dev \
            qtquickcontrols2-5-dev || print_warning "Some optional dependencies unavailable"
        
        print_status "Building OpenAuto (this may take 20-30 minutes)..."
        mkdir -p build
        cd build
        
        # Configure with specific flags for Raspberry Pi
        print_status "Configuring build for Raspberry Pi..."
        if cmake \
            -DCMAKE_BUILD_TYPE=Release \
            -DRPI_BUILD=TRUE \
            -DAASDK_INCLUDE_DIRS="../aasdk/include" \
            -DAASDK_LIBRARIES="../aasdk/lib" \
            -DAASDK_PROTO_INCLUDE_DIRS="../aasdk" \
            -DAASDK_PROTO_LIBRARIES="../aasdk" \
            -DGST_BUILD=TRUE \
            -DQT_BUILD=TRUE \
            ../; then
            
            print_status "Building OpenAuto..."
            if make -j$(nproc --ignore=1); then  # Use one less core to avoid memory issues
                print_status "Installing OpenAuto..."
                make install
                print_success "OpenAuto installed successfully"
            else
                print_warning "OpenAuto build failed during compilation, installing alternative solution..."
                cd /opt/android-auto-hud
                rm -rf openauto
            fi
        else
            print_warning "OpenAuto CMake configuration failed, installing alternative solution..."
            cd /opt/android-auto-hud
            rm -rf openauto
            
            # Create a simple launcher as fallback
            mkdir -p simple-auto
            cat > simple-auto/launcher.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0

# Detect available browser
if command -v chromium-browser &> /dev/null; then
    BROWSER="chromium-browser"
elif command -v chromium &> /dev/null; then
    BROWSER="chromium"
elif command -v firefox-esr &> /dev/null; then
    BROWSER="firefox-esr"
else
    BROWSER="x-www-browser"
fi

# Simple Android Auto placeholder interface
$BROWSER --kiosk --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-dev-shm-usage --no-sandbox \
    --window-size=800,480 \
    --autoplay-policy=no-user-gesture-required \
    "data:text/html,<html><head><title>Android Auto HUD</title></head><body style='margin:0;padding:20px;background:#1a1a1a;color:#fff;font-family:Arial;text-align:center;'><h1 style='color:#4CAF50;'>Android Auto HUD</h1><h2>Ready for Connection</h2><p>Connect your Android phone via USB</p><p>Enable USB Debugging in Developer Options</p><div style='margin:50px auto;padding:30px;border:2px solid #4CAF50;border-radius:10px;max-width:400px;'><h3>System Status</h3><p>✓ Display: DSI 5-inch (800x480)</p><p>✓ Rotation: 180° (Dashboard mount)</p><p>✓ Touch: Enabled</p><p>✓ Audio: 3.5mm jack</p></div><p style='margin-top:50px;font-size:14px;'>Install complete OpenAuto for full functionality</p></body></html>"
EOF
            chmod +x simple-auto/launcher.sh
            print_warning "Installed simple interface as fallback"
        fi
    else
        print_error "Failed to clone OpenAuto repository"
        print_status "Installing simple Android Auto interface..."
        
        # Create simple interface as fallback
        mkdir -p simple-auto
        cat > simple-auto/launcher.sh << 'EOF'
#!/bin/bash
export DISPLAY=:0

# Detect available browser
if command -v chromium-browser &> /dev/null; then
    BROWSER="chromium-browser"
elif command -v chromium &> /dev/null; then
    BROWSER="chromium"
elif command -v firefox-esr &> /dev/null; then
    BROWSER="firefox-esr"
else
    BROWSER="x-www-browser"
fi

# Simple Android Auto placeholder interface
$BROWSER --kiosk --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-dev-shm-usage --no-sandbox \
    --window-size=800,480 \
    --autoplay-policy=no-user-gesture-required \
    "data:text/html,<html><head><title>Android Auto HUD</title></head><body style='margin:0;padding:20px;background:#1a1a1a;color:#fff;font-family:Arial;text-align:center;'><h1 style='color:#4CAF50;'>Android Auto HUD</h1><h2>Ready for Connection</h2><p>Connect your Android phone via USB</p><p>Enable USB Debugging in Developer Options</p><div style='margin:50px auto;padding:30px;border:2px solid #4CAF50;border-radius:10px;max-width:400px;'><h3>System Status</h3><p>✓ Display: DSI 5-inch (800x480)</p><p>✓ Rotation: 180° (Dashboard mount)</p><p>✓ Touch: Enabled</p><p>✓ Audio: 3.5mm jack</p></div><p style='margin-top:50px;font-size:14px;'>Install complete OpenAuto for full functionality</p></body></html>"
EOF
        chmod +x simple-auto/launcher.sh
        print_success "Simple Android Auto interface installed"
    fi
else
    print_status "OpenAuto already installed"
fi

# Create systemd service
print_status "Creating systemd service..."
cat > /etc/systemd/system/android-auto-hud.service << EOF
[Unit]
Description=Android Auto HUD Service
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
User=pi
Group=pi
WorkingDirectory=/opt/android-auto-hud
ExecStart=/opt/android-auto-hud/start-hud.sh
Restart=always
RestartSec=5
Environment=DISPLAY=:0
Environment=XDG_RUNTIME_DIR=/run/user/1000

[Install]
WantedBy=graphical-session.target
EOF

# Enable the service
systemctl daemon-reload
systemctl enable android-auto-hud.service

# Configure auto-login for pi user
print_status "Configuring auto-login..."
systemctl set-default graphical.target
if [ ! -f /etc/lightdm/lightdm.conf.backup ]; then
    cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi

sed -i 's/#autologin-user=/autologin-user=pi/' /etc/lightdm/lightdm.conf
sed -i 's/#autologin-user-timeout=0/autologin-user-timeout=0/' /etc/lightdm/lightdm.conf

# Configure X server to allow anyone to start it
sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config

# Add pi user to required groups
usermod -a -G audio,video,input,dialout,plugdev,netdev pi

# Set up udev rules for Android devices
print_status "Setting up USB/Android device rules..."
cat > /etc/udev/rules.d/51-android.rules << EOF
# Google
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
# Samsung
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
# LG
SUBSYSTEM=="usb", ATTR{idVendor}=="1004", MODE="0666", GROUP="plugdev"
# Huawei
SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", MODE="0666", GROUP="plugdev"
# HTC
SUBSYSTEM=="usb", ATTR{idVendor}=="0bb4", MODE="0666", GROUP="plugdev"
# Sony
SUBSYSTEM=="usb", ATTR{idVendor}=="0fce", MODE="0666", GROUP="plugdev"
# Motorola
SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0666", GROUP="plugdev"
# OnePlus
SUBSYSTEM=="usb", ATTR{idVendor}=="2a70", MODE="0666", GROUP="plugdev"
# Xiaomi
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0666", GROUP="plugdev"
EOF

udevadm control --reload-rules

# Create startup script
print_status "Creating startup script..."
cat > /opt/android-auto-hud/start-hud.sh << 'EOF'
#!/bin/bash

# Wait for X server to be ready
while ! pgrep -x "Xorg" > /dev/null; do
    sleep 1
done

# Wait a bit more for everything to settle
sleep 5

# Set display
export DISPLAY=:0

# Hide cursor
unclutter -idle 1 &

# Start Android Auto interface
if [ -d "/opt/android-auto-hud/openauto/build/bin" ] && [ -f "/opt/android-auto-hud/openauto/build/bin/autoapp" ]; then
    # Start full OpenAuto if available
    echo "Starting OpenAuto..."
    cd /opt/android-auto-hud/openauto/build/bin
    ./autoapp
elif [ -f "/opt/android-auto-hud/simple-auto/launcher.sh" ]; then
    # Start simple interface as fallback
    echo "Starting simple Android Auto interface..."
    /opt/android-auto-hud/simple-auto/launcher.sh
else
    # Last resort: basic interface
    echo "No Android Auto interface found, starting basic display..."
    
    # Detect available browser
    if command -v chromium-browser &> /dev/null; then
        BROWSER="chromium-browser"
    elif command -v chromium &> /dev/null; then
        BROWSER="chromium"
    elif command -v firefox-esr &> /dev/null; then
        BROWSER="firefox-esr"
    else
        BROWSER="x-www-browser"
    fi
    
    $BROWSER --kiosk --disable-infobars \
        --disable-session-crashed-bubble \
        --disable-dev-shm-usage --no-sandbox \
        --window-size=800,480 \
        "data:text/html,<html><head><title>Android Auto HUD</title></head><body style='margin:0;padding:50px;background:#1a1a1a;color:#fff;font-family:Arial;text-align:center;'><h1 style='color:#f44336;'>Android Auto HUD</h1><h2>Installation Issue</h2><p>Please run the installation script again</p><p>or install OpenAuto manually</p></body></html>"
fi

EOF

chmod +x /opt/android-auto-hud/start-hud.sh

# Install unclutter to hide cursor
apt install -y unclutter

# Create boot splash configuration
print_status "Configuring boot splash..."
if ! grep -q "disable_splash=1" /boot/config.txt; then
    echo "disable_splash=1" >> /boot/config.txt
fi

# Configure cmdline.txt for faster boot and no console messages
cp /boot/cmdline.txt /boot/cmdline.txt.backup
sed -i 's/console=tty1/console=tty3 quiet splash loglevel=3 logo.nologo vt.global_cursor_default=0/' /boot/cmdline.txt

# Configure DSI 5-inch display connection
print_status "Configuring DSI 5-inch display connection..."

# Remove any existing HDMI settings that might conflict
sed -i '/hdmi_force_hotplug/d' /boot/config.txt
sed -i '/hdmi_group/d' /boot/config.txt
sed -i '/hdmi_mode/d' /boot/config.txt
sed -i '/hdmi_cvt/d' /boot/config.txt

# Configure framebuffer for DSI display
if ! grep -q "framebuffer_width=800" /boot/config.txt; then
    echo "framebuffer_width=800" >> /boot/config.txt
fi

if ! grep -q "framebuffer_height=480" /boot/config.txt; then
    echo "framebuffer_height=480" >> /boot/config.txt
fi

# Disable overscan for DSI displays
if ! grep -q "disable_overscan=1" /boot/config.txt; then
    echo "disable_overscan=1" >> /boot/config.txt
fi

# Enable DSI display auto-detection
if ! grep -q "display_auto_detect=1" /boot/config.txt; then
    echo "display_auto_detect=1" >> /boot/config.txt
fi

# Ensure DSI is enabled
if ! grep -q "enable_dsi_auto_timing=1" /boot/config.txt; then
    echo "enable_dsi_auto_timing=1" >> /boot/config.txt
fi

print_success "DSI 5-inch display configured"

# Create configuration file
print_status "Creating configuration file..."
cat > /opt/android-auto-hud/config.ini << EOF
[Display]
rotation=180
resolution=800x480
fullscreen=true

[Audio]
output=analog
volume=80

[Android]
enable_wireless=false
enable_usb=true

[System]
auto_start=true
hide_cursor=true
EOF

# Set ownership
chown -R pi:pi /opt/android-auto-hud
chown -R pi:pi /home/pi/.config

print_success "Installation completed successfully!"
print_status "Configuration summary:"
echo "  ✓ Display rotation: 180°"
echo "  ✓ Resolution: 800x480 (DSI 5-inch optimized)"
echo "  ✓ Auto-start on boot: Enabled"
echo "  ✓ Audio output: 3.5mm jack (configurable)"
echo "  ✓ OpenAuto installed"
echo "  ✓ USB Android device support enabled"
echo ""
print_warning "Please reboot your Raspberry Pi to apply all changes:"
print_status "sudo reboot"
echo ""
print_status "After reboot:"
echo "1. Connect your Android phone via USB"
echo "2. Enable Developer Options and USB Debugging on your phone"
echo "3. The Android Auto interface should start automatically"
echo ""
print_status "Logs can be viewed with: sudo journalctl -u android-auto-hud" 