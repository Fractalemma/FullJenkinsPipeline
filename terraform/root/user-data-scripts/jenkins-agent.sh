#!/bin/bash
set -euxo pipefail

sudo apt update -y
# Install Java and dependencies (Jenkins agents need Java)
sudo apt install -y fontconfig openjdk-21-jre

# Install AWS CLI v2
curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt install -y unzip
unzip -q awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws/

# Install additional tools
apt install -y zip