# RustDesk Client Installer

A comprehensive bash script for automated RustDesk client installation and configuration on Linux servers. This script simplifies the deployment of RustDesk clients across multiple servers and automatically configures them to connect to your custom RustDesk server.

## Features

- **Automated Installation**: Downloads and installs the latest RustDesk version
- **Headless Server Support**: Automatically detects headless servers and sets up virtual display (Xvfb)
- **Multiple Configuration Options**: Simple (IP-only) or Advanced (custom ports) setup
- **Password Management**: Secure password configuration with confirmation
- **Multi-Distribution Support**: Works with Ubuntu, Debian, CentOS, RHEL, Rocky Linux, AlmaLinux, and Fedora
- **Server Connectivity Testing**: Validates connection to your RustDesk server before configuration
- **Automatic Service Setup**: Creates and enables systemd services for persistent operation

## Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh | sudo bash
```

### Download and Run

```bash
wget https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh
chmod +x install-rustdesk-client.sh
sudo ./install-rustdesk-client.sh
```

## Installation Process

The script will guide you through the following steps:

### 1. Headless Detection
- Automatically detects if the server has no graphical display
- Offers to set up virtual display (Xvfb) for headless operation

### 2. Configuration Method
Choose between:
- **Simple**: Enter only your server IP (uses standard ports 21116, 21117, 21114)
- **Advanced**: Specify custom ports and URLs

### 3. Server Configuration
- **ID/Rendezvous Server**: Your RustDesk server (default port 21116)
- **Relay Server**: Your RustDesk server (default port 21117)
- **API Server**: Your RustDesk server (default port 21114)
- **Server Key**: Your RustDesk server's public key

### 4. Password Setup
- Secure password entry with confirmation
- Minimum 6 characters required

### 5. Installation and Configuration
- Downloads latest RustDesk version
- Sets up virtual display (if needed)
- Configures services and firewall rules
- Provides connection details

## Requirements

### System Requirements
- Linux distribution (Ubuntu, Debian, CentOS, RHEL, Rocky, AlmaLinux, Fedora)
- Root/sudo access
- Internet connectivity
- x86_64 or aarch64 architecture

### Network Requirements
- Access to GitHub for downloading RustDesk
- Access to your RustDesk server on configured ports
- Standard ports: 21116 (ID), 21117 (Relay), 21114 (API)

## Configuration Examples

### Simple Configuration
```
Server IP: 192.168.1.100
Automatically configures:
- ID Server: 192.168.1.100:21116
- Relay Server: 192.168.1.100:21117
- API Server: http://192.168.1.100:21114
```

### Advanced Configuration
```
ID Server: 192.168.1.100:21116
Relay Server: 192.168.1.100:21117
API Server: http://192.168.1.100:21114
Server Key: [Your public key]
```

## Post-Installation

### Service Management
```bash
# Check service status
sudo systemctl status rustdesk

# Start/stop service
sudo systemctl start rustdesk
sudo systemctl stop rustdesk

# View logs
sudo journalctl -u rustdesk -f
```

### Get Connection Details
```bash
# Get RustDesk ID
sudo rustdesk --get-id

# For headless servers with virtual display
sudo DISPLAY=:0 rustdesk --get-id
```

### Configuration File Location
- Main config: `/root/.config/rustdesk/RustDesk2.toml`
- User configs: `/home/[username]/.config/rustdesk/RustDesk2.toml`

## Mass Deployment

### SSH Deployment Script
```bash
#!/bin/bash
SERVERS="
192.168.1.101
192.168.1.102
192.168.1.103
"

for server in $SERVERS; do
    echo "Deploying RustDesk to $server..."
    ssh root@$server "curl -fsSL https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh | bash"
done
```

### Ansible Playbook
```yaml
---
- hosts: all
  become: yes
  tasks:
    - name: Install RustDesk
      shell: curl -fsSL https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh | bash
```

## Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check detailed logs
sudo journalctl -xeu rustdesk.service

# For headless servers, ensure virtual display is running
sudo systemctl status xvfb
```

#### Cannot Connect
- Verify server IP and ports are accessible
- Check firewall rules on both client and server
- Confirm server key is correct

#### Password Issues
```bash
# Reset password
sudo DISPLAY=:0 rustdesk --password newpassword123

# For headless servers
sudo systemctl restart rustdesk
```

### Manual Configuration
If automatic configuration fails, edit the config file directly:

```bash
sudo nano /root/.config/rustdesk/RustDesk2.toml
```

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

## Security Considerations

- Passwords are stored in configuration files - ensure proper file permissions
- Use strong passwords (minimum 6 characters, recommended 12+)
- Restrict network access to your RustDesk server
- Regularly update RustDesk to the latest version
- Monitor connection logs for unauthorized access

## Supported Operating Systems

| Distribution | Versions | Architecture |
|-------------|----------|--------------|
| Ubuntu      | 18.04+   | x86_64, aarch64 |
| Debian      | 10+      | x86_64, aarch64 |
| CentOS      | 7+       | x86_64, aarch64 |
| RHEL        | 7+       | x86_64, aarch64 |
| Rocky Linux | 8+       | x86_64, aarch64 |
| AlmaLinux   | 8+       | x86_64, aarch64 |
| Fedora      | 30+      | x86_64, aarch64 |

## License

This script is provided as-is under the MIT License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test on multiple distributions
4. Submit a pull request

## Support

For issues related to:
- **This script**: Open an issue in this repository
- **RustDesk software**: Visit [RustDesk GitHub](https://github.com/rustdesk/rustdesk)
- **RustDesk server setup**: Check [RustDesk Server documentation](https://rustdesk.com/docs/en/self-host/)

## Changelog

### v2.0.0
- Added headless server detection and virtual display setup
- Implemented secure password configuration
- Enhanced error handling and validation
- Added server connectivity testing
- Improved service management for headless operation

### v1.0.0
- Initial release with basic installation and configuration
