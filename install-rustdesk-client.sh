#!/bin/bash

# RustDesk Client Installation Script with Interactive Configuration
# This script installs RustDesk on Linux servers and configures them to use your custom RustDesk Server
# Usage: curl -fsSL https://raw.githubusercontent.com/your-username/rustdesk-installer/main/install-rustdesk-client.sh | sudo bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

header() {
    echo -e "${CYAN}$1${NC}"
}

# Display banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "=================================================="
    echo "          RustDesk Client Installer"
    echo "=================================================="
    echo -e "${NC}"
    echo "This script will install RustDesk and configure it"
    echo "to use your custom RustDesk Server."
    echo
}

# Get latest RustDesk version
get_latest_version() {
    log "Fetching latest RustDesk version..."
    RUSTDESK_VERSION=$(curl -s https://api.github.com/repos/rustdesk/rustdesk/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$RUSTDESK_VERSION" ]]; then
        warn "Could not fetch latest version, using fallback version 1.2.3"
        RUSTDESK_VERSION="1.2.3"
    else
        info "Latest RustDesk version: $RUSTDESK_VERSION"
    fi
}

# Prompt for server configuration
get_server_config() {
    header "Server Configuration"
    echo "Please provide your RustDesk server details:"
    echo

    # ID/Rendezvous Server
    while true; do
        read -p "Enter ID Server (e.g., 192.168.1.100:21116): " RUSTDESK_SERVER
        if [[ -n "$RUSTDESK_SERVER" ]]; then
            # Validate format (basic check)
            if [[ $RUSTDESK_SERVER =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]] || [[ $RUSTDESK_SERVER =~ ^[a-zA-Z0-9.-]+:[0-9]+$ ]]; then
                break
            else
                error "Please enter a valid format (IP:PORT or DOMAIN:PORT)"
            fi
        else
            error "ID Server cannot be empty"
        fi
    done

    # Relay Server
    while true; do
        read -p "Enter Relay Server (e.g., 192.168.1.100:21117): " RUSTDESK_RELAY
        if [[ -n "$RUSTDESK_RELAY" ]]; then
            if [[ $RUSTDESK_RELAY =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]] || [[ $RUSTDESK_RELAY =~ ^[a-zA-Z0-9.-]+:[0-9]+$ ]]; then
                break
            else
                error "Please enter a valid format (IP:PORT or DOMAIN:PORT)"
            fi
        else
            error "Relay Server cannot be empty"
        fi
    done

    # API Server
    while true; do
        read -p "Enter API Server (e.g., http://192.168.1.100:21114): " RUSTDESK_API
        if [[ -n "$RUSTDESK_API" ]]; then
            if [[ $RUSTDESK_API =~ ^https?://[a-zA-Z0-9.-]+:[0-9]+$ ]] || [[ $RUSTDESK_API =~ ^https?://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
                break
            else
                error "Please enter a valid URL format (http://IP:PORT or http://DOMAIN:PORT)"
            fi
        else
            error "API Server cannot be empty"
        fi
    done

    # Server Key
    while true; do
        read -p "Enter Server Key (public key from your RustDesk server): " RUSTDESK_KEY
        if [[ -n "$RUSTDESK_KEY" ]]; then
            if [[ ${#RUSTDESK_KEY} -ge 20 ]]; then
                break
            else
                error "Server key seems too short. Please check and try again."
            fi
        else
            error "Server Key cannot be empty"
        fi
    done

    echo
    header "Configuration Summary:"
    info "ID Server: $RUSTDESK_SERVER"
    info "Relay Server: $RUSTDESK_RELAY"
    info "API Server: $RUSTDESK_API"
    info "Server Key: ${RUSTDESK_KEY:0:10}..." # Show only first 10 chars for security
    echo

    read -p "Is this configuration correct? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Configuration cancelled. Please run the script again."
        exit 1
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        error "Cannot detect Linux distribution"
        exit 1
    fi
    
    log "Detected distribution: $DISTRO $VERSION"
}

# Install dependencies
install_dependencies() {
    log "Installing dependencies..."
    
    case $DISTRO in
        ubuntu|debian)
            apt-get update -qq
            apt-get install -y wget curl systemd ca-certificates >/dev/null 2>&1
            ;;
        centos|rhel|rocky|almalinux)
            if command -v dnf >/dev/null 2>&1; then
                dnf update -y -q
                dnf install -y wget curl systemd ca-certificates >/dev/null 2>&1
            else
                yum update -y -q
                yum install -y wget curl systemd ca-certificates >/dev/null 2>&1
            fi
            ;;
        fedora)
            dnf update -y -q
            dnf install -y wget curl systemd ca-certificates >/dev/null 2>&1
            ;;
        *)
            warn "Unsupported distribution: $DISTRO. Proceeding anyway..."
            ;;
    esac
}

# Download and install RustDesk
install_rustdesk() {
    log "Downloading and installing RustDesk..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Determine architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            RUSTDESK_ARCH="x86_64"
            ;;
        aarch64|arm64)
            RUSTDESK_ARCH="aarch64"
            ;;
        *)
            error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    # Download RustDesk based on distribution
    case $DISTRO in
        ubuntu|debian)
            PACKAGE_URL="https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-${RUSTDESK_ARCH}.deb"
            info "Downloading RustDesk package: $PACKAGE_URL"
            if ! wget -q "$PACKAGE_URL" -O rustdesk.deb; then
                error "Failed to download RustDesk package"
                exit 1
            fi
            info "Installing RustDesk..."
            dpkg -i rustdesk.deb >/dev/null 2>&1 || apt-get install -f -y >/dev/null 2>&1
            ;;
        centos|rhel|rocky|almalinux|fedora)
            PACKAGE_URL="https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-${RUSTDESK_ARCH}.rpm"
            info "Downloading RustDesk package: $PACKAGE_URL"
            if ! wget -q "$PACKAGE_URL" -O rustdesk.rpm; then
                error "Failed to download RustDesk package"
                exit 1
            fi
            info "Installing RustDesk..."
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y rustdesk.rpm >/dev/null 2>&1
            else
                rpm -ivh rustdesk.rpm >/dev/null 2>&1 || yum install -y rustdesk.rpm >/dev/null 2>&1
            fi
            ;;
        *)
            # Generic installation - download AppImage
            PACKAGE_URL="https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-${RUSTDESK_ARCH}.AppImage"
            info "Downloading RustDesk AppImage: $PACKAGE_URL"
            if ! wget -q "$PACKAGE_URL" -O /usr/local/bin/rustdesk; then
                error "Failed to download RustDesk AppImage"
                exit 1
            fi
            chmod +x /usr/local/bin/rustdesk
            ;;
    esac
    
    # Cleanup
    cd /
    rm -rf "$TEMP_DIR"
    
    log "RustDesk installation completed"
}

