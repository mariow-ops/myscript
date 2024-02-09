#!/bin/bash

# Check if at least one subnet is provided as an argument
if [ $# -eq 0 ]
then
    echo "Please provide at least one subnet as an argument."
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

# Split the subnet and mask from the argument
IFS='/' read -ra ADDR <<< "$1"
subnet=${ADDR[0]}
mask=${ADDR[1]}

# Generate all IP addresses in the subnet
IFS='.' read -ra OCTETS <<< "$subnet"
for i in {0..255}
do
    ip="${OCTETS[0]}.${OCTETS[1]}.${OCTETS[2]}.$i"
    
    # Scan each IP address
    echo "Scanning $ip for vulnerabilities..."
    output=$(docker run sslyze $ip)
    echo "$output" >> subnet.txt
done

while IFS= read -r line
do
    counter=0
    # Extract the ip address 

    ip=$(echo "$line" | grep -oP '(?<=SCAN RESULTS FOR ).*')
    if [ -z "$ip" ]; then
        continue
    fi

    # Print the ip address
    echo "IP Address: $ip" >> results.txt

    # Extract the results for the specified tests
    echo "Test Results:" >> results.txt
    while true; do
        grep -m 4 -A 1 'Deflate Compression\|OpenSSL CCS Injection\|OpenSSL Heartbleed\|ROBOT Attack' | tr -s ' ' >> results.txt
        #output=$(grep -m 1 'Deflate Compression')
        #put=$(grep -A 1 'Deflate Compression'| tr '\n' ' ')
        #echo "$output $put"
        echo -e '\n' >> results.txt
        grep -m 1 -A 2 'Session Renegotiation' | tr -s ' ' >> results.txt
        counter=$((counter+1))

        # Check if the counter reaches one
        if [ $counter -eq 1 ]; then
            break
        fi
    done
    echo -e '\n' >> results.txt
    sleep 5
    
done < "/home/mario/Documents/myscript/subnet.txt"

# Email the results.txt file
mail -s "Results for sslyze subnet" mariow@arizona.edu < results.txt
