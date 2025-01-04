# Ansible Project for Deploying a Website on Microsoft Azure

---

## Project Overview

This repository demonstrates deploying a website using Ansible on Microsoft Azure.

It includes:
- Setting up a controller node and managed nodes.
- Configuring keyless SSH access.
- Writing playbooks, inventories, and using them.
- Cleaning up resources.

---

## Setup Instructions

### Prerequisites

1.	Azure Subscription: Ensure you have an active Azure subscription. If not, you can create a free account.

2.	Install Azure CLI: Install the Azure CLI to interact with Azure services.
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

3.	Install Ansible: Install Ansible on your local machine or preferred environment.
```bash
sudo apt update
sudo apt install -y ansible
```

4.	Install Azure Ansible Collection: Install the Azure collection for Ansible to manage Azure resources.
```bash
ansible-galaxy collection install azure.azcollection
```

5.	Azure Authentication: Set up authentication to Azure using a Service Principal.
```
az ad sp create-for-rbac --name AnsibleSP --role Contributor --scopes /subscriptions/<Your-Subscription-ID>
```

- Note the **appId**, **password**, and **tenant** from the output. 
- Set them as environment variables:
```bash
export AZURE_CLIENT_ID=<appId>
export AZURE_SECRET=<password>
export AZURE_SUBSCRIPTION_ID=<Your-Subscription-ID>
export AZURE_TENANT=<tenant>
```

- Alternatively, you can store these credentials in ~/.azure/credentials.

---

### Step 1: Create a Bash Script to Set Up the Ansible Environment

- Create a script named setup_ansible_environment.sh to set up the necessary Azure resources.
```bash
#!/bin/bash

# Variables
RESOURCE_GROUP="ansible-rg"
LOCATION="eastus"
VNET_NAME="ansible-vnet"
SUBNET_NAME="ansible-subnet"
NSG_NAME="ansible-nsg"
ADMIN_USERNAME="azureuser"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
VM_SIZE="Standard_B1s"
CONTROLLER_VM="ansible-controller"
WORKER_VM="ansible-worker"

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Virtual Network
az network vnet create --resource-group $RESOURCE_GROUP --name $VNET_NAME --address-prefix 10.0.0.0/16 --subnet-name $SUBNET_NAME --subnet-prefix 10.0.1.0/24

# Create Network Security Group
az network nsg create --resource-group $RESOURCE_GROUP --name $NSG_NAME

# Create NSG Rules
az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --name Allow-SSH --protocol tcp --priority 1000 --destination-port-range 22 --access allow
az network nsg rule create --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --name Allow-HTTP --protocol tcp --priority 1001 --destination-port-range 80 --access allow

# Create Public IPs
az network public-ip create --resource-group $RESOURCE_GROUP --name ${CONTROLLER_VM}-pip --allocation-method Static
az network public-ip create --resource-group $RESOURCE_GROUP --name ${WORKER_VM}-pip --allocation-method Static

# Create Network Interfaces
az network nic create --resource-group $RESOURCE_GROUP --name ${CONTROLLER_VM}-nic --vnet-name $VNET_NAME --subnet $SUBNET_NAME --network-security-group $NSG_NAME --public-ip-address ${CONTROLLER_VM}-pip
az network nic create --resource-group $RESOURCE_GROUP --name ${WORKER_VM}-nic --vnet-name $VNET_NAME --subnet $SUBNET_NAME --network-security-group $NSG_NAME --public-ip-address ${WORKER_VM}-pip

# Create VMs
az vm create --resource-group $RESOURCE_GROUP --name $CONTROLLER_VM --size $VM_SIZE --nics ${CONTROLLER_VM}-nic --image UbuntuLTS --admin-username $ADMIN_USERNAME --ssh-key-values $SSH_KEY_PATH
az vm create --resource-group $RESOURCE_GROUP --name $WORKER_VM --size $VM_SIZE --nics ${WORKER_VM}-nic --image UbuntuLTS --admin-username $ADMIN_USERNAME --ssh-key-values $SSH_KEY_PATH

# Output Public IP Addresses
echo "Controller VM Public IP:"
az vm list-ip-addresses --resource-group $RESOURCE_GROUP --name $CONTROLLER_VM --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" --output tsv

echo "Worker VM Public IP:"
az vm list-ip-addresses --resource-group $RESOURCE_GROUP --name $WORKER_VM --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" --output tsv

echo "Ansible environment setup is complete!"
```
- Make the script executable:
```bash
chmod +x setup_ansible_environment.sh
```

- Run the script to set up the environment:
```bash
./setup_ansible_environment.sh
```

### Step 2: Configure Keyless SSH Access

- Ensure that your SSH public key is added during VM creation. 
- If not, you can manually copy your public key to the VMs.

**On the controller node:*
```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub azureuser@<Worker-VM-Public-IP>
```

### Step 3: Create the Website Content

**On your local machine**, create the website content:
```bash
mkdir webapp
cd webapp
nano index.html
```

- Add your HTML content to index.html.

### Step 4: Configure Ansible Inventory

- Create an inventory file named inventory.yml:
```yaml
all:
  hosts:
    worker:
      ansible_host: <Worker-VM-Public-IP>
      ansible_user: azureuser
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

- Test the connection:
```bash
ansible -i inventory.yml -m ping all

Step 5: Deploy the Website

- Create a playbook named deploy_website.yml:
```bash
---
- name: Deploy Website
  hosts: all
  become: yes
  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Start and enable Nginx
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Copy website files
      copy:
        src: webapp/index.html
        dest: /var/www/html/index.html
        owner: www-data
        group: www-data
        mode: '0644'
```

- Run the playbook:
```bash
ansible-playbook -i inventory.yml deploy_website.yml
```

### Step 6: Clean Up Resources

- Create a script named destroy_ansible_environment.sh to clean up the Azure resources:
```bash
#!/bin/bash

# Variables
RESOURCE_GROUP="ansible-r 
```
