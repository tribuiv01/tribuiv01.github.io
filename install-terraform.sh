#!/bin/bash
# Script to install a specific version of Terraform

# Default version if not specified
TERRAFORM_VERSION=${1:-"1.11.3"}

echo "Installing Terraform version $TERRAFORM_VERSION..."

# Create temporary directory for download
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Determine system architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Determine OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
    linux) ;;
    darwin) ;;
    *) echo "Unsupported OS: $OS"; exit 1 ;;
esac

# Download and install Terraform
DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OS}_${ARCH}.zip"
echo "Downloading Terraform from: $DOWNLOAD_URL"

curl -s -o terraform.zip "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo "Failed to download Terraform. Please check the version and try again."
    exit 1
fi

unzip terraform.zip
if [ $? -ne 0 ]; then
    echo "Failed to unzip Terraform package."
    exit 1
fi

# Move to a directory in PATH
sudo mv terraform /usr/local/bin/
if [ $? -ne 0 ]; then
    echo "Failed to move Terraform to /usr/local/bin. Try running with sudo."
    exit 1
fi

# Clean up
cd - > /dev/null
rm -rf "$TMP_DIR"

# Verify installation
terraform version

echo "Terraform $TERRAFORM_VERSION has been installed successfully!"
