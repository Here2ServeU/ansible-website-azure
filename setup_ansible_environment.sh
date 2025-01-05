Here’s the updated bash script to add two additional VMs (Debian and CentOS) to the Ansible cluster:

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
DEBIAN_VM="ansible-worker-debian"
CENTOS_VM="ansible-worker-centos"

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
az network public-ip create --resource-group $RESOURCE_GROUP --name ${DEBIAN_VM}-pip --allocation-method Static
az network public-ip create --resource-group $RESOURCE_GROUP --name ${CENTOS_VM}-pip --allocation-method Static

# Create Network Interfaces
az network nic create --resource-group $RESOURCE_GROUP --name ${CONTROLLER_VM}-nic --vnet-name $VNET_NAME --subnet $SUBNET_NAME --network-security-group $NSG_NAME --public-ip-address ${CONTROLLER_VM}-pip
az network nic create --resource-group $RESOURCE_GROUP --name ${WORKER_VM}-nic --vnet-name $VNET_NAME --subnet $SUBNET_NAME --network-security-group $NSG_NAME --public-ip-address ${WORKER_VM}-pip
az network nic create --resource-group $RESOURCE_GROUP --name ${DEBIAN_VM}-nic --vnet-name $VNET_NAME --subnet $SUBNET_NAME --network-security-group $NSG_NAME --public-ip-address ${DEBIAN_VM}-pip
az network nic create --resource-group $RESOURCE_GROUP --name ${CENTOS_VM}-nic --vnet-name $VNET_NAME --subnet $SUBNET_NAME --network-security-group $NSG_NAME --public-ip-address ${CENTOS_VM}-pip

# Create VMs
az vm create --resource-group $RESOURCE_GROUP --name $CONTROLLER_VM --size $VM_SIZE --nics ${CONTROLLER_VM}-nic --image UbuntuLTS --admin-username $ADMIN_USERNAME --ssh-key-values $SSH_KEY_PATH
az vm create --resource-group $RESOURCE_GROUP --name $WORKER_VM --size $VM_SIZE --nics ${WORKER_VM}-nic --image UbuntuLTS --admin-username $ADMIN_USERNAME --ssh-key-values $SSH_KEY_PATH
az vm create --resource-group $RESOURCE_GROUP --name $DEBIAN_VM --size $VM_SIZE --nics ${DEBIAN_VM}-nic --image Debian --admin-username $ADMIN_USERNAME --ssh-key-values $SSH_KEY_PATH
az vm create --resource-group $RESOURCE_GROUP --name $CENTOS_VM --size $VM_SIZE --nics ${CENTOS_VM}-nic --image CentOS --admin-username $ADMIN_USERNAME --ssh-key-values $SSH_KEY_PATH

# Output Public IP Addresses
echo "Controller VM Public IP:"
az vm list-ip-addresses --resource-group $RESOURCE_GROUP --name $CONTROLLER_VM --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" --output tsv

echo "Worker VM Public IP:"
az vm list-ip-addresses --resource-group $RESOURCE_GROUP --name $WORKER_VM --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" --output tsv

echo "Debian Worker VM Public IP:"
az vm list-ip-addresses --resource-group $RESOURCE_GROUP --name $DEBIAN_VM --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" --output tsv

echo "CentOS Worker VM Public IP:"
az vm list-ip-addresses --resource-group $RESOURCE_GROUP --name $CENTOS_VM --query "[].virtualMachine.network.publicIpAddresses[].ipAddress" --output tsv

echo "Ansible environment setup with additional VMs (Debian and CentOS) is complete!"

Notes:
	1.	This script creates four VMs: the controller node, a worker node running Ubuntu, a worker node running Debian, and a worker node running CentOS.
	2.	Public IP addresses are output for all VMs for use in inventory files.
	3.	The SSH key path ($HOME/.ssh/id_rsa.pub) should match the key used for accessing these VMs. Update if necessary.
