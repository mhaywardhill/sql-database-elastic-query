#!/usr/bin/env bash
# ============================================================================
# Deploy Hub-Spoke VNET topology with Azure SQL Private Endpoints
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Configuration — override via environment variables or edit defaults below
# ---------------------------------------------------------------------------
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-sql-elastic-query}"
LOCATION="${LOCATION:-uksouth}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-hub-spoke-sql-$(date +%Y%m%d%H%M%S)}"
PARAMETERS_FILE="${PARAMETERS_FILE:-${SCRIPT_DIR}/main.parameters.json}"

# ---------------------------------------------------------------------------
# Prompt for SQL admin password if not set
# ---------------------------------------------------------------------------
if [[ -z "${SQL_ADMIN_PASSWORD:-}" ]]; then
  read -rsp "Enter SQL admin password: " SQL_ADMIN_PASSWORD
  echo
fi

# ---------------------------------------------------------------------------
# Validate password is not empty
# ---------------------------------------------------------------------------
if [[ -z "$SQL_ADMIN_PASSWORD" ]]; then
  echo "ERROR: SQL admin password cannot be empty." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Ensure logged in to Azure
# ---------------------------------------------------------------------------
echo "Checking Azure CLI login..."
az account show --output none 2>/dev/null || {
  echo "Not logged in. Running 'az login'..."
  az login
}

echo "Subscription: $(az account show --query '{name:name, id:id}' -o tsv)"

# ---------------------------------------------------------------------------
# Create resource group
# ---------------------------------------------------------------------------
echo "Creating resource group '${RESOURCE_GROUP}' in '${LOCATION}'..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none

# ---------------------------------------------------------------------------
# Deploy Bicep template
# ---------------------------------------------------------------------------
echo "Starting deployment '${DEPLOYMENT_NAME}'..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --template-file "${SCRIPT_DIR}/main.bicep" \
  --parameters @"$PARAMETERS_FILE" \
  --parameters sqlAdminPassword="$SQL_ADMIN_PASSWORD" \
  --output table

echo ""
echo "=========================================="
echo " Deployment complete!"
echo "=========================================="

# Show outputs
az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --query 'properties.outputs' \
  --output table
