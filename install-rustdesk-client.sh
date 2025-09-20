#!/bin/bash

# RustDesk Client Installation Script with Enhanced Configuration
# This script installs RustDesk with virtual display support and password configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default ports (standard RustDesk server ports)
DEFAULT_ID_PORT="21116"
DEFAULT_RELAY_PORT="21117"
DEFAULT_API_PORT="21114"

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
    echo "   RustDesk Client Installer (Enhanced)"
    echo "=================================================="
    echo -e "${NC}"
    echo "This script will install RustDesk and configure it"
    echo "to use your custom RustDesk Server."
    echo
}

# Check if running non-interactively
is_non_interactive() {
    # Check if stdin is not a terminal (piped input) or if running in CI/automated environment
    if [[ ! -t 0 ]] || [[ -n "$RUSTDESK_AUTO_INSTALL" ]] || [[ -n "$CI" ]] || [[ -n "$DEBIAN_FRONTEND" ]]; then
        return 0  # Non-interactive
    else
        return 1  # Interactive
    fi
}

# Check if system is headless
check_if_headless() {
    if [ -z "$DISPLAY" ] && ! pgrep -x "Xorg" > /dev/null && ! pgrep -x "X" > /dev/null; then
        return 0  # Headless
    else
        return 1  # Has display
    fi
}

# Ask about virtual display setup
ask_virtual_display() {
    if check_if_headless; then
        info "Headless server detected (no graphical display)"
        echo "RustDesk requires a display to function properly."
        echo
        
        if is_non_interactive; then
            info "Non-interactive mode detected - automatically enabling virtual display"
            SETUP_VIRTUAL_DISPLAY=true
        else
            while true; do
                read -p "Set up virtual display (Xvfb) for headless operation? (Y/n): " setup_virtual
                case $setup_virtual in
                    [Yy]* | "" )
                        SETUP_VIRTUAL_DISPLAY=true
                        break
                        ;;
                    [Nn]* )
                        SETUP_VIRTUAL_DISPLAY=false
                        warn "Proceeding without virtual display - RustDesk may not work properly"
                        break
                        ;;
                    * )
                        error "Please answer yes (y) or no (n)"
                        ;;
                esac
            done
        fi
    else
        info "Graphical display detected - virtual display not needed"
        SETUP_VIRTUAL_DISPLAY=false
    fi
}

