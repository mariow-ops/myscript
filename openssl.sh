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

# Convert the provided IP address to a range
ip=$1
IFS='.' read -ra ADDR <<< "$ip"
range="${ADDR[0]}.${ADDR[1]}.${ADDR[2]}.0-${ADDR[0]}.${ADDR[1]}.${ADDR[2]}.255"

is_valid_ip()
{
    local ip=$1
    local IFS='.' parts=($ip) count=${#parts[@]}
    if ((count != 4)); then return 1; fi
    for part in "${parts[@]}"; do
        if ((part < 0 || part > 255)); then return 1; fi
    done
    return 0
}

# Then, before calling ip_to_int, check if the IP is valid
# if is_valid_ip "$ip"; then
#     ip_to_int "$ip"
# else
#     echo "Invalid IP address: $ip"
#     exit 1
# fi

# Function to convert IP to integer
ip_to_int()
{
    local IFS='.' ip=($1) i
    ip=()
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