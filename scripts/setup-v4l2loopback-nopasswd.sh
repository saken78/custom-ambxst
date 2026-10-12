#!/bin/bash

# Script Setup v4l2loopback NOPASSWD
# sudo bash setup-v4l2loopback-nopasswd.sh

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║       V4L2LOOPBACK NOPASSWD SETUP SCRIPT                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo "Script harus dijalankan dengan sudo!"
  echo "   Jalankan: sudo bash setup-v4l2loopback-nopasswd.sh"
  exit 1
fi

# Get current user (the one who ran sudo)
CURRENT_USER="${SUDO_USER:-$(whoami)}"

if [[ $CURRENT_USER == "root" ]]; then
  echo "Jangan jalankan dari root user langsung!"
  echo "   Gunakan: sudo bash setup-v4l2loopback-nopasswd.sh"
  exit 1
fi

echo "Detected user: $CURRENT_USER"
echo ""

# Check if v4l2loopback module is available
if ! modinfo v4l2loopback &>/dev/null; then
  echo "Kernel module v4l2loopback tidak ditemukan!"
  echo ""
  echo "Install dengan: sudo pacman -S v4l2loopback-dkms"
  exit 1
fi

echo "✓ v4l2loopback module tersedia"
echo ""

MODPROBE_BIN="$(command -v modprobe)"

# Create sudoers file (only modprobe for v4l2loopback, nothing else)
SUDOERS_FILE="/etc/sudoers.d/v4l2loopback-${CURRENT_USER}-nopasswd"

echo "Membuat file sudoers: $SUDOERS_FILE"
echo ""

cat >"$SUDOERS_FILE" <<EOF
# Allow $CURRENT_USER to (un)load v4l2loopback without password
# (used by ambxst Android Webcam widget — no password is stored anywhere)
# Created by setup-v4l2loopback-nopasswd.sh on $(date)
${CURRENT_USER} ALL=(ALL) NOPASSWD: ${MODPROBE_BIN} v4l2loopback *, ${MODPROBE_BIN} -r v4l2loopback

EOF

# Set proper permissions
chmod 440 "$SUDOERS_FILE"

echo "✓ File sudoers berhasil dibuat"
echo "  Path: $SUDOERS_FILE"
echo "  Permissions: 440"
echo ""

# Validate sudoers file
echo "🔍 Validating sudoers file..."
if visudo -c -f "$SUDOERS_FILE" &>/dev/null; then
  echo "✓ Sudoers file valid"
else
  echo "Sudoers file invalid! Menghapus..."
  rm -f "$SUDOERS_FILE"
  exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    SETUP BERHASIL! ✓                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Testing (seharusnya tidak diminta password):"
echo "  $ sudo -n modprobe v4l2loopback video_nr=10 card_label=\"Android Webcam\" exclusive_caps=1"
echo ""
echo "Keterangan:"
echo "  • Hanya user '$CURRENT_USER' yang bisa run tanpa password"
echo "  • Terbatas pada perintah modprobe v4l2loopback saja"
echo ""
