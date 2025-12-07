#!/bin/bash

# Determine if we need sudo or running as root
if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

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
$SUDO useradd -m "$username"

# Ask for password
echo "Please enter the password for new user:"
$SUDO passwd "$username"

# Add user to sudo group
$SUDO usermod -aG sudo "$username"

# Change user shell to bash
$SUDO chsh -s /bin/bash "$username"

echo "User $username created successfully!"

# Ask if user wants to continue as the new user
read -p "Continue as newly created user? (Y/n) " continue_as_new
continue_as_new=${continue_as_new:-Y}  # Default to Y if empty

if [[ "$continue_as_new" =~ ^[Yy]$ ]]; then
    echo "Switching to user $username and opening script menu..."
    $SUDO su - "$username" -c 'bash <(curl -s -L https://github.com/maslyankov/quickie_script/raw/refs/heads/main/quick_setup.sh)'
fi