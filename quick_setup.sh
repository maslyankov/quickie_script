#!/bin/bash

# Colors for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to get system info
function get_system_info {
    # Local IP (get primary interface IP)
    local_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    [ -z "$local_ip" ] && local_ip="N/A"

    # Public IP (with timeout to avoid hanging)
    public_ip=$(curl -s --connect-timeout 2 ifconfig.me 2>/dev/null)
    [ -z "$public_ip" ] && public_ip="N/A"

    # Current user
    current_user=$(whoami)

    # CPU load (1 min average)
    cpu_load=$(cat /proc/loadavg 2>/dev/null | awk '{print $1}')
    [ -z "$cpu_load" ] && cpu_load="N/A"

    # Memory usage
    if command -v free &> /dev/null; then
        mem_info=$(free -m | awk 'NR==2{printf "%.1f%% (%dMB/%dMB)", $3*100/$2, $3, $2}')
    else
        mem_info="N/A"
    fi

    # CPU Temperature (try different sources)
    cpu_temp="N/A"
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
        if [ -n "$temp_raw" ]; then
            cpu_temp=$(echo "scale=1; $temp_raw/1000" | bc 2>/dev/null)°C
        fi
    elif command -v sensors &> /dev/null; then
        cpu_temp=$(sensors 2>/dev/null | grep -oP 'Core 0.*?\+\K[0-9.]+' | head -1)
        [ -n "$cpu_temp" ] && cpu_temp="${cpu_temp}°C"
    fi

    # Disk usage (root partition)
    disk_usage=$(df -h / 2>/dev/null | awk 'NR==2{print $5 " (" $3 "/" $2 ")"}')
    [ -z "$disk_usage" ] && disk_usage="N/A"

    # Netbird status
    if ! command -v netbird &> /dev/null; then
        netbird_status="Not installed"
        netbird_status_color="${RED}"
    else
        netbird_state=$(netbird status 2>/dev/null | grep -oP 'Status: \K\w+' | head -1)
        if [ "$netbird_state" = "Connected" ]; then
            netbird_ip_addr=$(netbird status 2>/dev/null | grep 'NetBird IP' | sed 's/NetBird IP: //' | sed 's#/.*##')
            netbird_status="Running (${netbird_ip_addr})"
            netbird_status_color="${GREEN}"
        elif [ -n "$netbird_state" ]; then
            netbird_status="Not running"
            netbird_status_color="${YELLOW}"
        else
            netbird_status="Not running"
            netbird_status_color="${YELLOW}"
        fi
    fi
}

# Function to display header with system info
function show_header {
    get_system_info
    
    clear
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC}              ${BOLD}${YELLOW}⚡ QUICK SETUP SCRIPT ⚡${NC}              ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BLUE}User:${NC}       ${GREEN}${current_user}${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BLUE}Local IP:${NC}   ${GREEN}${local_ip}${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BLUE}Public IP:${NC}  ${GREEN}${public_ip}${NC}"
    echo -e "${BOLD}${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BLUE}CPU Load:${NC}   ${YELLOW}${cpu_load}${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BLUE}Memory:${NC}     ${YELLOW}${mem_info}${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BLUE}CPU Temp:${NC}   ${YELLOW}${cpu_temp}${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BLUE}Disk (/):${NC}   ${YELLOW}${disk_usage}${NC}"
    echo -e "${BOLD}${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BLUE}Netbird:${NC}    ${netbird_status_color}${netbird_status}${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to display menu
function show_menu {
    show_header
    echo -e "${BOLD}Select an option:${NC}"
    echo ""
    echo -e "  ${GREEN}1.${NC} Setup admin user"
    echo -e "  ${GREEN}2.${NC} Setup Docker"
    echo -e "  ${GREEN}3.${NC} Set Timezone to Europe/Sofia"
    echo -e "  ${GREEN}4.${NC} Install & Setup Netbird"
    echo -e "  ${RED}5.${NC} Exit"
    echo ""
}

