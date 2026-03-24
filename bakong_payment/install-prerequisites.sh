#!/usr/bin/env bash
# ============================================================================
# Quick installation script - Install required packages
# ============================================================================

set -e

echo "Installing required packages..."
echo ""

# Detect OS
if command -v apt-get &> /dev/null; then
  # Ubuntu/Debian
  echo "Detected Debian/Ubuntu system"
  sudo apt-get update
  sudo apt-get install -y docker.io docker-compose nginx certbot python3-certbot-nginx
elif command -v dnf &> /dev/null; then
  # Fedora/RHEL
  echo "Detected Fedora/RHEL system"
  sudo dnf install -y docker docker-compose nginx certbot python3-certbot-nginx
elif command -v pacman &> /dev/null; then
  # Arch
  echo "Detected Arch system"
  sudo pacman -S --noconfirm docker docker-compose nginx certbot
else
  echo "Unsupported OS. Please install manually:"
  echo "  - Docker"
  echo "  - Docker Compose"
  echo "  - Nginx"
  echo "  - Certbot"
  exit 1
fi

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

echo ""
echo "✓ All packages installed successfully"
echo ""
echo "Next: Run sudo bash /home/rayu/das-tern/bakong_payment/deploy.sh"
