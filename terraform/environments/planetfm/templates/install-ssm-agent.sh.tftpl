#!/bin/bash
install_ssm_agent_rhel6() {
  echo "Installing amazon-ssm-agent for RHEL6"
  yum install -y https://s3.eu-west-2.amazonaws.com/amazon-ssm-eu-west-2/3.0.1390.0/linux_amd64/amazon-ssm-agent.rpm
  start amazon-ssm-agent
}
install_ssm_agent_rhel() {
  echo "Installing latest version of amazon-ssm-agent"
  yum install -y https://s3.eu-west-2.amazonaws.com/amazon-ssm-eu-west-2/latest/linux_amd64/amazon-ssm-agent.rpm
  systemctl start amazon-ssm-agent
}
install_ssm_agent() {
  if [[ -f /etc/redhat-release ]]; then
    if grep " 6" /etc/redhat-release > /dev/null; then
      install_ssm_agent_rhel6
    else
      install_ssm_agent_rhel
    fi
  else
    echo "Only implemented for RedHat"
  fi
}

echo "install_ssm_agent start" | logger -p local3.info -t user-data
install_ssm_agent 2>&1 | logger -p local3.info -t user-data
echo "install_ssm_agent end" | logger -p local3.info -t user-data
