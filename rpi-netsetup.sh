#!/bin/bash

# Exit on error
set -e

# Prompt for network configuration
DEFAULT_INTERFACE=$(nmcli -t -f DEVICE,STATE dev | grep ':connected' | grep -v 'lo:' | cut -d: -f1)
DEFAULT_IP_ADDRESS=$(nmcli -g IP4.ADDRESS dev show "$DEFAULT_INTERFACE" | head -n1 | cut -d/ -f1)
DEFAULT_GATEWAY=$(nmcli -g IP4.GATEWAY dev show "$DEFAULT_INTERFACE")
DEFAULT_DNS_SERVER=$(nmcli -g IP4.DNS dev show "$DEFAULT_INTERFACE" | head -n1 || echo "8.8.8.8")

echo "Please enter the following network configuration details (Press Enter to use the defaults):"
read -p "Interface name [${DEFAULT_INTERFACE}]: " INTERFACE
INTERFACE=${INTERFACE:-$DEFAULT_INTERFACE}

read -p "IP Address [${DEFAULT_IP_ADDRESS}]: " IP_ADDRESS
IP_ADDRESS=${IP_ADDRESS:-$DEFAULT_IP_ADDRESS}

read -p "Subnet Mask (e.g., 24 for /24 or 255.255.255.0) [24]: " SUBNET_MASK
SUBNET_MASK=${SUBNET_MASK:-24}

read -p "Gateway [${DEFAULT_GATEWAY}]: " GATEWAY
GATEWAY=${GATEWAY:-$DEFAULT_GATEWAY}

read -p "DNS Server [${DEFAULT_DNS_SERVER}]: " DNS_SERVER
DNS_SERVER=${DNS_SERVER:-$DEFAULT_DNS_SERVER}

# Apply network configuration using nmcli
echo "Configuring network with NetworkManager..."
sudo nmcli con mod "$INTERFACE" ipv4.addresses "$IP_ADDRESS/$SUBNET_MASK" ipv4.gateway "$GATEWAY" ipv4.dns "$DNS_SERVER" ipv4.method manual
sudo nmcli con up "$INTERFACE"

# Final message
echo "Network configuration applied successfully!"