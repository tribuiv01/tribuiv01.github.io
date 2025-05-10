#!/bin/bash

# Cập nhật hệ thống
sudo apt update
sudo apt upgrade -y

# Cài đặt các gói cần thiết
sudo apt install -y python3 python3-pip software-properties-common

# Cài đặt Ansible thông qua pip
sudo pip3 install ansible

# Kiểm tra phiên bản Ansible
ansible --version

# Tạo thư mục cấu hình Ansible nếu chưa tồn tại
mkdir -p ~/.ansible

# Tạo file ansible.cfg cơ bản
cat > ~/.ansible/ansible.cfg << 'EOL'
[defaults]
inventory = ~/inventory
host_key_checking = False
remote_user = ansible
timeout = 30

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
EOL

# Tạo file inventory cơ bản
cat > ~/inventory << 'EOL'
[local]
localhost ansible_connection=local

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOL

echo "Ansible đã được cài đặt thành công!"


# Tạo playbook đầu tiên
cat > ~/first_playbook.yml << 'EOL'
---
- name: Test Playbook
  hosts: localhost
  gather_facts: yes
  
  tasks:
    - name: Display system information
      debug:
        msg: "Running on {{ ansible_distribution }} {{ ansible_distribution_version }}"
    
    - name: Check disk space
      command: df -h
      register: disk_space
      changed_when: false
    
    - name: Show disk space
      debug:
        var: disk_space.stdout_lines
EOL

# Chạy playbook
ansible-playbook ~/first_playbook.yml
