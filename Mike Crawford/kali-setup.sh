#!/bin/bash

# Function to check for necessary dependencies
check_dependencies() {
    echo "Updating package list..."
    sudo apt update -q
    dpkg -l | grep -qw git || sudo apt install -yq git
}

# Function to display help menu
display_help() {
    echo "Usage: sudo $0 [option]"
    echo "Options: -h|--help"
    exit 0
}

# Check for help argument
[[ $1 == "-h" || $1 == "--help" ]] && display_help

# Verify root access
[[ $EUID -ne 0 ]] && {
    echo "Run as root. Exiting."
    exit 1
}

# Function to change repositories to Cloudflare
change_repos() {
    read -p "Switch repositories? (y/N): " confirmation
    [[ $confirmation =~ ^[Yy]$ ]] || {
        echo "Cancelled."
        return
    }
    sudo cp /etc/apt/sources.list{,.bak}
    sudo sed -i 's|http://http.kali.org/kali|http://kali.download/kali|g' /etc/apt/sources.list
}

# Function to update Kali Linux
update_kali() {
    sudo apt update -q && sudo apt dist-upgrade -yq && sudo apt autoremove -yq
}

# Function to clean up
cleanup() {
    apt clean && apt autoclean && apt autoremove -y
    rm -rf /var/cache/apt/archives/*
}

# Function to install headless tools
install_headless() {
    update_kali
    sudo apt install -yq kali-linux-headless kali-linux-firmware htop btop vim tldr ninja-build gettext cmake unzip curl cargo ripgrep gdu || {
        echo "Network issue. Exiting."
        exit 1
    }
    su kali -c 'tldr -u'
    if command -v nvim >/dev/null; then
        echo "Neovim already installed. Skipping..."
    else
        install_neovim
    fi
    cleanup
}

# Function to install neovim
install_neovim() {
    [ -d "neovim" ] && echo "neovim exists. Skipping git clone..." || git clone https://github.com/neovim/neovim
    cd neovim || {
        echo "Failed to cd to neovim"
        exit 1
    }
    git checkout stable

    make CMAKE_BUILD_TYPE=RelWithDebInfo || {
        echo "Failed to make neovim..."
        exit 1
    }
    cd build && cpack -G DEB && dpkg -i nvim-linux64.deb
    wget -q -O /tmp/CascadiaCode.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/CascadiaCode.zip"
    unzip -o -d ~/.fonts /tmp/CascadiaCode.zip
    fc-cache -fv
    rm /tmp/CascadiaCode.zip

    cargo install tree-sitter-cli
    curl -LO https://github.com/ClementTsang/bottom/releases/download/0.9.6/bottom_0.9.6_amd64.deb
    sudo dpkg -i bottom_0.9.6_amd64.deb
    mv ~/.config/nvim ~/.config/nvim.bak
    mv ~/.local/share/nvim ~/.local/share/nvim.bak
    mv ~/.local/state/nvim ~/.local/state/nvim.bak
    mv ~/.cache/nvim ~/.cache/nvim.bak
    git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim
    cd /home/kali || return
    rm -rf neovim
}

# Function to install Desktop
install_desktop_default() {
    install_headless
    sudo apt install -yq kali-desktop-xfce kali-linux-default kali-tools-* xrdp && sudo systemctl enable --now xrdp
    cleanup
}

# Function to install all including pimp my kali
install_all_pimp() {
    install_desktop_default
    [ -d "pimpmykali" ] && echo "pimpmykali exists. Skipping git clone..." || git clone https://github.com/Dewalt-arch/pimpmykali.git
    cd pimpmykali || {
        echo "Failed to cd to pimpmykali..."
        exit 1
    }
    ./pimpmykali.sh || {
        echo "Failed to run pimpmykali.sh"
        exit 1
    }
    cd /home/kali || exit
    rm -rf pimpmykali
    cleanup
}

# Quit function
reboot_func() {
    read -p "Would you like to reboot now? (y/N): " reboot_choice
    [[ $reboot_choice =~ ^[Yy]$ ]] && reboot || echo "Exiting script without rebooting"
}

# Display TUI menu
display_menu() {
    while true; do
        read -p "U: Update, I: Headless, D: Desktop, A: All Tools, C: Change Repos, Q: Quit: " choice
        case $choice in
        U | u) update_kali ;;
        I | i) install_headless ;;
        D | d) install_desktop_default ;;
        A | a) install_all_pimp ;;
        C | c) change_repos ;;
        Q | q) reboot_func && exit 0 ;;
        *) echo "Invalid. Retry." ;;
        esac
    done
}

main() {
    check_dependencies
    display_menu
}

main
