#!/usr/bin/env bash
set -euo pipefail

LOCATION="${1:-germanywestcentral}"

echo "Checking Azure VM usage/quota in: ${LOCATION}"
az vm list-usage --location "${LOCATION}" -o table

echo
echo "Checking candidate VM SKUs in: ${LOCATION}"
az vm list-skus \
  --location "${LOCATION}" \
  --resource-type virtualMachines \
  --query "[?contains(name, 'Standard_B') || contains(name, 'Standard_D') || contains(name, 'Standard_F')].[name, restrictions]" \
  -o table

echo
echo "Checking AKS versions in: ${LOCATION}"
az aks get-versions --location "${LOCATION}" -o table

echo
echo "Do not pick the AKS node size until quota and SKU availability are confirmed."
