#! /bin/bash
sudo amazon-linux-extras instal -y epel
sudo yum update -y
sudo yum install -y ansible

cat << EOF > /opt/cymulate.yml
---
- hosts: all
  become: true
  vars:
    cymulate_agent_linkingkey: "${cymulate_agent_linkingkey}"
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install required packages
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - libgdiplus
        - cups
        - zlib1g-dev
        - libssl-dev
        - build-essential
        - make
        - python3-pip
        - curl
        - unzip

    - name: Install kubectl
      become_user: root
      shell: |
        curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x ./kubectl
        mv ./kubectl /usr/local/bin/kubectl

    - name: Download Cymulate Agent
      get_url:
        url: "https://app.cymulate.com/agent/download?arch=64&os=linux&type=zip&isService=false"
        dest: "/tmp/CymulateAgentInstaller.zip"

    - name: Unzip Cymulate Agent Installer
      command: "unzip /tmp/CymulateAgentInstaller.zip"
      args:
        chdir: "/tmp"

    - name: Move to Cymulate Agent Installer directory
      command: "mv /tmp/CymulateAgentInstaller /opt"
      args:
        creates: "/opt"

    - name: Change directory to Cymulate Agent Installer
      command: "cd /opt/CymulateAgentInstaller"

    - name: Set execute permissions for install.sh
      command: "chmod +x install.sh"
      args:
        chdir: "/opt/CymulateAgentInstaller"

    - name: Copy cfg.json to the target machine
      copy:
        src: "cfg.json"
        dest: "/path/on/target/machine/cfg.json"

    - name: Run Cymulate Agent Installer
      command: "sudo ./install.sh -configfile cfg.json"
      args:
        chdir: "/opt/CymulateAgentInstaller"
EOF

ansible-playbook /opt/cymulate.yml

