#!/bin/bash

# Exit on error
set -e

# Update and upgrade packages
sudo apt update && sudo apt upgrade -y

# Install depndencies
echo "Updating and nstalling dependencies..."
sudo apt install -y net-tools

# Function to convert CIDR to subnet mask
cidr_to_netmask() {
    local cidr=$1
    local mask=""
    local i
    for ((i=0; i<4; i++)); do
        if [ "$cidr" -ge 8 ]; then
            mask+=255
            cidr=$((cidr-8))
        else
            mask+=$((256-(2**(8-cidr))))
            cidr=0
        fi
        [ $i -lt 3 ] && mask+=.
    done
    echo "$mask"
}

# Get current network configuration
CURRENT_INTERFACE=$(ip route | grep default | awk '{print $5}')
CURRENT_IP_ADDRESS=$(ip -o -4 addr list "$CURRENT_INTERFACE" | awk '{print $4}' | cut -d/ -f1)
CURRENT_CIDR=$(ip -o -4 addr list "$CURRENT_INTERFACE" | awk '{print $4}' | cut -d/ -f2)
CURRENT_SUBNET_MASK=$(cidr_to_netmask "$CURRENT_CIDR")
CURRENT_GATEWAY=$(ip route | grep default | awk '{print $3}')
CURRENT_DNS="8.8.8.8 8.8.4.4"

# Prompt for network configuration with default values
echo "Please enter the following network configuration details (press Enter to accept default values):"
read -p "Interface name [$CURRENT_INTERFACE]: " INTERFACE
INTERFACE=${INTERFACE:-$CURRENT_INTERFACE}

read -p "IP Address [$CURRENT_IP_ADDRESS]: " IP_ADDRESS
IP_ADDRESS=${IP_ADDRESS:-$CURRENT_IP_ADDRESS}

read -p "Subnet Mask [$CURRENT_SUBNET_MASK]: " SUBNET_MASK
SUBNET_MASK=${SUBNET_MASK:-$CURRENT_SUBNET_MASK}

read -p "Gateway [$CURRENT_GATEWAY]: " GATEWAY
GATEWAY=${GATEWAY:-$CURRENT_GATEWAY}

read -p "DNS Server(s) (space-separated) [$CURRENT_DNS]: " DNS
DNS=${DNS:-$CURRENT_DNS}

# Validate inputs
# The key change: DNS now checks for one or more space-separated IP addresses
if ! [[ $INTERFACE =~ ^[a-zA-Z0-9]+$ ]] || \
   ! [[ $IP_ADDRESS =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
   ! [[ $SUBNET_MASK =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
   ! [[ $GATEWAY =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
   ! [[ $DNS =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)([[:space:]]+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)*$ ]]; then
    echo "Invalid IP address format. Please check your inputs."
    exit 1
fi

echo "Backing up and cleaning /etc/network/interfaces..."
sudo cp /etc/network/interfaces /etc/network/interfaces.bak

sudo bash -c 'cat > /etc/network/interfaces' <<EOL
source /etc/network/interfaces.d/*
EOL

echo "Configuring static IP for $INTERFACE..."
NETWORK_CONFIG="/etc/network/interfaces.d/$INTERFACE.cfg"
sudo tee "$NETWORK_CONFIG" > /dev/null <<EOL
auto $INTERFACE
iface $INTERFACE inet static
    address $IP_ADDRESS
    netmask $SUBNET_MASK
    gateway $GATEWAY
    dns-nameservers $DNS
EOL

echo "Restarting network service to apply the static IP configuration..."
sudo systemctl restart networking

echo "Verifying new interface settings..."
ip addr show "$INTERFACE"
