#!/bin/bash

# Variables
RESOURCE_GROUP="ansible-rg"
LOCATION="eastus"

# Step 1: Delete Resource Group
echo "Deleting Resource Group: $RESOURCE_GROUP..."
az group delete --name $RESOURCE_GROUP --yes --no-wait
echo "Resource Group deletion initiated."

# Step 2: Clean up local Ansible environment
echo "Cleaning up local Ansible environment..."
rm -f ~/inventory.yml 2>/dev/null
rm -f ~/deploy_website.yml 2>/dev/null
rm -rf ~/ansible/ 2>/dev/null
echo "Local Ansible environment cleaned up."

echo "All resources and local files have been scheduled for deletion."
