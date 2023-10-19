#!/bin/bash
# Script to setup a folder for an HTB machine

if [ -z "$1" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo -e "\nUsage: ./setup_folder.sh [box_name]"
    echo -e "\n-h, --help  Show this help message"
    exit 1
fi

dir="$1"

if [ -d "$dir" ]; then
    echo -e "\nDirectory $dir already exists"
    exit 1
fi

mkdir -p "/home/mike/htb/labs/$dir"/{nmap,loot,exploits,extra,recon}
echo -e "# $dir" > "/home/mike/htb/labs/$dir"/README.md