# Function to install and setup Netbird
function setup_netbird {
    # Check if netbird is already installed
    if command -v netbird &> /dev/null; then
        netbird_state=$(netbird status 2>/dev/null | grep -oP 'Status: \K\w+' | head -1)
        if [ "$netbird_state" = "Connected" ]; then
            netbird_ip_addr=$(netbird status 2>/dev/null | grep 'NetBird IP' | sed 's/NetBird IP: //' | sed 's#/.*##')
            echo ""
            echo -e "${GREEN}════════════════════════════════════════${NC}"
            echo -e "${GREEN}Netbird is already installed and running${NC}"
            echo -e "${GREEN}Netbird IP: ${BOLD}${netbird_ip_addr}${NC}"
            echo -e "${GREEN}════════════════════════════════════════${NC}"
            echo ""
            read -n 1 -s -r -p "Press any key to continue..."
            return
        else
            echo ""
            echo -e "${YELLOW}Netbird is installed but not running.${NC}"
            read -p "Do you want to configure and start it? (Y/n) " start_netbird
            start_netbird=${start_netbird:-Y}
            if [[ ! "$start_netbird" =~ ^[Yy]$ ]]; then
                return
            fi
            # Skip installation, go to configuration
            echo ""
        fi
    else
        echo "Installing Netbird..."
        
        # Install dependencies
        echo "Installing dependencies..."
        sudo apt update
        sudo apt install -y ca-certificates curl gnupg

        # Add public key for netbird
        echo "Adding Netbird public key..."
        curl -sSL https://pkgs.netbird.io/debian/public.key | sudo gpg --dearmor -o /usr/share/keyrings/netbird-archive-keyring.gpg

        # Add netbird repository
        echo "Adding Netbird repository..."
        echo "deb [signed-by=/usr/share/keyrings/netbird-archive-keyring.gpg] https://pkgs.netbird.io/debian stable main" | sudo tee /etc/apt/sources.list.d/netbird.list > /dev/null

        # Install netbird
        echo "Installing Netbird package..."
        sudo apt update
        sudo apt install -y netbird

        echo -e "${GREEN}Netbird installed successfully!${NC}"
        echo ""
    fi

    # Get configuration from user
    read -p "Enter Netbird Setup Key: " netbird_setup_key
    read -p "Enter Netbird Management URL: " netbird_url
    read -p "Enter Site ID: " site_id
    read -p "Enter Instance ID: " instance_id

    # Configure and start netbird
    echo "Configuring Netbird..."
    sudo netbird up --setup-key "$netbird_setup_key" --management-url "$netbird_url" --hostname "edge-${site_id}-${instance_id}"

    # Wait for netbird to connect
    echo "Waiting for Netbird to connect..."
    sleep 5

    # Get and display Netbird IP
    netbird_ip=$(netbird status | grep 'NetBird IP' | sed 's/NetBird IP: //' | sed 's#/16##')
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}Netbird configured successfully!${NC}"
    echo -e "${GREEN}Netbird IP: ${BOLD}${netbird_ip}${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
}

# Function to read user input and execute the corresponding script
function read_and_run {
    read -p "Enter your choice [ 1 - 5 ] " choice
    case $choice in
        1) 
            echo "Running the admin user setup script..."
            bash <(curl -s -L https://gist.github.com/maslyankov/75fec45087eddcb09b9527a915905045/raw/502f11fe3da8280e8645c4c61e543c6814f068a4/create_admin_user.sh)
            ;;
        2) 
            echo "Running the Docker setup script..."
            bash <(curl -s -L https://gist.github.com/maslyankov/b1078c8d1143584ad1f3201f73632dcf/raw/2b19d1c55810a970bb28daeaeba84678c620c2a2/setup_docker_and_compose2.sh)
            ;;
        3)
            echo "Setting timezone to Europe/Sofia"
            sudo timedatectl set-timezone Europe/Sofia
            ;;
        4)
            setup_netbird
            ;;
        5) exit 0;;
        *) echo "Invalid option.";;
    esac
}

# Main loop
while true
do
    show_menu
    read_and_run
done