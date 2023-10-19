#!/bin/bash

# Function to check for necessary dependencies
check_dependencies() {
    echo "Updating package list..."
    sudo apt update
    dpkg -l | grep -qw git || {
        echo "Git is not installed. Installing Git..."
        sudo apt install -y git
    }
}

# Function to display help menu
display_help() {
    echo "Usage: sudo $0 [option]"
    echo
    echo "This script provides a TUI menu for Kali Linux configurations."
    echo "Run without arguments to access the TUI menu."
    echo "Available options:"
    echo "  -h, --help    Display this help menu and exit"
    echo
    echo "TUI Menu Options:"
    echo "  U: Update Kali Linux"
    echo "     - Updates the package list for upgrades and new package installations."
    echo "     - Upgrades installed packages to their latest versions."
    echo
    echo "  I: Install kali-headless-tools"
    echo "     - Installs headless tools for Kali Linux."
    echo
    echo "  D: Install desktop and Kali Linux default tools"
    echo "     - Installs the default Kali Linux tools along with the desktop environment."
    echo
    echo "  A: Install desktop and all Kali Linux tools and pimpmykali"
    echo "     - Installs all Kali Linux tools, the desktop environment, and runs pimpmykali for further customization."
    echo
    echo "  C: Change Repositories to Cloudflare"
    echo "     - Changes the APT repositories to use Cloudflare mirrors for faster downloads."
    echo
    exit 0
}

# Check if -h or --help argument is passed
if [[ $1 == "-h" || $1 == "--help" ]]; then
    display_help
fi

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Rerun with sudo $0."
    echo "Exiting."
    exit 1
fi

# Display TUI menu
display_menu() {
    while true; do
        echo ""
        echo ""
        echo "Please select an option:"
        echo "  U: Update Kali Linux"
        echo "  I: Install kali-headless-tools"
        echo "  D: Install desktop and Kali Linux default tools"
        echo "  A: Install desktop and all Kali Linux tools and pimpmykali"
        echo "  C: Change Repositories to Cloudflare"
        echo "  Q: Quit"
        echo ""
        echo ""
        read -p "Enter your choice: " choice
        case $choice in
        U | u)
            update_kali
            ;;
        I | i)
            install_headless
            ;;
        D | d)
            install_desktop_default
            ;;
        A | a)
            install_all_pimp
            ;;
        C | c)
            change_repos
            ;;
        Q | q)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid option $choice, please try again."
            ;;
        esac
    done
}

# Function to change repositories to Cloudflare
change_repos() {
    echo "Changing repositories to Cloudflare..."
    read -p "Are you sure you want to change the repositories? (y/N): " confirmation
    if [[ $confirmation =~ ^[Yy]$ ]]; then
        # Backup the original sources.list file
        sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

        # Replace the repositories in sources.list with Cloudflare repositories
        sudo sed -i 's|http://http.kali.org/kali|http://kali.download/kali|g' /etc/apt/sources.list

        echo "Repositories changed to Cloudflare. The original sources.list file has been backed up to /etc/apt/sources.list.bak."
    else
        echo "Operation cancelled by user."
    fi
}

# Function to update Kali Linux
update_kali() {
    echo "Updating Kali Linux..."
    sudo apt update && sudo apt dist-upgrade -y && sudo apt autoremove -y
    echo "Update completed."
}

# Function to install headless tools
install_headless() {
    echo "Installing kali-linux-headless..."
    if ! sudo apt-get install -y kali-linux-headless; then
        echo "Failed to install kali-linux-headless. Please check your network connection and try again."
        exit 1
    fi
    echo "kali-linux-headless installation complete."
}

# Function to install Desktop
install_desktop_default() {
    echo "Installing Desktop Environment and enabling RDP..."
    if ! sudo apt-get install -y kali-desktop-xfce kali-linux-default xrdp || ! sudo systemctl enable --now xrdp; then
        echo "Failed to complete the installation or enable RDP. Please check your network connection and try again."
        exit 1
    fi
    echo "Desktop Environment installed and RDP enabled successfully."
}

# Function to install all including pimp my kali
install_all_pimp() {
    echo "Installing All Tools and pimping Kali..."
    echo ""
    echo "Executing install_desktop_default function..."
    install_desktop_default || {
        echo "Failed executing install_desktop_default function."
        exit 1
    }
    echo "install_desktop_default function executed successfully."
    echo ""
    echo "Installing kali-linux-large..."
    sudo apt-get install -y kali-linux-large || {
        echo "Failed to install kali-linux-large. Please check your network connection and try again."
        exit 1
    }
    echo "kali-linux-large installed successfully."
    echo ""
    echo "Cloning pimpmykali repository..."
    git clone https://github.com/Dewalt-arch/pimpmykali.git || {
        echo "Failed to clone pimpmykali repository. Please check your network connection and try again."
        exit 1
    }
    echo "pimpmykali repository cloned successfully."
    echo ""
    echo "Running pimpmykali script..."
    cd pimpmykali && ./pimpmykali.sh || {
        echo "Failed to run pimpmykali script. Please check for errors and try again."
        exit 1
    }
    echo ""
    echo "Install and customization complete."
}

# Main function
main() {
    check_dependencies
    display_menu
}

main
