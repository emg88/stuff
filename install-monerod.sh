#!/usr/bin/env bash
# Monero node (monerod) installer for Debian/Ubuntu-style systems with systemd.
# Verifies the release via binaryFate's GPG signature + SHA256 before installing.
# Usage: sudo PRUNE=1 ./install-monerod.sh
#   PRUNE=1  -> pruned blockchain (~1/3 disk, ~100 GB). Default: full node.
set -euo pipefail

PRUNE="${PRUNE:-0}"
INSTALL_DIR="/opt/monero"
DATA_DIR="/var/lib/monero"
CONF="/etc/monerod.conf"
FPR="81AC591FE9C4B65C5806AFC3F0AF4D462A0BDF92"   # binaryFate signing key

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)." >&2; exit 1; }

case "$(uname -m)" in
  x86_64)  PLATFORM="linux-x64" ;;
  aarch64) PLATFORM="linux-armv8" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

apt-get update -qq
apt-get install -y -qq curl gnupg bzip2 ca-certificates

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

echo "==> Fetching signing key and hashes"
curl -fsSL https://raw.githubusercontent.com/monero-project/monero/master/utils/gpg_keys/binaryfate.asc -o binaryfate.asc
GNUPGHOME="$TMP/gnupg"; export GNUPGHOME
mkdir -m 700 "$GNUPGHOME"
gpg --batch --import binaryfate.asc 2>/dev/null
gpg --batch --fingerprint "$FPR" >/dev/null || { echo "Signing key fingerprint mismatch!" >&2; exit 1; }

curl -fsSL https://www.getmonero.org/downloads/hashes.txt -o hashes.txt
gpg --batch --verify hashes.txt || { echo "Bad signature on hashes.txt!" >&2; exit 1; }

FILE="$(grep -oE "monero-${PLATFORM}-v[0-9.]+\.tar\.bz2" hashes.txt | head -1)"
[[ -n "$FILE" ]] || { echo "Could not find $PLATFORM release in hashes.txt" >&2; exit 1; }
EXPECTED="$(grep -E "$FILE" hashes.txt | grep -oE '[a-f0-9]{64}' | head -1)"

echo "==> Downloading $FILE"
curl -fL "https://downloads.getmonero.org/cli/$FILE" -o "$FILE"
ACTUAL="$(sha256sum "$FILE" | cut -d' ' -f1)"
[[ "$ACTUAL" == "$EXPECTED" ]] || { echo "SHA256 mismatch!" >&2; exit 1; }
echo "    checksum OK"

echo "==> Installing to $INSTALL_DIR"
id monero &>/dev/null || useradd --system --home-dir "$DATA_DIR" --shell /usr/sbin/nologin monero
mkdir -p "$INSTALL_DIR" "$DATA_DIR"
tar -xjf "$FILE" -C "$INSTALL_DIR" --strip-components=1
chown -R monero:monero "$DATA_DIR"

echo "==> Writing $CONF"
cat > "$CONF" <<EOF
data-dir=$DATA_DIR
log-file=$DATA_DIR/monerod.log
log-level=0
max-log-file-size=0

# P2P (forward TCP 18080 on your router/firewall to help the network)
p2p-bind-ip=0.0.0.0
p2p-bind-port=18080
out-peers=32
in-peers=64

# RPC: restricted, local only. Wallets on this machine can use 127.0.0.1:18081
rpc-bind-ip=127.0.0.1
rpc-bind-port=18081
restricted-rpc=1
confirm-external-bind=0

no-igd=1
enable-dns-blocklist=1
$( [[ "$PRUNE" == "1" ]] && echo "prune-blockchain=1" )
EOF

echo "==> Creating systemd service"
cat > /etc/systemd/system/monerod.service <<EOF
[Unit]
Description=Monero Daemon
After=network-online.target
Wants=network-online.target

[Service]
User=monero
Group=monero
ExecStart=$INSTALL_DIR/monerod --config-file $CONF --non-interactive
Restart=on-failure
RestartSec=30
TimeoutStopSec=120
LimitNOFILE=65535
ProtectSystem=full
ProtectHome=true
PrivateTmp=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now monerod

if command -v ufw &>/dev/null; then
  ufw allow 18080/tcp comment "monerod p2p" || true
fi

cat <<EOF

Done. Monero node is syncing.
  Status:   systemctl status monerod
  Logs:     tail -f $DATA_DIR/monerod.log
  Sync info: curl -s http://127.0.0.1:18081/get_info | grep -E 'height|synchronized'
  Binaries: $INSTALL_DIR  (monerod, monero-wallet-cli, ...)
EOF
