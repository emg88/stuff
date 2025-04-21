Tor Repository Update Script

This script automates the process of resolving GPG errors and securely updating the Tor repository to the latest version. It ensures a smooth installation of Tor for relay configuration while running under root privileges.
Features:

    Adds the missing public key required to authenticate the Tor repository.

    Configures the Tor Project's repository securely in /etc/apt/sources.list.d/tor.list.

    Updates the package list to reflect the latest repository changes.

    Installs the latest stable version of Tor.

    Verifies the installation by checking the Tor version.

Usage:

    Save the script as update_tor.sh.

    Grant execution permission:
    bash
