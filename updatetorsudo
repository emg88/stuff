#!/bin/bash

# Define custom directories in the user's home folder
KEYRING_DIR="$HOME/.tor_keyring"
TOR_LIST_DIR="$HOME/.tor_sources"
TOR_LIST="$TOR_LIST_DIR/tor.list"

# Create directories if they don't exist
mkdir -p "$KEYRING_DIR" "$TOR_LIST_DIR"

# Add the Tor Project's public key
echo "Adding the Tor Project's public key..."
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor > "$KEYRING_DIR/tor-archive-keyring.gpg"

# Configure the Tor repository (local-only sources.list)
echo "Configuring the Tor repository..."
echo "deb [signed-by=$KEYRING_DIR/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org bookworm main" > "$TOR_LIST"

# Use an APT cache directory in the user's home folder
export APT_CONFIG="$HOME/.apt_config"
export APT_OPTIONS="Dir::Etc::sourcelist=$TOR_LIST Dir::Etc::sourceparts=- Dir::Cache::Archives=$HOME/.apt_cache/archives Dir::State::lists=$HOME/.apt_cache/lists"

# Update the package list
echo "Updating the package list..."
apt update $APT_OPTIONS

# Install Tor (downloads and unpacks locally)
echo "Installing the latest version of Tor..."
apt install -y --no-install-recommends tor $APT_OPTIONS

# Verify the installation
echo "Verifying the installed Tor version..."
tor_version=$(tor --version 2>/dev/null
