sudo yum update -y
sudo yum install -y amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent