import os
import sys
import subprocess
import platform

def activate_environment(env_name, requirements_file):
    """Activates a virtual environment and installs dependencies from a requirements.txt file."""
    # Determine the platform and set the activation command
    activate_cmd = ""
    if platform.system() == "Windows":
        activate_cmd = f"{env_name}\\Scripts\\activate"
    else:
        activate_cmd = f"source {env_name}/bin/activate"

    try:
        # Check if the virtual environment exists
        if not os.path.exists(env_name):
            print(f"Creating virtual environment: {env_name}")
            subprocess.check_call([sys.executable, "-m", "venv", env_name])
        else:
            print(f"Virtual environment '{env_name}' already exists.")

        # Activate the virtual environment
        print("Activating the virtual environment...")
        activation_script = os.path.join(env_name, "Scripts" if platform.system() == "Windows" else "bin", "activate")
        if not os.path.isfile(activation_script):
            raise FileNotFoundError(f"Activation script not found at {activation_script}")
        
        print(f"Installing dependencies from {requirements_file}...")
        # Install dependencies
        subprocess.check_call([os.path.join(env_name, "Scripts" if platform.system() == "Windows" else "bin", "pip"), "install", "-r", requirements_file])
        print("All dependencies have been installed successfully!")

    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    # Specify the virtual environment name and requirements file
    ENV_NAME = "env"  # Change this if you want a different name for your environment
    REQUIREMENTS_FILE = "requirements.txt"  # Update if your file is named differently

    # Check if requirements.txt exists
    if not os.path.exists(REQUIREMENTS_FILE):
        print(f"Error: {REQUIREMENTS_FILE} not found in the current directory.")
        sys.exit(1)

    activate_environment(ENV_NAME, REQUIREMENTS_FILE)
