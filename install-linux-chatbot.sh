#!/bin/bash

# Linux ChatBot Installation Script
# Downloads from GitHub and installs automatically
# Repository: https://github.com/techconvergenceDev/Linux-ChatBot.git
# Author: TechConvergence Dev Team
# Web : https://techconvergence.dev
# Version: 1.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
GITHUB_REPO="https://github.com/techconvergenceDev/Linux-ChatBot.git"
INSTALL_DIR="/opt/linux-chatbot"
SERVICE_PORT="3000"
AGENT_PORT="8080"
DEFAULT_PASSWORD="admin123"
OLLAMA_MODEL="qwen2.5:latest"
TEMP_DIR="/tmp/linux-chatbot-install"

# Print functions
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    LINUX CHATBOT SYSTEM                     ║"
    echo "║              AI-Powered Server Management                    ║"
    echo "║                                                              ║"
    echo "║  🤖 Downloads from GitHub Repository                        ║"
    echo "║  🎨 Modern Dashboard Interface                              ║"
    echo "║  📊 Real-time Server Monitoring                             ║"
    echo "║  🔧 Automatic Agent Deployment                              ║"
    echo "║  💬 Natural Language Commands                               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${GREEN}Repository: ${GITHUB_REPO}${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_progress() {
    echo -e "${PURPLE}[PROGRESS]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        echo "Please run: sudo $0"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    print_step "Checking system requirements..."
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine OS version"
        exit 1
    fi
    
    . /etc/os-release
    print_status "Detected OS: $PRETTY_NAME"
    
    if [[ "$ID" != "ubuntu" ]] && [[ "$ID" != "debian" ]]; then
        print_warning "This script is optimized for Ubuntu/Debian. Proceeding anyway..."
    fi
    
    # Check available space (5GB minimum)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 5000000 ]]; then
        print_error "Insufficient disk space. At least 5GB required."
        exit 1
    fi
    
    # Check memory (2GB recommended)
    total_mem=$(free -m | awk 'NR==2{print $2}')
    if [[ $total_mem -lt 2048 ]]; then
        print_warning "Less than 2GB RAM detected. Performance may be affected."
    fi
    
    # Check internet connectivity
    if ! ping -c 1 github.com &> /dev/null; then
        print_error "No internet connection. Cannot download from GitHub."
        exit 1
    fi
    
    print_success "System requirements check passed"
}

# Install system dependencies
install_dependencies() {
    print_step "Installing system dependencies..."
    
    # Update system
    print_progress "Updating package lists..."
    export DEBIAN_FRONTEND=noninteractive
    apt update -qq
    
    print_progress "Installing essential packages..."
    apt install -y -qq \
        curl wget git build-essential \
        python3 python3-pip python3-venv \
        nginx sqlite3 \
        openssh-client sshpass \
        htop iotop nethogs \
        ufw fail2ban \
        jq unzip software-properties-common \
        ca-certificates gnupg lsb-release \
        supervisor
    
    # Install Node.js 18.x (LTS)
    print_progress "Installing Node.js 18.x LTS..."
    if ! command -v node &> /dev/null || [[ $(node --version | cut -d'v' -f2 | cut -d'.' -f1) -lt 18 ]]; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt install -y nodejs
    else
        print_status "Node.js 18+ already installed"
    fi
    
    # Verify Node.js installation
    node_version=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1 || echo "0")
    if [[ $node_version -lt 18 ]]; then
        print_error "Failed to install Node.js 18+"
        exit 1
    fi
    
    print_success "Dependencies installed successfully"
    print_status "Node.js version: $(node --version)"
    print_status "npm version: $(npm --version)"
}

