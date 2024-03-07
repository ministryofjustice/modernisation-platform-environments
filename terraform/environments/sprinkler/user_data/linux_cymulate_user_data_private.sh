#!/bin/bash

# Install EPEL repository and Ansible
amazon-linux-extras install -y epel
sleep 20
yum update -y
sleep 20
yum install -y ansible

# Create the configuration file /opt/cfg.json
cat << EOF > /opt/cfg.json
{
    "AppProxyInfo": { 
        "Address": "",
        "Port": 0,
        "Username": "",
        "Password": "",
        "Domain": "",
        "UseProxy": false
    },
    "BrowsingProxyInfo": { 
        "Address": "<Browsing Proxy Address>",
        "Port": 0,
        "Username": "",
        "Password": "",
        "Domain": "",
        "UseProxy": false
    },
    "HttpsInfo": {
        "LinkingKey": "${cymulate_agent_linkingkey}"
    },
    "SmtpInfo": {
        "UserName": "",
        "Password": "",
        "Domain": "",
        "IP": "", 
        "Type": 0, 
        "Version": 2 
    }
}
EOF

# Create the Ansible playbook /opt/cymulate.yml
cat << EOF > /opt/cymulate.yml
---
- hosts: localhost
  become: true
  vars:
    cymulate_agent_linkingkey: "${cymulate_agent_linkingkey}"
  tasks:
    - name: Update yum packages
      yum:
        name: "*"
        state: latest

    - name: Install required packages
      yum:
        name: "{{ item }}"
        state: present
      loop:
        - libgdiplus
        - libicu
        - cups
        - gcc
        - zlib-devel
        - openssl-devel
        - python3-pip
        - curl
        - unzip

    - name: Install kubectl
      become_user: root
      shell: |
        curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        mv ./kubectl /usr/local/bin/kubectl

    - name: Download Cymulate Agent & unzip packages
      shell: |
        mkdir /opt/cymulate_install
        curl -o /opt/cymulate_install/CymulateAgentInstaller.zip "https://app.cymulate.com/api/agent/download?arch=64&os=linux&type=zip&isService=false&isInstaller=false&isExecutor=false"
        cd /opt/cymulate_install
        unzip /opt/cymulate_install/CymulateAgentInstaller.zip

    - name: Set Permissions and Install agent without waiting as it takes a long time
      shell: |
        cd /opt/cymulate_install
        chmod +x install.sh
        sudo ./install.sh -configfile /opt/cfg.json
      poll: 0
      background: yes

    - name: Cymulate setup now completed
      debug:
        msg: "Cymulate setup now completed"
EOF

# Run the Ansible playbook
ansible-playbook /opt/cymulate.yml