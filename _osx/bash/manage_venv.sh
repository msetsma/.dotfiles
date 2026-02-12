# 

# --- Custom venv Manager Function ---
# This function manages a Python virtual environment (.venv)
# in the current directory. It's designed to be called by an alias.
# Add the alias 'alias venv="manage_project_venv"' after this function definition.

manage_project_venv() {
    # Configuration
    local venv_dir=".venv"
    local requirements_file="requirements.txt"
    local python_cmd="python3"

    local VENV_COLOR_RED='\033[0;31m'
    local VENV_COLOR_GREEN='\033[0;32m'
    local VENV_COLOR_YELLOW='\033[0;33m'
    local VENV_COLOR_BLUE='\033[0;34m'
    local VENV_COLOR_RESET='\033[0m'

    # Get the absolute path of the current directory for reliable comparison.
    local current_dir_abs=$(pwd)
    local expected_venv_path="$current_dir_abs/$venv_dir"

    # --- Check and manage the current state ---
    # Check if *any* virtual environment is currently active ($VIRTUAL_ENV is set).
    if [[ -n "$VIRTUAL_ENV" ]]; then
        # Check if the active environment is THIS project's venv.
        # Using [[ ]] for string comparison.
        if [[ "$VIRTUAL_ENV" == "$expected_venv_path" ]]; then
            # --- Case: This project's venv is already active ---
            echo -e "${VENV_COLOR_BLUE}▶️  Virtual environment '$venv_dir' is currently active.${VENV_COLOR_RESET}"
            echo -e "${VENV_COLOR_BLUE}⏹️  Deactivating...${VENV_COLOR_RESET}"
            deactivate
            # Using [[ ]] for condition check.
            if [[ -z "$VIRTUAL_ENV" ]]; then
                echo -e "${VENV_COLOR_GREEN}✅ '$venv_dir' successfully deactivated.${VENV_COLOR_RESET}"
            else
                echo -e "${VENV_COLOR_YELLOW}⚠️  Warning: Failed to fully deactivate.${VENV_COLOR_RESET}"
            fi
            # Exit the function (like 'return' in Python main) - NOT 'exit' which kills the shell!
            return 0
        else
            # --- Case: Another virtual environment is active ---
            echo -e "${VENV_COLOR_YELLOW}⚠️  Another virtual environment ('$(basename "$VIRTUAL_ENV")') is active.${VENV_COLOR_RESET}"
            echo -e "${VENV_COLOR_YELLOW}ℹ️  Proceeding to manage this project's '$venv_dir'. Activation below will override.${VENV_COLOR_RESET}"
        fi
    fi

    # --- Manage the target virtual environment directory ---
    # (Runs if no venv was active, or another venv was active)

    # Using [[ ]] for directory check.
    if [[ -d "$venv_dir" ]]; then
        # --- Case: The target venv directory exists ---
        echo -e "${VENV_COLOR_BLUE}📂 Virtual environment directory '$venv_dir' found.${VENV_COLOR_RESET}"

        # Using [[ ]] for file check.
        if [[ -f "$venv_dir/bin/activate" ]]; then
            echo -e "${VENV_COLOR_BLUE}🚀 Activating '$venv_dir'...\033[0m" # \033[0m resets color after emoji
            # Source the activation script. CRUCIAL: Affects the current shell!
            source "$venv_dir/bin/activate"

            # Verify activation success. Using [[ ]] with && for combined conditions.
            if [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$expected_venv_path" ]]; then
                echo -e "${VENV_COLOR_GREEN}✅ Virtual environment '$venv_dir' activated successfully.${VENV_COLOR_RESET}"
            else
                echo -e "${VENV_COLOR_RED}❌ Error: Found '$venv_dir', but failed to activate it.${VENV_COLOR_RESET}"
                echo -e "${VENV_COLOR_RED}   Please check the contents of '$venv_dir/bin/activate'.${VENV_COLOR_RESET}"
                return 1
            fi
        else
            echo -e "${VENV_COLOR_RED}❌ Error: '$venv_dir' exists but does not seem to be a valid venv (missing activate script).${VENV_COLOR_RESET}"
            echo -e "${VENV_COLOR_RED}   Please remove '$venv_dir' manually and try again.${VENV_COLOR_RESET}"
            return 1
        fi

    else
        # --- Case: The target venv directory does NOT exist ---
        echo -e "${VENV_COLOR_BLUE}✨ Virtual environment directory '$venv_dir' not found. Creating...${VENV_COLOR_RESET}"

        # Check if the Python command is available. (command -v is external, keep as is)
        if ! command -v "$python_cmd" &>/dev/null; then
            echo -e "${VENV_COLOR_RED}❌ Error: Python command '$python_cmd' not found.${VENV_COLOR_RESET}"
            echo -e "${VENV_COLOR_RED}   Please ensure Python is installed and in your PATH.${VENV_COLOR_RESET}"
            return 1
        fi

        # Create the virtual environment.
        "$python_cmd" -m venv "$venv_dir"

        # Check if venv creation was successful. Using [[ ]] for status check.
        if [[ $? -ne 0 ]]; then
            echo -e "${VENV_COLOR_RED}❌ Error: Failed to create virtual environment in '$venv_dir'.${VENV_COLOR_RESET}"
            return 1
        fi

        echo -e "${VENV_COLOR_GREEN}✅ Virtual environment created.${VENV_COLOR_RESET}"
        echo -e "${VENV_COLOR_BLUE}🚀 Activating '$venv_dir'...\033[0m"
        # Using [[ ]] for file check.
        if [[ -f "$venv_dir/bin/activate" ]]; then
            # Source the activation script from the newly created venv.
            source "$venv_dir/bin/activate"
            # Verify activation success. Using [[ ]] with && for combined conditions.
            if [[ -n "$VIRTUAL_ENV" && "$VIRTUAL_ENV" == "$expected_venv_path" ]]; then
                echo -e "${VENV_COLOR_GREEN}✅ Virtual environment '$venv_dir' activated successfully.${VENV_COLOR_RESET}"
            else
                echo -e "${VENV_COLOR_RED}❌ Error: Created '$venv_dir', but failed to activate it.${VENV_COLOR_RESET}"
                echo -e "${VENV_COLOR_RED}   Please check the contents of '$venv_dir/bin/activate'.${VENV_COLOR_RESET}"
                return 1
            fi
        else
            echo -e "${VENV_COLOR_RED}❌ Error: Venv '$venv_dir' created, but activate script is missing.${VENV_COLOR_RESET}"
            echo -e "${VENV_COLOR_RED}   Please investigate or remove '$venv_dir' manually.${VENV_COLOR_RESET}"
            return 1
        fi
    fi

    # -------------------------------------------------------------------
    # Install requirements if requirements.txt exists
    # (Runs only after successful activation)
    # -------------------------------------------------------------------

    # Using [[ ]] for file check.
    if [[ -f "$requirements_file" ]]; then
        echo -e "${VENV_COLOR_BLUE}📦 Found requirements file '$requirements_file'.${VENV_COLOR_RESET}"
        echo -e "${VENV_COLOR_BLUE}⬇️  Installing packages from '$requirements_file'...${VENV_COLOR_RESET}"

        # Use the pip from the activated environment.
        pip install -r "$requirements_file"

        # Check if pip installation was successful. Using [[ ]] for status check.
        if [[ $? -ne 0 ]]; then
            echo -e "${VENV_COLOR_YELLOW}⚠️  Warning: Failed to install requirements from '$requirements_file'.${VENV_COLOR_RESET}"
            echo -e "${VENV_COLOR_YELLOW}   Please check the output above for details.${VENV_COLOR_RESET}"
        else
            echo -e "${VENV_COLOR_GREEN}✅ Requirements installed successfully.${VENV_COLOR_RESET}"
        fi
    else
        # No requirements file found.
        echo -e "${VENV_COLOR_BLUE}ℹ️  No requirements file ('$requirements_file') found. Skipping package installation.${VENV_COLOR_RESET}"
    fi

    # -------------------------------------------------------------------
    # Function finished.
    # -------------------------------------------------------------------
    return 0 # Indicate successful function execution.
}