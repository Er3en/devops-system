# Ansible Cheat Sheet

This README serves as a quick reference guide for using Ansible, covering common commands, modules, and playbook structures.

## Table of Contents
- [Ansible Basics](#ansible-basics)
- [Ad-Hoc Commands](#ad-hoc-commands)
- [Playbooks](#playbooks)
- [Variables](#variables)
- [Roles](#roles)
- [Common Modules](#common-modules)
- [Handlers](#handlers)
- [Loops](#loops)
- [Templates](#templates)
- [Conditionals](#conditionals)
- [Tags](#tags)
- [Vault](#vault)

## Ansible Basics
- **Installation**:
  ```shell
  sudo apt-get install ansible  # Ubuntu/Debian
  brew install ansible          # macOS
  ```
- **Configuration File**: 
  
  Ansible uses ansible.cfg for configuration. Common paths:
  ```shell
  /etc/ansible/ansible.cfg
  ~/.ansible.cfg
  ```

- **Inventory File**: Default location is /etc/ansible/hosts. Example format:
  ```yaml
  [webservers]
  web1.example.com
  web2.example.com

  [dbservers]
  db1.example.com
  ```
## Ad-Hoc Commands
- **Ping all hosts:**
  `ansible all -m ping`
- **Execute a command:**
  `ansible all -m ping`
- **Copy a file:**
  `ansible all -m copy -a "src=/local/path dest=/remote/path"`
- **Check disk usage:**
  `ansible all -m shell -a "df -h"`

## Playbooks
- **Basic Structure:**
  ```yaml
  ---
  - name: Example Playbook
    hosts: all
    tasks:
      - name: Ensure Apache is installed
        apt:
          name: apache2
          state: present
  ```
- **Running a Playbook:**
  `ansible-playbook playbook.yml`

## Variables
- **Defining Variables:**
  ```yaml
  vars:
    http_port: 80
  ```

- **Using Variables:**
  ```yaml
  tasks:
    - name: Ensure Apache is listening on the correct port
      lineinfile:
        path: /etc/apache2/ports.conf
        regexp: '^Listen'
        line: "Listen {{ http_port }}"
  ```
- **Host Variables:** Defined in the inventory file or `host_vars/` directory.

## Variables
- **Create a Role:**
  
      ansible-galaxy init my_role
- **Using Roles in a Playbook:**
  ```yaml
  ---
  - hosts: webservers
    roles:
      - my_role
  ```
## Common Modules
- **Package Management:**
  ```yaml
  - name: Install a package
    apt:
      name: "{{ item }}"
      state: present
    with_items:
      - nginx
      - git
  ```
- **Using Roles in a Playbook:**
  ```yaml
  ---
  - hosts: webservers
    roles:
      - my_role
  ```
- **Service Management:**
  ```yaml
  - name: Ensure service is running
    service:
      name: nginx
      state: started
  ```
- **File Management:**
  ```yaml
  - name: Create a directory
    file:
      path: /etc/mydir
      state: directory
  ```
## Handlers
- **Defining a Handler:**
  ```yaml
  handlers:
    - name: restart apache
      service:
        name: apache2
        state: restarted
  ```
- **Calling a Handler:**
  ```yaml
  tasks:
    - name: Ensure config is updated
      template:
        src: template.j2
        dest: /etc/apache2/sites-enabled/000-default.conf
      notify: restart apache
  ```
## Loops
- **Simple Loop:**
  ```yaml
  tasks:
  - name: Add multiple users
    user:
      name: "{{ item }}"
      state: present
    with_items:
      - alice
      - bob
      - charlie
  ```
- **Loop with a Dictionary:**
  ```yaml
  tasks:
    - name: Create multiple files
      file:
        path: "{{ item.path }}"
        state: "{{ item.state }}"
      with_items:
        - { path: '/tmp/file1', state: 'touch' }
        - { path: '/tmp/file2', state: 'absent' }
  ```
## Templates
- **Using Templates:**
  ```yaml
  tasks:
    - name: Deploy a configuration file
      template:
        src: my_template.j2
        dest: /etc/myapp/config.conf
  ```
- **Using Templates:**
  ```jinja2
  server_name {{ ansible_hostname }};
  listen {{ http_port }};
  ```

## Conditionals
- **Simple Conditional:**
  ```yaml
  tasks:
    - name: Install httpd on RedHat
      yum:
        name: httpd
        state: present
      when: ansible_os_family == "RedHat"
  ```
## Tags
- **Tagging Tasks:**
  ```yaml
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
      tags: web

    - name: Install MySQL
      apt:
        name: mysql-server
        state: present
      tags: database
    ```
- **Running Specific Tags:**
    ansible-playbook playbook.yml --tags "web"
## Vault
- **Encrypt a file:**
    ansible-vault encrypt secrets.yml
- **Decrypt a file:**
    ansible-vault decrypt secrets.yml
- **Using Vault in a Playbook:**
    ```yaml
  vars_files:
    - secrets.yml
    ```


# Ansible
Master node -> linux,

To install ansible: ```python3 -m pip install ansible pywinrm```

Store all configuration files in `/etc/ansible`


## Windows hosts
Instruction for windows hosts: https://www.ansible.com/blog/connecting-to-a-windows-host


Step 1: Setting up WinRM:

With most versions of Windows, WinRM ships in the box but isn’t turned on by default. There’s a Configure Remoting for Ansible script you can run on the remote Windows machine (in a PowerShell console as an Admin) to turn on WinRM. To set up an https listener, build a self-signed cert and execute PowerShell commands, just run the script like in the example below (if you’ve got the `host_setup/ConfigureRemotingForAnsible.ps1` file stored locally on your machine):

Tips: If u have problem with Execution Policy, run this before running script.
```bat
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
Step 2: Install Pywinrm:

Since pywinrm dependencies aren’t shipped with Ansible Engine (and these are necessary for using WinRM), make sure you install the pywinrm-related library on the machine that Ansible is installed on. The simplest method is to run `pip install pywinrm` in your Terminal.

Step 3: Set Up Your Inventory File Correctly:

In order to connect to your Windows hosts properly, you need to make sure that you put in ansible_connection=winrm in the host vars section of your inventory file so that Ansible Engine doesn’t just keep trying to connect to your Windows host via SSH.

Also, the WinRM connection plugin defaults to communicating via https, but it supports different modes like message-encrypted http. Since the “Configure Remoting for Ansible” script we ran earlier set things up with the self-signed cert, we need to tell Python, “Don’t try to validate this certificate because it’s not going to be from a valid CA.” So in order to prevent an error, one more thing you need to put into the host vars section is: ansible_winrm_server_cert_validation=ignore

Just so you can see it in one place, here is an example host file (please note, some details for your particular environment will be different):
```bash
[win]
172.316.52.5
172.316.52.6
[win:vars]
ansible_user=vagrant
ansible_password=password
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
```
Step 4: Test Connection:

To see if everything is working, go to your control node’s terminal and type ansible [host_group_name_in_inventory_file] -i hosts -m win_ping. Your output should look like this:
```bash
user@host:/$ ansible all -m win_ping
```
```bash
host2 | SUCCESS => {
    "changed": false,
    "ping": "pong"}
```
```bash
host1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

## Setup WinRM for Ansible with Certificate Authentication (single host auth) / working on using one cert for many PCS
Download the repo https://github.com/devopssolver/ansible-winrm-cert-auth
1. Generate client certificate on the linux machine
2. Copy the keys, and scripts to the windows host
3. Open powershell and use this command `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`
4. .\import_client_cert
5. .\enable_winrm.ps1
6. .\create_server_cert.ps1
7. .\create_ansible_user.ps1
8. .\create_winrm_listener.ps1
9. .\update_firewall.ps1
10. Create inventory file
```bash

[win]
172.16.2.5
[win:vars]
ansible_host=172.126.212.51
ansible_user=vagrant
ansible_connection=winrm
ansible_winrm_transport=certificate
ansible_winrm_cert_pem=/path/to/client_cert.pem
ansible_winrm_cert_key_pem=/path/to/client_key.pem
ansible_port=5986
ansible_winrm_server_cert_validation=ignore
```
### Test connection
user@host:/$ ansible all -m win_ping
```bash
host2 | SUCCESS => {
    "changed": false,
    "ping": "pong"}
```
# Disable Privacy Settings Experience at Sign

https://www.tenforums.com/tutorials/118840-enable-disable-privacy-settings-experience-sign-windows-10-a.html



# Integrating Windows machines with Github Actions (GA)

Github recommends to place GA runner on main drive.
https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners
To place it under another drive we changed the ExecutionPolicy to Bypass mode -> `Set-ExecutionPolicy Bypass`
```bash
       Scope ExecutionPolicy
        ----- ---------------
MachinePolicy       Undefined
   UserPolicy       Undefined
      Process       Undefined
  CurrentUser    RemoteSigned
 LocalMachine          Bypass
```

Ansible Collaborative
Connecting to a Windows Host
Set up and connect to your Windows hosts with Ansible Engine.
Apr 24th, 2018

tenforums.comtenforums.com
Enable or Disable Privacy Settings Experience at Sign-in in Windows 10
How to Enable or Disable Privacy Settings Experience at Sign-in in Windows 10