# Download from GitHub
download_from_github() {
    print_step "Downloading Linux ChatBot from GitHub..."
    
    # Clean up any existing temp directory
    rm -rf $TEMP_DIR
    mkdir -p $TEMP_DIR
    
    print_progress "Cloning repository: $GITHUB_REPO"
    
    # Clone the repository with retry logic
    max_attempts=3
    attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        print_progress "Clone attempt $attempt/$max_attempts..."
        
        if git clone $GITHUB_REPO $TEMP_DIR; then
            print_success "Repository cloned successfully"
            break
        else
            print_warning "Clone attempt $attempt failed"
            
            if [[ $attempt -eq $max_attempts ]]; then
                print_error "Failed to clone repository after $max_attempts attempts"
                print_error "Please check:"
                echo "  1. Repository URL is correct: $GITHUB_REPO"
                echo "  2. Repository exists and is accessible"
                echo "  3. Internet connection is stable"
                exit 1
            fi
            
            ((attempt++))
            sleep 5
        fi
    done
    
    # Verify essential files exist
    if [[ ! -d "$TEMP_DIR" ]] || [[ -z "$(ls -A $TEMP_DIR)" ]]; then
        print_error "Repository appears to be empty or download failed"
        exit 1
    fi
    
    print_status "Repository contents:"
    ls -la $TEMP_DIR
    
    print_success "Files downloaded and verified"
}

# Install Ollama and AI model
install_ollama() {
    print_step "Installing Ollama and AI model..."
    
    # Install Ollama
    if ! command -v ollama &> /dev/null; then
        print_progress "Downloading and installing Ollama..."
        curl -fsSL https://ollama.ai/install.sh | sh
        
        # Wait for installation to complete
        sleep 5
    else
        print_status "Ollama is already installed"
    fi
    
    # Configure Ollama service
    print_progress "Configuring Ollama service..."
    systemctl enable ollama 2>/dev/null || true
    systemctl start ollama 2>/dev/null || true
    
    # Wait for Ollama to start
    print_progress "Waiting for Ollama to initialize..."
    max_attempts=24
    attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
            print_success "Ollama is running"
            break
        fi
        print_progress "Waiting for Ollama... (attempt $attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    if [[ $attempt -gt $max_attempts ]]; then
        print_warning "Ollama may not be fully ready, but continuing installation"
    fi
    
    # Pull Qwen model
    print_progress "Downloading Qwen model (this may take several minutes)..."
    if ollama pull $OLLAMA_MODEL; then
        print_success "Qwen model downloaded successfully"
    else
        print_warning "Model download failed, but continuing installation"
    fi
    
    print_success "Ollama installation completed"
}

