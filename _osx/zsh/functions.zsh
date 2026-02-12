rld() {
    echo "Reloading Zsh configuration..."
    exec zsh
}

update() {
    echo "Updating Homebrew and installed packages..."
    brew update && brew upgrade && (brew cleanup || true)
    
    echo "Updating Rust toolchain..."
    rustup update
    
    echo "Updating Cargo packages..."
    cargo install $(cargo install --list | grep -E '^\w' | cut -d' ' -f1)
    
    echo "All updates completed."
}

# Function to source all .sh or .zsh files in a given directory
# Usage: source_folder_contents /path/to/folder
source_folder_contents() {
    # Check for the correct number of arguments
    if [ $# -ne 1 ]; then
        return 1
    fi

    local target_dir="$1"
    target_dir=${=target_dir}
    [[ "$target_dir" != */ ]] && target_dir="$target_dir/"

    # Check if the target is a valid directory and exists
    if [ ! -d "$target_dir" ]; then
        echo "Error: '$target_dir' is not a valid directory or does not exist." >&2 # Send error to stderr
        return 1
    fi

    local sourced_count=0
    local error_count=0
    local file_found=false # Flag to check if any files were considered

    # Temporarily disable the 'nomatch' option so the glob doesn't cause an error
    local original_options="$(setopt | grep nomatch)" # Capture current state
    setopt nonomatch

    # Loop through files ending in .sh or .zsh within the directory.
    for script_file in "${target_dir}"*.sh "${target_dir}"*.zsh; do
        # Check if the file exists and is a regular file
        if [ -f "$script_file" ]; then # <--- This is line ~39/40/41 depending on formatting
            file_found=true # Indicate we found at least one file to consider
            # *** CHANGED THIS LINE BACK TO JUST 'source' ***
            if source "$script_file"; then # <--- This is line ~43 in your error message
                ((sourced_count++))
            else
                echo "  Error sourcing $script_file" >&2 # Send error to stderr
                ((error_count++))
            fi
        fi
    done

    # Restore the original 'nomatch' option state
    if [[ "$original_options" == "nonomatch" ]]; then
       setopt nonomatch # Was originally off
    else
       setopt nomatch # Was originally on (or not explicitly set, which defaults to on)
    fi

    # Return status code: 0 for success (or no errors), 1 for errors during sourcing
    if [ $error_count -gt 0 ]; then
        return 1
    else
        return 0
    fi
}

# Get Azure Function App info interactively
az-func-info() {
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        echo "Error: Azure CLI not installed"
        return 1
    fi

    # Check if logged in
    if ! az account show &> /dev/null; then
        echo "Error: Not logged into Azure CLI. Run 'az login'"
        return 1
    fi

    # Check if fzf is installed
    if ! command -v fzf &> /dev/null; then
        echo "Error: fzf not installed (brew install fzf)"
        return 1
    fi

    echo "Fetching function apps..."
    
    # Get list of function apps with resource group for context
    local func_list=$(az functionapp list --query "[].{name:name, rg:resourceGroup}" -o tsv)
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to fetch function apps from Azure"
        return 1
    fi
    
    if [ -z "$func_list" ]; then
        echo "No function apps found in current subscription"
        local current_sub=$(az account show --query name -o tsv)
        echo "Current subscription: $current_sub"
        echo ""
        echo "Available subscriptions:"
        az account list --query "[].{name:name, id:id, isDefault:isDefault}" -o table
        return 1
    fi

    # Let user select with fzf (shows name and resource group)
    local selection=$(echo "$func_list" | fzf --prompt="Select Function App: " --height=40% --layout=reverse --header="NAME | RESOURCE GROUP")
    
    if [ -z "$selection" ]; then
        echo "No selection made"
        return 0
    fi

    # Extract function app name and resource group
    local func_name=$(echo "$selection" | awk '{print $1}')
    local rg=$(echo "$selection" | awk '{print $2}')
    
    echo "Getting info for: $func_name"
    echo "================================"
    
    echo "Resource Group: $rg"
    
    # Get location
    local location=$(az functionapp show -n "$func_name" -g "$rg" --query location -o tsv 2>/dev/null)
    echo "Location: $location"
    
    # Get app service plan
    local asp=$(az functionapp show -n "$func_name" -g "$rg" --query appServicePlanId -o tsv 2>/dev/null | awk -F'/' '{print $NF}')
    echo "App Service Plan: $asp"
    
    # Get storage account from app settings
    local storage=$(az functionapp config appsettings list -n "$func_name" -g "$rg" --query "[?name=='AzureWebJobsStorage'].value" -o tsv 2>/dev/null | rg -o 'AccountName=([^;]+)' -r '$1')
    echo "Storage Account: $storage"
    
    # Get subscription ID
    local sub_id=$(az account show --query id -o tsv 2>/dev/null)
    echo "Subscription ID: $sub_id"
    
    # Get function app URL
    local url=$(az functionapp show -n "$func_name" -g "$rg" --query defaultHostName -o tsv 2>/dev/null)
    echo "URL: https://$url"

    
    echo "================================"
    echo ""
    echo "Config snippet for pipelines/config.yml:"
    echo "  environment_name:"
    echo "    azureSubscription: 'your-service-connection'"
    echo "    resourceGroup: '$rg'"
    echo "    location: '$location'"
    echo "    functionAppName: '$func_name'"
    echo "    storageAccountName: '$storage'"
    echo "    appServicePlanName: '$asp'"
}