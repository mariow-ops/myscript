#!/bin/bash

# Define the Input file
INFILE=/home/mario/Documents/myscript/IP.txt

# Check if the input file exists
if [ ! -f "$INFILE" ]; then
    echo "File $INFILE does not exist."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if the Docker image is built
if ! docker image ls | grep sslyze &> /dev/null
then
    echo "The Docker image for sslyze is not built. Building the image..."
    docker build -t sslyze .
fi

# Check if an input file is provided as an argument
if [ $# -eq 0 ]
then
    echo "Please provide an input file as an argument."
    exit 1
fi

# Loop through the domain names in the input file and scan each one using sslyze
while IFS= read -r domain
do
    echo "Scanning $domain for vulnerabilities...">>IP.txt
    output=$(docker run sslyze $domain)
    echo "$output">>IP.txt
done < "/home/mariow/Documents/myscript/domain.txt"


# Read the file line by line
while IFS= read -r line
do
    counter=0
    # Extract the domain name

    domain=$(echo "$line" | grep -oP '(?<=SCAN RESULTS FOR ).*')
    if [ -z "$domain" ]; then
        continue
    fi

    # Print the domain name
    echo "Domain Name: $domain"

    # Extract the results for the specified tests
    echo "Test Results:"
    while true; do
        grep -m 4 -A 1 'Deflate Compression\|OpenSSL CCS Injection\|OpenSSL Heartbleed\|ROBOT Attack' | tr -s ' '
        #output=$(grep -m 1 'Deflate Compression')
        #put=$(grep -A 1 'Deflate Compression'| tr '\n' ' ')
        #echo "$output $put"
        echo -e '\n'
        grep -m 1 -A 2 'Session Renegotiation'
        counter=$((counter+1))

        # Check if the counter reaches one
        if [ $counter -eq 1 ]; then
            break
        fi
    done
    echo -e '\n'
    sleep 5
    
done < "/home/mariow/Documents/myscript/IP.txt"