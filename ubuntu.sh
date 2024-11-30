#!/data/data/com.termux/files/usr/bin/bash

# Check for root access
if [ "$(id -u)" == "0" ]; then
   echo "This script should not be run as root. Exiting."
   exit 1
fi

# Declare variables
UBUNTU_URL="https://cdimage.ubuntu.com/ubuntu-base/jammy/ubuntu-base-22.04.5-base-arm64.tar.gz"
UBUNTU_TAR="ubuntu-base-jammy-arm64.tar.gz"
DEST_DIR="$HOME/ubuntu-jammy"
USERNAME="daffa"
PASSWORD="Daffa30"
MIRRORED_URL="http://mirrors.kernel.org/ubuntu/dists/jammy/main/binary-arm64/Packages.gz"
PKG_LIST_FILE="/tmp/packages_list.txt"
PROOT_TMP="/tmp/proot_tmp"

# Function to ask for confirmation
confirm() {
    read -r -p "Do you want to proceed? [Y/n] " response
    case "$response" in
        [nN][oO]|[nN])
            echo "Installation cancelled."
            exit 0
            ;;
        *)
            ;;
    esac
}

# Check if required tools are installed
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo "$1 is required but not installed. Installing $1..."
        pkg install "$1" -y
    fi
}

# Install required tools
for tool in proot wget tar; do
    check_tool $tool
done

# Create necessary directories
mkdir -p "$DEST_DIR" "$PROOT_TMP"

# Download Ubuntu base image
echo "Downloading Ubuntu Jammy base system..."
if ! wget -O "$DEST_DIR/$UBUNTU_TAR" "$UBUNTU_URL"; then
    echo "Failed to download the Ubuntu base system. Please check your internet connection."
    exit 1
fi
confirm

# Extract the tarball and handle possible errors
echo "Extracting Ubuntu image..."
tar --warning=no-unknown-keyword -xzf "$DEST_DIR/$UBUNTU_TAR" -C "$DEST_DIR"
if [ $? -ne 0 ]; then
    echo "Error during extraction. Attempting to fix common issues..."
    tar --warning=no-unknown-keyword --ignore-zeros -xzf "$DEST_DIR/$UBUNTU_TAR" -C "$DEST_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to extract tarball even after trying to fix errors. Exiting."
        exit 1
    fi
fi

# Link proot to symlink
proot --link2symlink "$DEST_DIR"

# Download and extract package lists for package detection
echo "Downloading package list for better package management..."
wget -O - "$MIRRORED_URL" | gunzip -c > "$PKG_LIST_FILE"

# Start the chroot session with additional configurations
echo "Setting up the chroot environment..."
proot -0 -r "$DEST_DIR" -b /dev -b /proc -b /sys -b /system -b /data/data/com.termux/files/usr/bin:/bin -w / -0 \
    /bin/sh -c "echo 'root:toor' | chpasswd; \
    useradd -m -s /bin/bash $USERNAME; \
    echo '$USERNAME:$PASSWORD' | chpasswd; \
    dpkg --print-architecture; \
    cp /etc/apt/sources.list /etc/apt/sources.list.bak; \
    echo 'deb http://mirrors.kernel.org/ubuntu/ jammy main universe' > /etc/apt/sources.list; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y sudo tar wget; \
    echo '$USERNAME ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers; \
    echo 'Acquire::http { Proxy \"http://127.0.0.1:8080/\"; };' > /etc/apt/apt.conf.d/99proxy; \
    su - $USERNAME -c 'echo \"export PS1=\\\"\$USER@jammy:\\\\W\\\\$ \\\"\" >> ~/.bashrc'; \
    su - $USERNAME -c 'echo \"source /etc/profile\" >> ~/.bashrc'; \
    su - $USERNAME"

echo "Ubuntu Jammy installation complete!"
echo "You can now start your Ubuntu environment by running 'proot -0 -r $DEST_DIR -b /dev -b /proc -b /sys -b /system -b /data/data/com.termux/files/usr/bin:/bin -w / /bin/bash -l'"

# Script to check for updates
echo "Creating a script to check for updates..."
cat << 'EOF' > "$DEST_DIR/check_update.sh"
#!/bin/bash
apt update
apt upgrade -y
echo "System updated to the latest packages."
EOF
chmod +x "$DEST_DIR/check_update.sh"

# Script to run commands inside chroot
echo "Creating a script to run commands inside chroot..."
cat << 'EOF' > "$DEST_DIR/run.sh"
#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 <command>"
    exit 1
fi
proot -0 -r $HOME/ubuntu-jammy -b /dev -b /proc -b /sys -b /system -b /data/data/com.termux/files/usr/bin:/bin -w / /bin/sh -c "su - daffa -c \"$@\""
EOF
chmod +x "$DEST_DIR/run.sh"

# Script to cleanup
echo "Creating a cleanup script..."
cat << 'EOF' > "$DEST_DIR/cleanup.sh"
#!/bin/bash
rm -rf $HOME/ubuntu-jammy
rm $HOME/check_update.sh $HOME/run.sh $HOME/cleanup.sh
echo "Ubuntu Jammy environment has been removed."
EOF
chmod +x "$DEST_DIR/cleanup.sh"

# Create symbolic links in Termux home for easy access
ln -s "$DEST_DIR/check_update.sh" "$HOME/check_update"
ln -s "$DEST_DIR/run.sh" "$HOME/run"
ln -s "$DEST_DIR/cleanup.sh" "$HOME/cleanup"

echo "Additional utility scripts have been created:"
echo "  - Run 'check_update' to update Ubuntu packages"
echo "  - Run 'run <command>' to execute commands inside the Ubuntu environment"
echo "  - Run 'cleanup' to remove the Ubuntu environment"

echo "Installation and setup of Ubuntu Jammy completed successfully!"
