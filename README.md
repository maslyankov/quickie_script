# ⚡ Quickie Script

A quick setup script for Linux machines (tested on Ubuntu). Provides a menu-driven interface for common server setup tasks.

## 🚀 Quick Start

Run this one-liner on any Linux machine to get started:

```bash
bash <(curl -sL https://github.com/maslyankov/quickie_script/raw/refs/heads/main/quick_setup.sh)
```

Or with `wget`:

```bash
bash <(wget -qO- https://github.com/maslyankov/quickie_script/raw/refs/heads/main/quick_setup.sh)
```

## 📋 Features

The interactive menu displays system information and provides the following options:

| Option | Description |
|--------|-------------|
| **1. Setup admin user** | Creates a new user with sudo privileges and optional login switch |
| **2. Setup Docker** | Installs Docker and Docker Compose |
| **3. Set Timezone** | Sets timezone to Europe/Sofia |
| **4. Install Netbird** | Installs and configures Netbird VPN client |
| **5. Exit** | Exit the script |

### System Info Header

The menu displays useful system information:
- 👤 Current user
- 🌐 Local & Public IP addresses
- 📊 CPU load, Memory usage, Temperature
- 💾 Disk usage

## 📁 Individual Scripts

You can also run individual scripts directly:

### Create Admin User

```bash
bash <(curl -sL https://github.com/maslyankov/quickie_script/raw/refs/heads/main/create_admin_user.sh)
```

With custom username:

```bash
bash <(curl -sL https://github.com/maslyankov/quickie_script/raw/refs/heads/main/create_admin_user.sh) -u myusername
```

## 📝 License

MIT
