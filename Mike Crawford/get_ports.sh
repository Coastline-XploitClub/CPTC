#!/bin/bash

function usage {
    echo "Usage: ./get_ports.sh <nmap_file> <output_file>"
    echo
    echo "This script processes an Nmap output file, extracts open port numbers,"
    echo "and writes them to the specified output file, formatted as a comma-separated list."
    echo
    echo "Arguments:"
    echo "  nmap_file      The input file containing Nmap output"
    echo "  output_file    The file to which the list of open ports will be written"
    exit 1
}

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    usage
fi

nmap_file=$1
output_file=$2

# Check if input file exists
if [ ! -f "$nmap_file" ]; then
    echo "Error: File '$nmap_file' not found."
    exit 1
fi

cat $nmap_file | grep -v "#" | grep open | awk -F'/' '{print $1}' | tr '\n' ',' | sed 's/,$//' > $output_file
