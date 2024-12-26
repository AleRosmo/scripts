#!/bin/bash

# Prompt for GitHub username and email
read -p "Enter your GitHub username: " github_user
read -p "Enter your GitHub email: " github_email

# Configure Git
git config --global user.name "$github_user"
git config --global user.email "$github_email"

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -C "$github_email" -f ~/.ssh/id_rsa -N ""
else
    echo "SSH key already exists."
fi

# Add SSH key to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Display public key
echo "Your SSH public key:"
cat ~/.ssh/id_rsa.pub

# Instructions for GitHub
echo "Copy the above SSH key and add it to your GitHub account:"
echo "1. Go to https://github.com/settings/keys"
echo "2. Click 'New SSH Key'."
echo "3. Paste the key and save."