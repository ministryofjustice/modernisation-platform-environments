#! /bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo "<h1>Cymulate Agent POC in Progress deployed with Terraform</h1>" | sudo tee /var/www/html/index.html
yum instlal curl -y
yum install unzip -y

sudo yum update 
sudo yum install libgdiplus 
sudo yum install libicu 
sudo yum install cups 


curl -o CymulateAgentInstaller.zip https://app.cymulate.com/agent/download?arch=64&os=linux&type=zip&isService=false
unzip CymulateAgentInstaller.zip
cd CymulateAgentInstaller
chmod +x install.sh
sudo ./install.sh
linkingkey = "xxxxx"




