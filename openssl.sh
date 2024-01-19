##!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if the Docker image is built
if ! docker image ls | grep openssl &> /dev/null
then
    echo "The Docker image for openssl is not built. Building the image..."
    docker build -t openssl .
fi

# Check if at least one IP range is provided as an argument
if [ $# -eq 0 ]
then
    echo "Please provide at least one IP range as an argument."
    exit 1
fi

# Function to convert IP to integer
ip_to_int()
{
    local IFS='.' ip=($1) i
    for i in {0..3}; do ip[i]=$((ip[i] << (24 - 8 * i))); done
    echo $((ip[0] | ip[1] | ip[2] | ip[3]))
}

# Function to convert integer to IP
int_to_ip()
{
    local ip del=''
    for i in {3..0}; do
        ip+=$del$((($1 >> (8 * i)) & 0xFF))
        del='.'
    done
    echo "$ip"
}

# Loop through the IP ranges and scan each one using openssl
for range in "$@"
do
    IFS='-' read -r start end <<< "$range"
    start=$(ip_to_int $start)
    end=$(ip_to_int $end)
    for ip in $(seq $start $end); do
        ip=$(int_to_ip $ip)
        echo "Scanning $ip for vulnerabilities..."
        docker run --rm openssl $ip
    done
done