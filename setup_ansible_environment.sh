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
