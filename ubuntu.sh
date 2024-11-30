!/data/data/com.termux/files/usr/bin/bash

time1="$( date +"%r" )"

install_ubuntu() {
    local directory=ubuntu-fs
    local ubuntu_version='22.04'
    local tar_file="ubuntu.tar.gz"

     Check if proot and wget are installed
    if [ -z "$(command -v proot)" ]; then
        echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;203m[ERROR]:\033[0m \033[38;5;87mPlease install proot.\n"
        exit 1
    fi

    if [ -z "$(command -v wget)" ]; then
        echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;203m[ERROR]:\033[0m \033[38;5;87mPlease install wget.\n"
        exit 1
    fi

     Check if the Ubuntu directory already exists
    if [ -d "$directory" ]; then
        echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;227m[WARNING]:\033[0m \033[38;5;87mUbuntu is already installed. Skipping download and extraction.\n"
        return
    fi

     Download Ubuntu root filesystem
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87mDownloading the Ubuntu root filesystem, please wait...\n"
    local architecture=$(dpkg --print-architecture)
    case "$architecture" in
        aarch64) architecture="arm64";;
        arm) architecture="armhf";;
        amd64|x86_64) architecture="amd64";;
        *)
            echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;203m[ERROR]:\033[0m \033[38;5;87mUnknown architecture: $architecture\n"
            exit 1
            ;;
    esac

    wget "https://cdimage.ubuntu.com/ubuntu-base/releases/${ubuntu_version}/release/ubuntu-base-${ubuntu_version}-base-${architecture}.tar.gz" -q -O "$tar_file"
    if [ $? -ne 0 ]; then
        echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;203m[ERROR]:\033[0m \033[38;5;87mFailed to download Ubuntu root filesystem.\n"
        exit 1
    fi
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87mDownload complete!\n"

     Create the Ubuntu directory and extract the root filesystem
    mkdir -p "$directory"
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87mDecompressing the Ubuntu root filesystem, please wait...\n"
    proot --link2symlink tar -zxf "$tar_file" --directory="$directory" --exclude='dev'
    if [ $? -ne 0 ]; then
        echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;203m[ERROR]:\033[0m \033[38;5;87mFailed to decompress the Ubuntu root filesystem.\n"
        exit 1
    fi
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87mUbuntu root filesystem decompressed successfully!\n"

     Configure network resolution
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87mConfiguring network...\n"
    echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4\n" > "$directory/etc/resolv.conf"

     Create a user "daffa" with password "Daffa30"
    mkdir -p "$directory/home/daffa"
    echo "daffa:Daffa30" | chpasswd --root="$directory"
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87mUser 'daffa' created with password 'Daffa30'!\n"

     Setting up the default environment for the user
    echo -e "!/bin/bash\n" > "$directory/root/.bashrc"
    echo -e "export LANG=C.UTF-8\nexport PATH=\$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n" >> "$directory/root/.bashrc"

     Set permissions for accessing all folders
    chmod -R 777 "$directory"
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87mPermissions set to allow access to all directories.\n"

     Create the startup script
    local bin=startubuntu.sh
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87mCreating the startup script...\n"
    cat > "$bin" <<- EOM
!/bin/bash
cd \$(dirname \$0)
 unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $directory"
command+=" -b /dev"
command+=" -b /proc"
command+=" -b /sys"
command+=" -b ubuntu-fs/tmp:/dev/shm"
command+=" -b /data/data/com.termux"
command+=" -b /:/host-rootfs"
command+=" -b /sdcard"
command+=" -b /storage"
command+=" -b /mnt"
 Set working directory to the home of daffa
command+=" -w /home/daffa"
command+=" /usr/bin/env -i"
command+=" HOME=/home/daffa"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ]; then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

     Make the startup script executable
    chmod +x "$bin"
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87mStartup script created successfully!\n"
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87mCompleting installation...\n"

     Cleanup downloaded tar file
    rm "$tar_file"
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87mCleaned up temporary files!\n"

     Final message
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;83m[INFO]:\033[0m \033[38;5;87mInstallation complete! You can now launch Ubuntu using ./$bin\n"
}

 Main script execution
if [ "$1" = "-y" ]; then
    install_ubuntu
elif [ "$1" = "" ]; then
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;127m[QUESTION]:\033[0m \033[38;5;87mDo you want to install Ubuntu in Termux? [Y/n] "
    
    read cmd1
    if [ "$cmd1" = "y" ] || [ "$cmd1" = "Y" ]; then
        install_ubuntu
    else
        echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;203m[ERROR]:\033[0m \033[38;5;87mInstallation aborted.\n"
        exit
    fi
else
    echo -e "\033[38;5;214m[${time1}]\033[0m \033[38;5;203m[ERROR]:\033[0m \033[38;5;87mInvalid option. Use -y to skip confirmation or no arguments for a prompt.\n"
    exit
fi
