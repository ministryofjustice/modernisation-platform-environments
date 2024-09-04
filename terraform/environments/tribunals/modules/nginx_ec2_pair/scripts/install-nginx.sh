#!/bin/bash
echo "starting nginx install script"
sudo yum update -y &&
sudo amazon-linux-extras install nginx1 -y
