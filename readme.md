# RustDesk Client Auto-Installer

A secure, interactive script to install RustDesk clients on Linux servers and configure them to use your custom RustDesk Server Pro.

## Features

- ✅ **Interactive Configuration** - Prompts for your server details (no hardcoded credentials)
- ✅ **Multi-Distribution Support** - Ubuntu, Debian, CentOS, RHEL, Rocky, Alma, Fedora
- ✅ **Automatic Service Setup** - Creates systemd service for auto-start
- ✅ **Firewall Configuration** - Automatically configures UFW/firewalld
- ✅ **Secure** - No sensitive information stored in the script
- ✅ **One-Line Installation** - Single command deployment

## Quick Start

curl -fsSL https://raw.githubusercontent.com/Lee-Robinson/rustdesk-installer/main/install-rustdesk-client.sh | sudo bash
