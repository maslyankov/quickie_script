#!/bin/bash

# Default username
username="admin"

# Help menu
print_help() {
cat << HELP
This script creates a new user with sudo privileges.
Usage: $0 [options]
OPTIONS:
    -u username   Specify a username for the new user. Default is 'admin'.
    -h            Show this help menu.
HELP
exit 0
}

# Parse command-line arguments
while getopts "u:h" option; do
    case $option in
        u) username=$OPTARG;;
        h) print_help;;
        *) print_help;;
    esac
done

# Create user and set password
useradd -m $username

# Ask for password
echo "Please enter the password for new user:"
passwd $username

# Add user to sudo group
usermod -aG sudo $username

# Change user shell to bash
chsh -s /bin/bash $username

echo "User $username created."

# Ask if user wants to continue as the new user
read -p "Continue as newly created user? (Y/n) " continue_as_new
continue_as_new=${continue_as_new:-Y}  # Default to Y if empty

if [[ "$continue_as_new" =~ ^[Yy]$ ]]; then
    echo "Switching to user $username and opening script menu..."
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    exec su - $username -c "bash $SCRIPT_DIR/quick_setup.sh"
fi