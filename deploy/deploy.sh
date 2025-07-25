#!/bin/bash

# Production Deployment Script for API2MD Converter
# Supports AWS EC2, Google Cloud, DigitalOcean, etc.

set -e

echo "🚀 Deploying API2MD Converter to Production"

# Configuration
APP_NAME="api2md-converter"
DEPLOY_USER="deploy"
SERVICE_PORT="8080"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "\n${BLUE}📍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root. Please run as a regular user with sudo access."
    exit 1
fi

print_step "Setting up production environment"

# Update system
sudo apt update && sudo apt upgrade -y

# Install required system packages
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    nginx \
    supervisor \
    git \
    curl \
    htop

print_success "System packages installed"

print_step "Creating deployment user and directories"

# Create deployment user if it doesn't exist
if ! id "$DEPLOY_USER" &>/dev/null; then
    sudo useradd -m -s /bin/bash $DEPLOY_USER
    sudo usermod -aG sudo $DEPLOY_USER
fi

# Create application directories
sudo mkdir -p /opt/$APP_NAME
sudo mkdir -p /var/log/$APP_NAME
sudo mkdir -p /var/run/$APP_NAME

# Set permissions
sudo chown -R $DEPLOY_USER:$DEPLOY_USER /opt/$APP_NAME
sudo chown -R $DEPLOY_USER:$DEPLOY_USER /var/log/$APP_NAME
sudo chown -R $DEPLOY_USER:$DEPLOY_USER /var/run/$APP_NAME

print_success "Deployment directories created"

print_step "Deploying application code"

# Copy application files
sudo -u $DEPLOY_USER cp -r . /opt/$APP_NAME/
cd /opt/$APP_NAME

# Setup virtual environment
sudo -u $DEPLOY_USER python3 -m venv venv
sudo -u $DEPLOY_USER bash -c "source venv/bin/activate && pip install -r requirements.txt"
sudo -u $DEPLOY_USER bash -c "source venv/bin/activate && playwright install chromium"

print_success "Application deployed"

print_step "Configuring systemd service"

# Create systemd service file
sudo tee /etc/systemd/system/$APP_NAME.service > /dev/null <<EOF
[Unit]
Description=API Documentation to Markdown Converter
After=network.target

[Service]
Type=simple
User=$DEPLOY_USER
Group=$DEPLOY_USER
WorkingDirectory=/opt/$APP_NAME
Environment=PATH=/opt/$APP_NAME/venv/bin
ExecStart=/opt/$APP_NAME/venv/bin/python api2md.py --urls /opt/$APP_NAME/input/urls.txt --output /opt/$APP_NAME/output
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$APP_NAME

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable $APP_NAME
print_success "Systemd service configured"

print_step "Setting up log rotation"

# Configure log rotation
sudo tee /etc/logrotate.d/$APP_NAME > /dev/null <<EOF
/var/log/$APP_NAME/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $DEPLOY_USER $DEPLOY_USER
    postrotate
        systemctl reload $APP_NAME
    endscript
}
EOF

print_success "Log rotation configured"

print_step "Setting up monitoring"

# Create monitoring script
sudo tee /opt/$APP_NAME/monitor.sh > /dev/null <<'EOF'
#!/bin/bash
# Basic monitoring for API2MD Converter

LOG_FILE="/var/log/api2md/monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Check if service is running
if systemctl is-active --quiet api2md-converter; then
    echo "$DATE - Service is running" >> $LOG_FILE
else
    echo "$DATE - Service is DOWN" >> $LOG_FILE
    systemctl restart api2md-converter
fi

# Check disk space
DISK_USAGE=$(df /opt/api2md-converter | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "$DATE - WARNING: Disk usage is ${DISK_USAGE}%" >> $LOG_FILE
fi
EOF

sudo chmod +x /opt/$APP_NAME/monitor.sh
sudo chown $DEPLOY_USER:$DEPLOY_USER /opt/$APP_NAME/monitor.sh

# Add monitoring to crontab
(sudo -u $DEPLOY_USER crontab -l 2>/dev/null; echo "*/5 * * * * /opt/$APP_NAME/monitor.sh") | sudo -u $DEPLOY_USER crontab -

print_success "Monitoring configured"

print_step "Configuring firewall"

# Configure UFW firewall
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow $SERVICE_PORT

print_success "Firewall configured"

print_step "Creating input/output directories"

# Create input and output directories
sudo -u $DEPLOY_USER mkdir -p /opt/$APP_NAME/input
sudo -u $DEPLOY_USER mkdir -p /opt/$APP_NAME/output

# Copy sample URLs file
sudo -u $DEPLOY_USER cp urls.txt /opt/$APP_NAME/input/

print_success "Directories created"

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "  - Application: /opt/$APP_NAME"
echo "  - Service: $APP_NAME"
echo "  - Logs: /var/log/$APP_NAME"
echo "  - Input: /opt/$APP_NAME/input"
echo "  - Output: /opt/$APP_NAME/output"
echo ""
echo "🔧 Management Commands:"
echo "  sudo systemctl start $APP_NAME      # Start service"
echo "  sudo systemctl stop $APP_NAME       # Stop service"
echo "  sudo systemctl status $APP_NAME     # Check status"
echo "  sudo journalctl -f -u $APP_NAME     # View logs"
echo ""
echo "📂 To process URLs:"
echo "  1. Add URLs to: /opt/$APP_NAME/input/urls.txt"
echo "  2. Run: sudo systemctl start $APP_NAME"
echo "  3. Check output: /opt/$APP_NAME/output/"
echo ""
print_success "Ready for production use!"