# Get latest RustDesk version
get_latest_version() {
    log "Fetching latest RustDesk version..."
    RUSTDESK_VERSION=$(curl -s https://api.github.com/repos/rustdesk/rustdesk/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$RUSTDESK_VERSION" ]]; then
        warn "Could not fetch latest version, using fallback version 1.4.2"
        RUSTDESK_VERSION="1.4.2"
    else
        info "Latest RustDesk version: $RUSTDESK_VERSION"
    fi
}

# Test server connectivity
test_server_connectivity() {
    local server_ip=$1
    local port=$2
    local service_name=$3
    
    if timeout 5 bash -c "</dev/tcp/$server_ip/$port" 2>/dev/null; then
        info "✓ $service_name ($server_ip:$port) is reachable"
        return 0
    else
        warn "✗ $service_name ($server_ip:$port) is not reachable"
        return 1
    fi
}

# Automated simple server configuration for non-interactive mode
get_server_config_simple_auto() {
    header "Automated Server Configuration"
    echo "Using environment variables for server configuration"
    echo

    # Get server configuration from environment variables
    if [[ -n "$RUSTDESK_SERVER_HOST" ]]; then
        SERVER_HOST="$RUSTDESK_SERVER_HOST"
        info "Using server host from environment: $SERVER_HOST"
    else
        error "RUSTDESK_SERVER_HOST environment variable not set"
        echo "For non-interactive installation, please set:"
        echo "export RUSTDESK_SERVER_HOST='your.server.ip'"
        echo "export RUSTDESK_SERVER_KEY='your_server_public_key'"
        echo "export RUSTDESK_PASSWORD='your_desired_password'"
        exit 1
    fi

    # Auto-configure with standard ports
    RUSTDESK_SERVER="${SERVER_HOST}:${DEFAULT_ID_PORT}"
    RUSTDESK_RELAY="${SERVER_HOST}:${DEFAULT_RELAY_PORT}"
    RUSTDESK_API="http://${SERVER_HOST}:${DEFAULT_API_PORT}"

    # Get server key from environment
    if [[ -n "$RUSTDESK_SERVER_KEY" ]]; then
        RUSTDESK_KEY="$RUSTDESK_SERVER_KEY"
        info "Using server key from environment"
    else
        error "RUSTDESK_SERVER_KEY environment variable not set"
        exit 1
    fi

    # Test connectivity
    echo
    info "Testing server connectivity..."
    test_server_connectivity "$SERVER_HOST" "$DEFAULT_ID_PORT" "ID Server"
    test_server_connectivity "$SERVER_HOST" "$DEFAULT_RELAY_PORT" "Relay Server"
    test_server_connectivity "$SERVER_HOST" "$DEFAULT_API_PORT" "API Server"
    echo
}

# Simplified server configuration
get_server_config_simple() {
    header "Simplified Server Configuration"
    echo "Enter your RustDesk server details:"
    echo "This mode uses standard ports and auto-detects services."
    echo

    # Get server IP/hostname
    while true; do
        read -p "Enter your RustDesk server IP or hostname: " SERVER_HOST
        if [[ -n "$SERVER_HOST" ]]; then
            # Basic validation
            if [[ $SERVER_HOST =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ $SERVER_HOST =~ ^[a-zA-Z0-9.-]+$ ]]; then
                break
            else
                error "Please enter a valid IP address or hostname"
            fi
        else
            error "Server IP/hostname cannot be empty"
        fi
    done

    # Auto-configure with standard ports
    RUSTDESK_SERVER="${SERVER_HOST}:${DEFAULT_ID_PORT}"
    RUSTDESK_RELAY="${SERVER_HOST}:${DEFAULT_RELAY_PORT}"
    RUSTDESK_API="http://${SERVER_HOST}:${DEFAULT_API_PORT}"

    # Test connectivity
    echo
    info "Testing server connectivity..."
    test_server_connectivity "$SERVER_HOST" "$DEFAULT_ID_PORT" "ID Server"
    test_server_connectivity "$SERVER_HOST" "$DEFAULT_RELAY_PORT" "Relay Server"
    test_server_connectivity "$SERVER_HOST" "$DEFAULT_API_PORT" "API Server"
    echo

    # Get server key
    while true; do
        read -p "Enter your RustDesk server public key: " RUSTDESK_KEY
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
}

# Advanced server configuration
get_server_config_advanced() {
    header "Advanced Server Configuration"
    echo "Please provide your RustDesk server details with custom ports:"
    echo

    # ID/Rendezvous Server
    while true; do
        read -p "Enter ID Server (e.g., 192.168.1.100:21116): " RUSTDESK_SERVER
        if [[ -n "$RUSTDESK_SERVER" ]]; then
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
}

# Choose configuration method
choose_config_method() {
    echo
    header "Configuration Method"
    
    if is_non_interactive; then
        info "Non-interactive mode - using Simple configuration (standard ports)"
        get_server_config_simple_auto
    else
        echo "Choose how you want to configure your RustDesk client:"
        echo
        echo "1) Simple - Just enter your server IP (uses standard ports)"
        echo "2) Advanced - Specify custom ports and URLs"
        echo

        while true; do
            read -p "Choose option (1 or 2): " choice
            case $choice in
                1)
                    get_server_config_simple
                    break
                    ;;
                2)
                    get_server_config_advanced
                    break
                    ;;
                *)
                    error "Please enter 1 or 2"
                    ;;
            esac
        done
    fi

    echo
    header "Configuration Summary:"
    info "ID Server: $RUSTDESK_SERVER"
    info "Relay Server: $RUSTDESK_RELAY"
    info "API Server: $RUSTDESK_API"
    info "Server Key: ${RUSTDESK_KEY:0:10}..." # Show only first 10 chars for security
    echo

    if ! is_non_interactive; then
        read -p "Is this configuration correct? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Configuration cancelled. Please run the script again."
            exit 1
        fi
    else
        info "Auto-accepting configuration in non-interactive mode"
    fi
}