# Setup project structure
setup_project_structure() {
    print_step "Setting up project structure..."
    
    # Create main installation directory
    mkdir -p $INSTALL_DIR
    
    # Copy all files from GitHub download
    print_progress "Copying files from repository..."
    cp -r $TEMP_DIR/* $INSTALL_DIR/
    
    # Create additional directories if they don't exist
    mkdir -p $INSTALL_DIR/{data,logs,backups,config}
    
    # Set permissions
    chown -R root:root $INSTALL_DIR
    chmod -R 755 $INSTALL_DIR
    
    # Make scripts executable
    find $INSTALL_DIR -name "*.sh" -exec chmod +x {} \;
    
    # Create configuration file
    print_progress "Creating configuration file..."
    cat > $INSTALL_DIR/config/config.json << EOF
{
    "version": "1.0.0",
    "installation_date": "$(date -Iseconds)",
    "installation_method": "github",
    "repository": "$GITHUB_REPO",
    "ollama_model": "$OLLAMA_MODEL",
    "ollama_url": "http://localhost:11434",
    "dashboard_port": $SERVICE_PORT,
    "agent_port": $AGENT_PORT,
    "default_password": "$DEFAULT_PASSWORD",
    "jwt_secret": "$(openssl rand -base64 32)",
    "monitoring_interval": 30,
    "alert_thresholds": {
        "cpu": 80,
        "memory": 85,
        "disk": 90
    }
}
EOF
    
    print_success "Project structure created"
    print_status "Installation directory: $INSTALL_DIR"
}

# Install Node.js dependencies
install_node_dependencies() {
    print_step "Installing Node.js dependencies..."
    
    # Find the main application directory
    if [[ -f "$INSTALL_DIR/package.json" ]]; then
        APP_DIR="$INSTALL_DIR"
    elif [[ -f "$INSTALL_DIR/dashboard/package.json" ]]; then
        APP_DIR="$INSTALL_DIR/dashboard"
    elif [[ -f "$INSTALL_DIR/app/package.json" ]]; then
        APP_DIR="$INSTALL_DIR/app"
    else
        print_warning "No package.json found. Creating basic structure..."
        APP_DIR="$INSTALL_DIR"
        
        # Create basic package.json if it doesn't exist
        cat > $APP_DIR/package.json << EOF
{
    "name": "linux-chatbot",
    "version": "1.0.0",
    "description": "AI-powered Linux server management system",
    "main": "app.js",
    "scripts": {
        "start": "node app.js",
        "dev": "nodemon app.js"
    },
    "dependencies": {
        "express": "^4.18.2",
        "sqlite3": "^5.1.6",
        "bcryptjs": "^2.4.3",
        "express-session": "^1.17.3",
        "ejs": "^3.1.9",
        "socket.io": "^4.7.2",
        "axios": "^1.5.0"
    }
}
EOF
    fi
    
    cd $APP_DIR
    
    # Configure npm
    print_progress "Configuring npm..."
    npm config set registry https://registry.npmjs.org/
    npm config set fetch-retry-mintimeout 20000
    npm config set fetch-retry-maxtimeout 120000
    npm config set fetch-retries 5
    npm config set audit false
    npm config set fund false
    
    # Clean npm cache
    npm cache clean --force 2>/dev/null || true
    
    # Install dependencies with retry logic
    print_progress "Installing dependencies..."
    max_attempts=3
    attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        print_progress "Installation attempt $attempt/$max_attempts..."
        
        if npm install --no-audit --no-fund --prefer-offline --legacy-peer-deps; then
            print_success "Dependencies installed successfully"
            break
        else
            print_warning "Installation attempt $attempt failed"
            
            if [[ $attempt -eq $max_attempts ]]; then
                print_warning "Trying individual package installation..."
                
                # Install critical packages individually
                local packages=(
                    "express@4.18.2"
                    "sqlite3@5.1.6"
                    "bcryptjs@2.4.3"
                    "express-session@1.17.3"
                    "ejs@3.1.9"
                    "socket.io@4.7.2"
                    "axios@1.5.0"
                )
                
                for package in "${packages[@]}"; do
                    print_progress "Installing $package..."
                    npm install "$package" --save --no-audit --no-fund || {
                        print_warning "Failed to install $package, trying with --force..."
                        npm install "$package" --save --force || true
                    }
                done
            fi
            
            ((attempt++))
            sleep 5
            npm cache clean --force 2>/dev/null || true
        fi
    done
    
    print_success "Node.js dependencies installation completed"
}

# Create systemd service
create_systemd_service() {
    print_step "Creating systemd service..."
    
    # Find the main app file
    if [[ -f "$INSTALL_DIR/app.js" ]]; then
        APP_FILE="app.js"
        WORK_DIR="$INSTALL_DIR"
    elif [[ -f "$INSTALL_DIR/dashboard/app.js" ]]; then
        APP_FILE="app.js"
        WORK_DIR="$INSTALL_DIR/dashboard"
    elif [[ -f "$INSTALL_DIR/server.js" ]]; then
        APP_FILE="server.js"
        WORK_DIR="$INSTALL_DIR"
    elif [[ -f "$INSTALL_DIR/index.js" ]]; then
        APP_FILE="index.js"
        WORK_DIR="$INSTALL_DIR"
    else
        print_warning "No main app file found. Using default app.js"
        APP_FILE="app.js"
        WORK_DIR="$INSTALL_DIR"
    fi
    
    cat > /etc/systemd/system/linux-chatbot.service << EOF
[Unit]
Description=Linux ChatBot AI Management System
Documentation=Linux ChatBot AI-powered server management
After=network.target ollama.service
Wants=ollama.service

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$WORK_DIR
Environment=NODE_ENV=production
Environment=PORT=$SERVICE_PORT
ExecStart=/usr/bin/node $APP_FILE
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=linux-chatbot

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable linux-chatbot
    
    print_success "Systemd service created and enabled"
}

# Configure Nginx reverse proxy
configure_nginx() {
    print_step "Configuring Nginx reverse proxy..."
    
    # Remove default site
    rm -f /etc/nginx/sites-enabled/default
    
    # Create Linux ChatBot site
    cat > /etc/nginx/sites-available/linux-chatbot << EOF
server {
    listen 80;
    listen [::]:80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;
    
    # Main application
    location / {
        proxy_pass http://localhost:$SERVICE_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
    }
    
    # Socket.IO support
    location /socket.io/ {
        proxy_pass http://localhost:$SERVICE_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # API endpoints
    location /api/ {
        proxy_pass http://localhost:$SERVICE_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri @proxy;
    }
    
    location @proxy {
        proxy_pass http://localhost:$SERVICE_PORT;
    }
    
    # Security
    location ~ /\. {
        deny all;
    }
    
    # Logs
    access_log /var/log/nginx/linux-chatbot.access.log;
    error_log /var/log/nginx/linux-chatbot.error.log;
}
EOF

    # Enable site
    ln -sf /etc/nginx/sites-available/linux-chatbot /etc/nginx/sites-enabled/
    
    # Test configuration
    if nginx -t; then
        systemctl restart nginx
        print_success "Nginx configured and restarted"
    else
        print_error "Nginx configuration test failed"
        exit 1
    fi
}

# Setup firewall
setup_firewall() {
    print_step "Configuring firewall..."
    
    # Configure UFW
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow essential services
    ufw allow ssh
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    ufw allow $SERVICE_PORT/tcp comment 'ChatBot Dashboard'
    
    # Allow Ollama (local only)
    ufw allow from 127.0.0.1 to any port 11434 comment 'Ollama Local'
    
    # Enable firewall
    ufw --force enable
    
    print_success "Firewall configured"
    ufw status
}

# Create management scripts
create_management_scripts() {
    print_step "Creating management scripts..."
    
    # Start script
    cat > $INSTALL_DIR/start.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting Linux ChatBot..."

# Start Ollama if not running
if ! pgrep -x "ollama" > /dev/null; then
    echo "🤖 Starting Ollama..."
    systemctl start ollama
    sleep 10
fi

# Start chatbot
echo "💬 Starting ChatBot dashboard..."
systemctl start linux-chatbot

# Check status
sleep 5
if systemctl is-active --quiet linux-chatbot; then
    echo "✅ Linux ChatBot started successfully!"
    echo "🌐 Dashboard: http://$(hostname -I | awk '{print $1}')"
    echo "👤 Default login: admin / admin123"
else
    echo "❌ Failed to start Linux ChatBot"
    echo "📋 Check logs: journalctl -u linux-chatbot -f"
    exit 1
fi
EOF

    # Stop script
    cat > $INSTALL_DIR/stop.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping Linux ChatBot..."
systemctl stop linux-chatbot
echo "✅ Linux ChatBot stopped"
EOF

    # Status script
    cat > $INSTALL_DIR/status.sh << 'EOF'
#!/bin/bash
echo "📊 Linux ChatBot Status"
echo "======================="
systemctl status linux-chatbot --no-pager -l
echo ""
echo "🤖 Ollama Status:"
systemctl status ollama --no-pager -l
echo ""
echo "🔗 Network Status:"
ss -tlnp | grep -E "(3000|11434)"
EOF

    # Update script
    cat > $INSTALL_DIR/update.sh << EOF
#!/bin/bash
echo "🔄 Updating Linux ChatBot from GitHub..."

# Stop service
systemctl stop linux-chatbot

# Backup current installation
backup_dir="/opt/linux-chatbot-backup-\$(date +%Y%m%d-%H%M%S)"
echo "📦 Creating backup at \$backup_dir"
cp -r $INSTALL_DIR \$backup_dir

# Download latest version
temp_dir="/tmp/linux-chatbot-update"
rm -rf \$temp_dir
git clone $GITHUB_REPO \$temp_dir

# Update files (preserve config and data)
echo "📁 Updating files..."
rsync -av --exclude='config/' --exclude='data/' --exclude='logs/' \$temp_dir/ $INSTALL_DIR/

# Update dependencies if package.json exists
if [[ -f "$INSTALL_DIR/package.json" ]]; then
    cd $INSTALL_DIR
    npm install --no-audit --no-fund
elif [[ -f "$INSTALL_DIR/dashboard/package.json" ]]; then
    cd $INSTALL_DIR/dashboard
    npm install --no-audit --no-fund
fi

# Restart service
systemctl start linux-chatbot

echo "✅ Update completed!"
echo "📦 Backup available at: \$backup_dir"
EOF

    # Logs script
    cat > $INSTALL_DIR/logs.sh << 'EOF'
#!/bin/bash
echo "📋 Linux ChatBot Logs"
echo "===================="
echo "Press Ctrl+C to exit"
echo ""
journalctl -u linux-chatbot -f
EOF

    # Make scripts executable
    chmod +x $INSTALL_DIR/*.sh
    
    # Create symlinks for easy access
    ln -sf $INSTALL_DIR/start.sh /usr/local/bin/chatbot-start
    ln -sf $INSTALL_DIR/stop.sh /usr/local/bin/chatbot-stop
    ln -sf $INSTALL_DIR/status.sh /usr/local/bin/chatbot-status
    ln -sf $INSTALL_DIR/update.sh /usr/local/bin/chatbot-update
    ln -sf $INSTALL_DIR/logs.sh /usr/local/bin/chatbot-logs
    
    print_success "Management scripts created"
    print_status "Available commands: chatbot-start, chatbot-stop, chatbot-status, chatbot-update, chatbot-logs"
}

# Start services
start_services() {
    print_step "Starting services..."
    
    # Start Ollama first
    print_progress "Starting Ollama..."
    systemctl start ollama
    sleep 15
    
    # Start chatbot
    print_progress "Starting Linux ChatBot..."
    systemctl start linux-chatbot
    sleep 10
    
    # Verify services
    if systemctl is-active --quiet ollama && systemctl is-active --quiet linux-chatbot; then
        print_success "All services started successfully"
    else
        print_warning "Some services may need more time to start"
        print_status "Check status with: chatbot-status"
        print_status "Check logs with: chatbot-logs"
    fi
}

# Cleanup temporary files
cleanup() {
    print_step "Cleaning up temporary files..."
    rm -rf $TEMP_DIR
    print_success "Cleanup completed"
}

# Display final summary
display_summary() {
    clear
    print_banner
    
    echo -e "${GREEN}"
    echo "🎉 Linux ChatBot Installation Complete!"
    echo "======================================"
    echo -e "${NC}"
    
    # Get server IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "${CYAN}📊 Access Information:${NC}"
    echo "   🌐 Dashboard URL: http://$SERVER_IP"
    echo "   👤 Username: admin"
    echo "   🔑 Password: $DEFAULT_PASSWORD"
    echo ""
    
    echo -e "${CYAN}🚀 Features Available:${NC}"
    echo "   💬 AI-powered chat interface"
    echo "   🎨 Modern dashboard design"
    echo "   📦 Automatic server management"
    echo "   🤖 Natural language commands"
    echo "   📊 Real-time monitoring"
    echo "   🔧 Agent deployment"
    echo ""
    
    echo -e "${CYAN}🔧 Management Commands:${NC}"
    echo "   🚀 Start: chatbot-start"
    echo "   🛑 Stop: chatbot-stop"
    echo "   📊 Status: chatbot-status"
    echo "   🔄 Update: chatbot-update"
    echo "   📋 Logs: chatbot-logs"
    echo ""
    
    echo -e "${CYAN}📦 Installation Details:${NC}"
    echo "   🔗 Repository: $GITHUB_REPO"
    echo "   📁 Installation: $INSTALL_DIR"
    echo "   🤖 AI Model: $OLLAMA_MODEL"
    echo "   🔌 Port: $SERVICE_PORT"
    echo ""
    
    echo -e "${YELLOW}⚠️ Important Notes:${NC}"
    echo "   🔒 Change the default password immediately!"
    echo "   ⚙️ Configure AI settings in the dashboard"
    echo "   🔄 Use 'chatbot-update' to get latest updates"
    echo "   📋 Check logs with 'chatbot-logs' if issues occur"
    echo ""
    
    echo -e "${GREEN}🎯 Installation Complete! Access your dashboard at http://$SERVER_IP${NC}"
    echo ""
}

# Main execution function
main() {
    print_banner
    
    check_root
    check_requirements
    install_dependencies
    download_from_github
    install_ollama
    setup_project_structure
    install_node_dependencies
    create_systemd_service
    configure_nginx
    setup_firewall
    create_management_scripts
    start_services
    cleanup
    
    display_summary
}

# Trap errors
trap 'print_error "Installation failed at line $LINENO. Check the logs for details."' ERR

# Run main function
main "$@"