# Find RustDesk binary path
find_rustdesk_binary() {
    RUSTDESK_BINARY=""
    
    # Common locations
    for path in "/usr/bin/rustdesk" "/usr/local/bin/rustdesk" "/opt/rustdesk/rustdesk"; do
        if [ -x "$path" ]; then
            RUSTDESK_BINARY="$path"
            break
        fi
    done
    
    # If not found in common locations, search
    if [ -z "$RUSTDESK_BINARY" ]; then
        RUSTDESK_BINARY=$(which rustdesk 2>/dev/null || find / -name rustdesk -type f -executable 2>/dev/null | head -1)
    fi
    
    if [ -z "$RUSTDESK_BINARY" ]; then
        error "RustDesk binary not found"
        exit 1
    fi
    
    info "RustDesk binary found at: $RUSTDESK_BINARY"
}

# Configure RustDesk to use custom server
configure_rustdesk() {
    log "Configuring RustDesk to use custom server..."
    
    # Create RustDesk config directory
    mkdir -p /root/.config/rustdesk
    
    # Create configuration file
    cat > /root/.config/rustdesk/RustDesk2.toml << EOL
[options]
custom-rendezvous-server = '$RUSTDESK_SERVER'
relay-server = '$RUSTDESK_RELAY'
api-server = '$RUSTDESK_API'
key = '$RUSTDESK_KEY'

[display]
allow-always-software-render = false
allow-auto-reconnect = true

[security] 
allow-remote-config-modification = false
approve-mode = 'click'
EOL

    # Also create config for regular users (if any)
    if [ -d /home ]; then
        for user_home in /home/*; do
            if [ -d "$user_home" ]; then
                user_name=$(basename "$user_home")
                mkdir -p "$user_home/.config/rustdesk"
                cp /root/.config/rustdesk/RustDesk2.toml "$user_home/.config/rustdesk/" 2>/dev/null || true
                chown -R "$user_name:$user_name" "$user_home/.config/rustdesk" 2>/dev/null || true
            fi
        done
    fi
    
    log "RustDesk configuration completed"
}

# Create systemd service for RustDesk daemon
create_service() {
    log "Creating RustDesk systemd service..."
    
    find_rustdesk_binary
    
    cat > /etc/systemd/system/rustdesk.service << EOL
[Unit]
Description=RustDesk remote desktop service
After=network.target

[Service]
Type=forking
LimitNOFILE=1000000
ExecStart=$RUSTDESK_BINARY --service
TimeoutStopSec=5
KillMode=mixed
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOL

    # Enable and start the service
    systemctl daemon-reload >/dev/null 2>&1
    systemctl enable rustdesk >/dev/null 2>&1
    systemctl start rustdesk >/dev/null 2>&1
    
    log "RustDesk service created and started"
}

# Configure firewall (if needed)
configure_firewall() {
    log "Checking firewall configuration..."
    
    # Extract IP from server configuration
    SERVER_IP=$(echo $RUSTDESK_SERVER | cut -d':' -f1)
    
    # Check if UFW is active
    if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
        info "UFW firewall detected. Adding RustDesk rules..."
        ufw allow from $SERVER_IP >/dev/null 2>&1 || true
    fi
    
    # Check if firewalld is active
    if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active firewalld >/dev/null 2>&1; then
        info "firewalld detected. Adding RustDesk rules..."
        firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$SERVER_IP' accept" >/dev/null 2>&1 || true
        firewall-cmd --reload >/dev/null 2>&1 || true
    fi
}

# Verify installation
verify_installation() {
    log "Verifying installation..."
    
    # Check if RustDesk is installed
    if command -v rustdesk >/dev/null 2>&1; then
        info "✓ RustDesk binary found"
    else
        error "✗ RustDesk binary not found"
        return 1
    fi
    
    # Check if service is running
    if systemctl is-active rustdesk >/dev/null 2>&1; then
        info "✓ RustDesk service is running"
    else
        warn "✗ RustDesk service is not running - attempting to start..."
        systemctl start rustdesk >/dev/null 2>&1 || warn "Failed to start service"
    fi
    
    # Check if config file exists
    if [ -f /root/.config/rustdesk/RustDesk2.toml ]; then
        info "✓ Configuration file created"
    else
        error "✗ Configuration file missing"
        return 1
    fi
    
    # Display RustDesk ID if available
    sleep 5
    info "Retrieving RustDesk ID..."
    if command -v rustdesk >/dev/null 2>&1; then
        RUSTDESK_ID=$(timeout 15 rustdesk --get-id 2>/dev/null || echo "Not available yet - service may still be starting")
        info "RustDesk ID: $RUSTDESK_ID"
    fi
}

# Show final instructions
show_instructions() {
    log "Installation completed successfully!"
    echo
    header "================================================"
    header "          RustDesk Installation Complete"
    header "================================================"
    echo
    info "Server Configuration:"
    info "  • ID/Rendezvous Server: $RUSTDESK_SERVER"
    info "  • Relay Server: $RUSTDESK_RELAY"
    info "  • API Server: $RUSTDESK_API"
    info "  • Server Key: Configured"
    echo
    info "Service Management:"
    info "  • Start:   systemctl start rustdesk"
    info "  • Stop:    systemctl stop rustdesk"
    info "  • Status:  systemctl status rustdesk"
    info "  • Logs:    journalctl -u rustdesk -f"
    echo
    info "Configuration File:"
    info "  • Location: /root/.config/rustdesk/RustDesk2.toml"
    echo
    info "Get RustDesk ID:"
    info "  • Command: rustdesk --get-id"
    echo
    info "Next Steps:"
    info "  1. The RustDesk service should be running automatically"
    info "  2. Check your RustDesk Server web console"
    info "  3. The server should appear in your directory shortly"
    echo
    warn "Note: It may take a few moments for the server to appear in the directory"
    echo
}

# Main execution
main() {
    show_banner
    check_root
    get_latest_version
    get_server_config
    detect_distro
    install_dependencies
    install_rustdesk
    configure_rustdesk
    create_service
    configure_firewall
    verify_installation
    show_instructions
    
    log "Script execution completed!"
}

# Check if running interactively
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Running directly
    main "$@"
fi