# Ask for RustDesk password
get_rustdesk_password() {
    header "RustDesk Password Configuration"
    
    if is_non_interactive; then
        if [[ -n "$RUSTDESK_PASSWORD" ]]; then
            info "Using password from environment variable"
        else
            info "No password provided - generating random password"
            RUSTDESK_PASSWORD=$(openssl rand -base64 12)
            info "Generated password: $RUSTDESK_PASSWORD"
            info "Please save this password for future connections"
        fi
    else
        echo "Set a password for RustDesk remote access:"
        echo

        while true; do
            read -s -p "Enter RustDesk password (min 6 characters): " RUSTDESK_PASSWORD
            echo
            if [[ ${#RUSTDESK_PASSWORD} -ge 6 ]]; then
                read -s -p "Confirm password: " RUSTDESK_PASSWORD_CONFIRM
                echo
                if [[ "$RUSTDESK_PASSWORD" == "$RUSTDESK_PASSWORD_CONFIRM" ]]; then
                    break
                else
                    error "Passwords do not match. Please try again."
                    echo
                fi
            else
                error "Password must be at least 6 characters long."
                echo
            fi
        done
    fi

    info "Password configured successfully"
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
            if [[ "$SETUP_VIRTUAL_DISPLAY" == "true" ]]; then
                apt-get install -y wget curl systemd ca-certificates xvfb >/dev/null 2>&1
            else
                apt-get install -y wget curl systemd ca-certificates >/dev/null 2>&1
            fi
            ;;
        centos|rhel|rocky|almalinux)
            if command -v dnf >/dev/null 2>&1; then
                dnf update -y -q
                if [[ "$SETUP_VIRTUAL_DISPLAY" == "true" ]]; then
                    dnf install -y wget curl systemd ca-certificates xorg-x11-server-Xvfb >/dev/null 2>&1
                else
                    dnf install -y wget curl systemd ca-certificates >/dev/null 2>&1
                fi
            else
                yum update -y -q
                if [[ "$SETUP_VIRTUAL_DISPLAY" == "true" ]]; then
                    yum install -y wget curl systemd ca-certificates xorg-x11-server-Xvfb >/dev/null 2>&1
                else
                    yum install -y wget curl systemd ca-certificates >/dev/null 2>&1
                fi
            fi
            ;;
        fedora)
            dnf update -y -q
            if [[ "$SETUP_VIRTUAL_DISPLAY" == "true" ]]; then
                dnf install -y wget curl systemd ca-certificates xorg-x11-server-Xvfb >/dev/null 2>&1
            else
                dnf install -y wget curl systemd ca-certificates >/dev/null 2>&1
            fi
            ;;
        *)
            warn "Unsupported distribution: $DISTRO. Proceeding anyway..."
            ;;
    esac
}

# Set up virtual display
setup_virtual_display() {
    if [[ "$SETUP_VIRTUAL_DISPLAY" != "true" ]]; then
        return
    fi

    log "Setting up virtual display..."

    # Create virtual display service
    cat > /etc/systemd/system/xvfb.service << 'EOL'
[Unit]
Description=Virtual Framebuffer X11 service
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/Xvfb :0 -screen 0 1024x768x24 -ac +extension GLX +render -noreset
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

    # Enable and start virtual display
    systemctl daemon-reload >/dev/null 2>&1
    systemctl enable xvfb >/dev/null 2>&1
    systemctl start xvfb >/dev/null 2>&1

    info "Virtual display configured and started"
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
                rpm -ivh rustdesk.rpm >/dev/null 2>&1 || yum install -y rustdesk.rpm >/dev/null 2>&
