
<img width="763" height="683" alt="Screenshot 2025-09-20 at 15 15 25" src="https://github.com/user-attachments/assets/c1172652-2b4d-463f-bdcc-886c496dc7a9" />






# RustDesk Client Installer

A comprehensive bash script for automated RustDesk client installation and configuration on Linux servers. This script simplifies the deployment of RustDesk clients across multiple servers with both interactive and non-interactive modes, automatic headless server detection, and virtual display setup.

## Features

### 🚀 **Installation & Configuration**
- **Automated Installation**: Downloads and installs the latest RustDesk version automatically
- **Smart Configuration**: Simple (IP-only) or Advanced (custom ports) setup options
- **Multi-Distribution Support**: Ubuntu, Debian, CentOS, RHEL, Rocky Linux, AlmaLinux, Fedora
- **Architecture Support**: x86_64 and aarch64 (ARM64)

### 🖥️ **Headless Server Support**
- **Automatic Detection**: Detects headless servers and prompts for virtual display setup
- **Virtual Display (Xvfb)**: Automatically installs and configures virtual display for headless operation
- **Service Integration**: Creates proper systemd services with dependencies

### 🔐 **Security & Password Management**
- **Interactive Password Setup**: Secure password entry with confirmation
- **Non-Interactive Mode**: Environment variable support for automated deployments
- **Auto-Generated Passwords**: Generates secure random passwords when not specified
- **Password Persistence**: Passwords survive server reboots

### ⚙️ **Deployment Options**
- **Interactive Mode**: Full guided setup with prompts and validation
- **Non-Interactive Mode**: Automated deployment using environment variables
- **Mass Deployment Ready**: Perfect for deploying across multiple servers
- **Server Connectivity Testing**: Validates connection to RustDesk server before configuration

## Quick Start

### Interactive Installation

**Standard Linux servers (with sudo):**
```bash
# Download and run interactively
wget https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh
chmod +x install-rustdesk-client.sh
sudo ./install-rustdesk-client.sh
```

**Root environments (Proxmox, containers, minimal installs):**
```bash
# Download and run as root (no sudo needed)
wget https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh
chmod +x install-rustdesk-client.sh
./install-rustdesk-client.sh
```

### Non-Interactive Installation

**Standard Linux servers (with sudo):**
```bash
# Set environment variables
export RUSTDESK_SERVER_HOST="your.server.ip"
export RUSTDESK_SERVER_KEY="your_server_public_key"
export RUSTDESK_PASSWORD="YourSecurePassword123"

# One-line installation
curl -fsSL https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh | sudo -E bash
```

**Root environments (Proxmox, containers):**
```bash
# Set environment variables
export RUSTDESK_SERVER_HOST="your.server.ip"
export RUSTDESK_SERVER_KEY="your_server_public_key"
export RUSTDESK_PASSWORD="YourSecurePassword123"

# One-line installation (no sudo needed)
curl -fsSL https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh | bash
```

## Installation Process

### 1. **System Detection**
- Automatically detects Linux distribution and version
- Identifies headless vs GUI systems
- Determines system architecture

### 2. **Headless Server Setup** (if detected)
- Prompts to install virtual display (Xvfb)
- Automatically configures virtual display service
- Sets up proper environment variables

### 3. **Configuration Method Selection**
**Interactive Mode:**
- **Simple**: Enter only server IP (uses standard ports)
- **Advanced**: Specify custom ports and URLs

**Non-Interactive Mode:**
- Uses environment variables
- Defaults to Simple configuration

### 4. **Server Configuration**
- **ID/Rendezvous Server**: Default port 21116
- **Relay Server**: Default port 21117  
- **API Server**: Default port 21114
- **Server Key**: Your RustDesk server's public key
- **Connectivity Testing**: Validates each service

### 5. **Password Configuration**
- **Interactive**: Secure password entry with confirmation
- **Non-Interactive**: Uses environment variable or generates random password
- **Minimum Requirements**: 6 characters minimum

### 6. **Installation & Service Setup**
- Downloads latest RustDesk version
- Installs dependencies and virtual display (if needed)
- Creates systemd services with proper dependencies
- Configures firewall rules
- Starts and enables services

## Requirements

### System Requirements
- **Operating System**: Linux (see supported distributions below)
- **Architecture**: x86_64 or aarch64
- **Privileges**: Root/sudo access
- **Network**: Internet connectivity

### Network Requirements
- Access to GitHub for downloading RustDesk
- Access to your RustDesk server on configured ports:
  - **21116** (ID/Rendezvous Server)
  - **21117** (Relay Server)  
  - **21114** (API Server)

### Supported Operating Systems

