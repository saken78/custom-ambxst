#!/bin/bash

# Script Setup TLP NOPASSWD
# Tujuan: Setup TLP agar tidak perlu password berulang kali
# Jalankan dengan: sudo bash setup-tlp-nopasswd.sh

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         TLP NOPASSWD SETUP SCRIPT                              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Script harus dijalankan dengan sudo!"
   echo "   Jalankan: sudo bash setup-tlp-nopasswd.sh"
   exit 1
fi

# Get current user (the one who ran sudo)
CURRENT_USER="${SUDO_USER:-$(whoami)}"

if [[ $CURRENT_USER == "root" ]]; then
    echo "❌ Jangan jalankan dari root user langsung!"
    echo "   Gunakan: sudo bash setup-tlp-nopasswd.sh"
    exit 1
fi

echo "ℹ️  Detected user: $CURRENT_USER"
echo ""

# Check if tlp is installed
if ! command -v tlp &> /dev/null; then
    echo "❌ TLP belum terinstall!"
    echo ""
    echo "Install dengan: sudo pacman -S tlp"
    exit 1
fi

echo "✓ TLP sudah terinstall"
echo "  Version: $(tlp --version | head -1)"
echo ""

# power-profiles-daemon and TLP conflict over the power profiles interface
if systemctl is-active --quiet power-profiles-daemon 2>/dev/null; then
    echo "⚠️  power-profiles-daemon sedang aktif dan berkonflik dengan TLP!"
    echo "   Nonaktifkan dulu:"
    echo "     sudo systemctl disable --now power-profiles-daemon"
    echo "   (Ambxst memakai power-profiles-daemon secara default)"
    exit 1
fi

# Create sudoers file
SUDOERS_FILE="/etc/sudoers.d/tlp-${CURRENT_USER}-nopasswd"

echo "📝 Membuat file sudoers: $SUDOERS_FILE"
echo ""

cat > "$SUDOERS_FILE" << EOF
# Allow $CURRENT_USER to run TLP commands without password
# Created by setup-tlp-nopasswd.sh on $(date)
${CURRENT_USER} ALL=(ALL) NOPASSWD: /usr/bin/tlp, /usr/bin/tlp-stat

EOF

# Set proper permissions
chmod 440 "$SUDOERS_FILE"

echo "✓ File sudoers berhasil dibuat"
echo "  Path: $SUDOERS_FILE"
echo "  Permissions: 440"
echo ""

# Validate sudoers file
echo "🔍 Validating sudoers file..."
if visudo -c -f "$SUDOERS_FILE" &> /dev/null; then
    echo "✓ Sudoers file valid"
else
    echo "❌ Sudoers file invalid! Menghapus..."
    rm -f "$SUDOERS_FILE"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    SETUP BERHASIL! ✓                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Sekarang user '$CURRENT_USER' bisa menjalankan:"
echo "  • sudo tlp performance      (tanpa password)"
echo "  • sudo tlp balanced         (tanpa password)"
echo "  • sudo tlp power-saver      (tanpa password)"
echo "  • sudo tlp-stat             (tanpa password)"
echo ""
echo "Testing:"
echo "  $ sudo tlp --version"
echo "  (Seharusnya tidak diminta password)"
echo ""
echo "Keterangan:"
echo "  • Hanya user '$CURRENT_USER' yang bisa run tanpa password"
echo "  • User lain masih perlu password"
echo "  • Sangat aman karena terbatas pada command TLP saja"
echo ""
