#!/bin/bash

usage() {
    echo "Usage: $0 -t <target-network> [-p]"
    echo "Options:"
    echo "  -t    Target network or IP"
    echo "  -p    Enable parallel scanning (default is sequential)"
    echo "  -h    Display this help message"
    exit 1
}

PARALLEL=0

while getopts "t:ph" opt; do
    case $opt in
        t)
            TARGET_NETWORK=$OPTARG
            ;;
        p)
            PARALLEL=1
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

if [[ -z $TARGET_NETWORK ]]; then
    usage
fi

echo "Running host discovery on $TARGET_NETWORK..."
nmap -sn $TARGET_NETWORK -oG discovery.gnmap
LIVE_HOSTS=$(grep "Status: Up" discovery.gnmap | awk '{print $2}')

if [[ -z $LIVE_HOSTS ]]; then
    echo "No live hosts found in $TARGET_NETWORK."
    exit 1
fi

echo "Live hosts discovered: $LIVE_HOSTS"


scan_host() {
    local HOST=$1
    echo "Running initial Nmap scan on $HOST..."
    nmap -p- --open --min-rate=1000 -T4 $HOST -oN initial-scan-$HOST.txt

    local OPEN_PORTS=$(grep -v "#" initial-scan-$HOST.txt | grep 'open' | awk -F'/' '{print $1}' | tr '\n' ',' | sed 's/,$//')
    if [[ -z $OPEN_PORTS ]]; then
        echo "No open ports found on $HOST."
        return
    fi

    echo "Open ports on $HOST: $OPEN_PORTS"
    echo "Running script scan on $HOST..."
    nmap -sC -sV -p$OPEN_PORTS --script=safe,default $HOST -oN script-scan-$HOST.txt
}

export -f scan_host

if [[ $PARALLEL -eq 1 ]]; then
    echo "Running parallel scans..."
    parallel scan_host ::: $LIVE_HOSTS
else
    echo "Running sequential scans..."
    for HOST in $LIVE_HOSTS; do
        scan_host $HOST
    done
fi

echo "Scans completed."