| Distribution | Versions | Package Type | Common Environments |
|-------------|----------|--------------|-------------------|
| Ubuntu      | 16.04+   | .deb | Standard servers, VMs |
| Debian      | 9+       | .deb | Proxmox, containers |
| CentOS      | 7+       | .rpm | Enterprise servers |
| RHEL        | 7+       | .rpm | Enterprise servers |
| Rocky Linux | 8+       | .rpm | Enterprise servers |
| AlmaLinux   | 8+       | .rpm | Enterprise servers |
| Fedora      | 30+      | .rpm | Development servers |

## Configuration Examples

### Simple Configuration (Recommended)
```bash
# Interactive prompt
Server IP: 192.168.1.100

# Automatically configures:
ID Server: 192.168.1.100:21116
Relay Server: 192.168.1.100:21117
API Server: http://192.168.1.100:21114
```

### Advanced Configuration
```bash
# Custom ports and URLs
ID Server: 192.168.1.100:21116
Relay Server: 192.168.1.100:21117
API Server: http://192.168.1.100:21114
Server Key: [Your public key]
```

### Environment Variables (Non-Interactive)
```bash
export RUSTDESK_SERVER_HOST="192.168.1.100"
export RUSTDESK_SERVER_KEY="xMHl+uV+yPZGQa4FYe7AR7xQrLbsxnnBP8GrG5CTWMI="
export RUSTDESK_PASSWORD="SecurePassword123"
```

## Mass Deployment

### SSH Deployment Script
```bash
#!/bin/bash
# Mass deployment script
export RUSTDESK_SERVER_HOST="192.168.1.100"
export RUSTDESK_SERVER_KEY="your_server_public_key"
export RUSTDESK_PASSWORD="StandardPassword123"

SERVERS="192.168.1.101 192.168.1.102 192.168.1.103"

for server in $SERVERS; do
    echo "Installing RustDesk on $server..."
    # Check if server requires sudo or running as root
    ssh root@$server "export RUSTDESK_SERVER_HOST='$RUSTDESK_SERVER_HOST' RUSTDESK_SERVER_KEY='$RUSTDESK_SERVER_KEY' RUSTDESK_PASSWORD='$RUSTDESK_PASSWORD'; curl -fsSL https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh | bash"
    
    # Alternative for servers with sudo users
    # ssh user@$server "export RUSTDESK_SERVER_HOST='$RUSTDESK_SERVER_HOST' RUSTDESK_SERVER_KEY='$RUSTDESK_SERVER_KEY' RUSTDESK_PASSWORD='$RUSTDESK_PASSWORD'; curl -fsSL https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh | sudo -E bash"
done
```

### Ansible Playbook
```yaml
---
- hosts: all
  become: yes
  environment:
    RUSTDESK_SERVER_HOST: "192.168.1.100"
    RUSTDESK_SERVER_KEY: "your_server_public_key"
    RUSTDESK_PASSWORD: "StandardPassword123"
  tasks:
    - name: Install RustDesk
      shell: curl -fsSL https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh | bash
      when: ansible_user_id == 'root'
    
    - name: Install RustDesk with sudo
      shell: curl -fsSL https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh | sudo -E bash
      when: ansible_user_id != 'root'
```

## Post-Installation Management

### Service Management
```bash
# Check service status
sudo systemctl status rustdesk

# Start/stop/restart services
sudo systemctl start rustdesk
sudo systemctl stop rustdesk
sudo systemctl restart rustdesk

# View service logs
sudo journalctl -u rustdesk -f

# For headless servers with virtual display
sudo systemctl status xvfb
```

### Connection Information
```bash
# Get RustDesk ID
sudo rustdesk --get-id

# For headless servers
sudo DISPLAY=:0 rustdesk --get-id

# Change password
sudo DISPLAY=:0 rustdesk --password newpassword123
```

### Configuration Files
- **Main config**: `/root/.config/rustdesk/RustDesk2.toml`
- **User configs**: `/home/[username]/.config/rustdesk/RustDesk2.toml`
- **Service files**: `/etc/systemd/system/rustdesk.service`, `/etc/systemd/system/xvfb.service`

### Sample Configuration File
```toml
[options]
custom-rendezvous-server = '192.168.1.100:21116'
relay-server = '192.168.1.100:21117'
api-server = 'http://192.168.1.100:21114'
key = 'your_server_public_key'
password = 'your_password'

[display]
allow-always-software-render = true
allow-auto-reconnect = true

[security]
allow-remote-config-modification = false
approve-mode = 'password'
```

## Troubleshooting

### Common Issues

#### sudo: command not found (Proxmox/Minimal Installs)
If you encounter "sudo: command not found", you're likely running on a minimal installation or as root:

