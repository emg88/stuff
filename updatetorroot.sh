#!/bin/bash

# Ensure the script is run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run this script as root."
  exit 1
fi

# Add the missing public key
echo "Adding the Tor Project's public key..."
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null

# Configure the Tor repository
echo "Configuring the Tor repository..."
echo "deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org bookworm main" > /etc/apt/sources.list.d/tor.list

# Update the package list
echo "Updating the package list..."
apt update

# Install the latest version of Tor
echo "Installing the latest version of Tor..."
apt install -y tor

# Verify the installation
echo "Verifying the installed Tor version..."
tor_version=$(tor --version 2>/dev/null)
if [[ $? -eq 0 ]]; then
  echo "Tor installed successfully! Version: $tor_version"
else
  echo "Failed to verify Tor installation. Please check manually."
fi
