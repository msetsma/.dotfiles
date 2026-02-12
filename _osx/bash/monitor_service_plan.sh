#!/bin/bash
set -euo pipefail

# Print usage to stderr
usage() {
    cat >&2 <<EOF
Usage:
  $0 <subscription-id> <resource-group> <app-service-plan-name> <metric>
  or
  $0 <config-file>

Config file should define:
  SUBSCRIPTION_ID
  RESOURCE_GROUP
  APP_SERVICE_PLAN_NAME
  METRIC
EOF
    exit 1
}

# Print error to stderr
error() {
    echo "Error: $*" >&2
}

# Check for required command
require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error "Required command '$1' not found in PATH."
        exit 1
    fi
}

require_command az

# Parse arguments or config file
if [ "$#" -eq 1 ]; then
    CONFIG_FILE="$1"
    if [ ! -f "$CONFIG_FILE" ]; then
        error "Config file '$CONFIG_FILE' not found."
        exit 1
    fi
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
elif [ "$#" -eq 4 ]; then
    SUBSCRIPTION_ID="$1"
    RESOURCE_GROUP="$2"
    APP_SERVICE_PLAN_NAME="$3"
    METRIC="$4"
else
    usage
fi

# Check required variables
missing_vars=()
[ -z "${SUBSCRIPTION_ID:-}" ] && missing_vars+=("SUBSCRIPTION_ID")
[ -z "${RESOURCE_GROUP:-}" ] && missing_vars+=("RESOURCE_GROUP")
[ -z "${APP_SERVICE_PLAN_NAME:-}" ] && missing_vars+=("APP_SERVICE_PLAN_NAME")
[ -z "${METRIC:-}" ] && missing_vars+=("METRIC")

if [ "${#missing_vars[@]}" -ne 0 ]; then
    error "Missing required variables: ${missing_vars[*]}"
    usage
fi

# Set the subscription
az account set --subscription "$SUBSCRIPTION_ID"

RESOURCE_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/serverfarms/$APP_SERVICE_PLAN_NAME"

echo "Querying metric '$METRIC' for App Service Plan '$APP_SERVICE_PLAN_NAME' in resource group '$RESOURCE_GROUP'..."

# Save the output to a file or variable
METRICS_JSON=$(az monitor metrics list \
    --resource "$RESOURCE_ID" \
    --metric "$METRIC" \
    --output json)

# Summarize with jq
echo "$METRICS_JSON" | jq '
.value[] | 
  {
    metric: .name.value,
    min: ([.timeseries[].data[].average] | map(select(. != null)) | min),
    max: ([.timeseries[].data[].average] | map(select(. != null)) | max),
        avg: ([.timeseries[].data[].average] 
          | map(select(. != null)) 
          | (add / length) 
          | (. * 100 | round) / 100)
  }
'