**Solution 1 - Run directly as root:**
```bash
# Since you're already root, no sudo needed
chmod +x install-rustdesk-client.sh
./install-rustdesk-client.sh
```

**Solution 2 - Install sudo first:**
```bash
# Install sudo (Debian/Ubuntu-based systems)
apt update && apt install sudo -y

# Then run normally
sudo ./install-rustdesk-client.sh
```

**Solution 3 - Use curl method without sudo:**
```bash
# For root environments
export RUSTDESK_SERVER_HOST="your.server.ip"
export RUSTDESK_SERVER_KEY="your_server_public_key"
export RUSTDESK_PASSWORD="your_password"

curl -fsSL https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh | bash
```

#### Service Won't Start
```bash
# Check detailed logs
sudo journalctl -xeu rustdesk.service

# For headless servers, ensure virtual display is running
sudo systemctl status xvfb
sudo systemctl restart xvfb
sudo systemctl restart rustdesk
```

#### Cannot Connect to Server
1. **Verify server configuration**:
   ```bash
   # Test connectivity to each port
   telnet your.server.ip 21116
   telnet your.server.ip 21117
   telnet your.server.ip 21114
   ```

2. **Check firewall rules**:
   ```bash
   # Ubuntu/Debian
   sudo ufw status
   
   # CentOS/RHEL/Fedora
   sudo firewall-cmd --list-all
   ```

3. **Verify configuration**:
   ```bash
   sudo cat /root/.config/rustdesk/RustDesk2.toml
   ```

#### Password Issues
```bash
# Reset password (interactive)
sudo DISPLAY=:0 rustdesk --password

# Set new password (headless)
sudo DISPLAY=:0 rustdesk --password newpassword123

# Restart service after password change
sudo systemctl restart rustdesk
```

#### Virtual Display Issues (Headless Servers)
```bash
# Check if virtual display is running
sudo systemctl status xvfb

# Restart virtual display
sudo systemctl restart xvfb

# Test virtual display
sudo DISPLAY=:0 xdpyinfo
```

### Download Issues
If you encounter 404 errors during download:
1. Check if GitHub is accessible
2. Verify the latest RustDesk version
3. Try running the script again (it fetches the latest version automatically)

### Manual Recovery
If the script fails partway through:
```bash
# Clean up any partial installation
sudo systemctl stop rustdesk
sudo apt remove --purge rustdesk -y  # Ubuntu/Debian
sudo dnf remove rustdesk -y          # Fedora/CentOS 8+
sudo yum remove rustdesk -y          # CentOS 7

# Remove configuration
sudo rm -rf /root/.config/rustdesk
sudo rm -f /etc/systemd/system/rustdesk.service

# Re-run the installer
```

## Security Considerations

### Password Security
- Use strong passwords (minimum 6 characters, recommended 12+)
- Passwords are stored in configuration files - ensure proper file permissions
- Consider using different passwords for different server groups
- Regularly rotate passwords for enhanced security

### Network Security
- Restrict network access to your RustDesk server using firewalls
- Use VPN or private networks when possible
- Monitor connection logs for unauthorized access attempts
- Keep RustDesk updated to the latest version

### File Permissions
The script automatically sets secure permissions, but verify:
```bash
# Check configuration file permissions
ls -la /root/.config/rustdesk/RustDesk2.toml
# Should be: -rw------- (600) root root
```

## Support & Contributing

### Getting Help
- **Script Issues**: Open an issue in this repository
- **RustDesk Software**: Visit [RustDesk GitHub](https://github.com/rustdesk/rustdesk)
- **RustDesk Server**: Check [RustDesk Documentation](https://rustdesk.com/docs/)

### Contributing
Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test on multiple distributions
4. Update documentation as needed
5. Submit a pull request

### Reporting Issues
When reporting issues, please include:
- Linux distribution and version
- System architecture (x86_64/aarch64)
- Whether it's a headless server
- Full error messages or logs
- Steps to reproduce

## Changelog

### v2.1.0 (Current)
- **Fixed**: Download URL format for latest RustDesk versions
- **Added**: Non-interactive mode with environment variable support
- **Added**: Automatic headless server detection and virtual display setup
- **Added**: Enhanced error handling and validation
- **Added**: Server connectivity testing
- **Added**: Automatic password generation
- **Improved**: Service management for headless operation
- **Improved**: Multi-distribution support

### v2.0.0
- Added headless server detection and virtual display setup
- Implemented secure password configuration
- Enhanced error handling and validation
- Added server connectivity testing
- Improved service management

### v1.0.0
- Initial release with basic installation and configuration

## License

This script is provided under the MIT License. See the LICENSE file for details.

---

**Note**: This installer is designed for system administrators managing multiple Linux servers. Always test on a non-production system first before mass deployment.
