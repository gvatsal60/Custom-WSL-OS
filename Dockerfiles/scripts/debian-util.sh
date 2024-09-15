#!/bin/bash

##########################################################################################
# File: debian-util.sh
# Author: Vatsal Gupta (gvatsal60)
# Date: 14-Sep-2024
# Description:
# This script contains utility functions and common operations for managing
# a Debian-based system. It includes functions for system maintenance,
# package management, and configuration tasks. The script is designed to
# simplify and automate common administrative tasks, ensuring a consistent
# setup across multiple Debian-based environments.
##########################################################################################

##########################################################################################
# License
##########################################################################################
# This script is licensed under the Apache 2.0 License.

##########################################################################################
# Constants
##########################################################################################
# Exit the script immediately if any command fails
set -e

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Set default username if not provided as an argument
USERNAME=${1:-"root"}
USER_UID=${2:-"root"}
USER_GID=${3:-"root"}

# .bashrc snippet
rc_snippet="$(
    cat <<'EOF'

# Add bin path
if [[ "${PATH}" != *"$HOME/.local/bin"* ]]; then
    export PATH="${PATH}:$HOME/.local/bin";
fi

# Define colors
COLOR_USR='\[\033[01;32m\]'  # User color
COLOR_DIR='\[\033[01;34m\]'  # Directory color
COLOR_GIT='\[\033[01;36m\]'  # Git branch color
COLOR_DEF='\[\033[00m\]'     # Default color
NEWLINE='\n'                 # Newline character

# Function to parse git branch (if available)
parse_git_branch() {
    git branch 2>/dev/null | grep \* | awk '{print " (" $2 ") "}'
}

# Set the PS1 prompt
PS1="${COLOR_USR}\u@\h ${COLOR_DIR}\w ${COLOR_GIT}\$(parse_git_branch)${COLOR_DEF}${NEWLINE}\$ "

# Personal Aliases
alias sou='source ~/.bashrc'

# Add 'update' as an alias in 'bash_history'
echo -e 'update' >> ~/.bash_history

EOF
)"

# WSL Configuration
readonly WSL_CONF_PATH="/etc/wsl.conf"

WSL_CONF="$(
    cat <<EOF

# Set whether WSL supports interop processes like launching Windows apps and adding path variables.
# Setting these to false will block the launch of Windows processes and block adding 'PATH' environment variables.
[interop]
enabled = true
appendWindowsPath = true

# Set the user when launching a distribution with WSL.
[user]
default = ${USERNAME}

# Set a command to run when a new WSL instance launches.
[boot]
command = service docker start

EOF
)"

##########################################################################################
# Functions
##########################################################################################
# Function: println
# Description: Prints each argument on a new line, suppressing any error messages.
println() {
    command printf %s\\n "$*" 2>/dev/null
}

# Function: print_err
# Description: : Prints each argument on a new line to the standard error stream (stderr),
#                while suppressing any error messages from printf
print_err() {
    printf "%s\n" "$*" 2>/dev/null >&2
}

# Function: docker_install
# Description: Installs Docker and Docker Compose on a Debian-based system.
docker_install() {
    # Add Docker's official GPG key:
    apt-get update
    apt-get -y install --no-install-recommends ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    # shellcheck source=/dev/null
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    apt-get update
    apt-get -y install --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    println "==> Docker is successfully installed."
}

##########################################################################################
# Main Script
##########################################################################################

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    print_err "==> Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script."
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" >/etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Install Required Packages
if type apt-get >/dev/null 2>&1; then
    docker_install
    apt-get -y upgrade --no-install-recommends
    apt-get -y autoremove
else
    print_err "==> Error: Unsupported or unrecognized package manager"
fi

# Ensure at least the en_US.UTF-8 UTF-8 locale is available.
if [ "${LOCALE_ALREADY_SET}" != "true" ] && ! grep -o -E '^\s*en_US.UTF-8\s+UTF-8' /etc/locale.gen >/dev/null; then
    println "en_US.UTF-8 UTF-8" >>/etc/locale.gen
    locale-gen
    LOCALE_ALREADY_SET="true"
fi

# Create or update a non-root user to match UID/GID.
group_name="${USERNAME}"

# Check if the user exists
if id -u "${USERNAME}" >/dev/null 2>&1; then
    # User exists, update if needed
    current_gid=$(id -g "${USERNAME}")
    current_uid=$(id -u "${USERNAME}")

    if [ -n "${USER_GID}" ] && [ "${USER_GID}" -ne "${current_gid}" ]; then
        group_name="$(id -gn "${USERNAME}")"
        groupmod --gid "${USER_GID}" "${group_name}"
        usermod --gid "${USER_GID}" "${USERNAME}"
    fi

    if [ -n "${USER_UID}" ] && [ "${USER_UID}" -ne "${current_uid}" ]; then
        usermod --uid "${USER_UID}" "${USERNAME}"
    fi
else
    # Create user
    if [ -n "${USER_GID}" ]; then
        groupadd --gid "${USER_GID}" "${USERNAME}"
    else
        groupadd "${USERNAME}"
    fi

    if [ -n "${USER_UID}" ]; then
        useradd -s /bin/bash --uid "${USER_UID}" --gid "${USERNAME}" -m "${USERNAME}"
    else
        useradd -s /bin/bash --gid "${USERNAME}" -m "${USERNAME}"
    fi
fi

# Add sudo support for non-root user
if [ "${USERNAME}" != "root" ] && [ "${EXISTING_NON_ROOT_USER}" != "${USERNAME}" ]; then
    # Create or update the sudoers file with the correct configuration
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/${USERNAME}" > /dev/null
    chmod 0440 "/etc/sudoers.d/${USERNAME}"
    EXISTING_NON_ROOT_USER="${USERNAME}"
fi

# Add ${USER} to 'docker' group if the group exists
if getent group docker >/dev/null; then
    usermod -aG docker "${USERNAME}"
else
    print_err "==> Error: 'docker' group does not exist."
    exit 1
fi

# Shell customization section
if [ "${USERNAME}" = "root" ]; then
    user_rc_path="/root"
else
    user_rc_path="/home/${USERNAME}"
fi

# Restore user .bashrc defaults from skeleton file if it doesn't exist or is empty
if [ ! -f "${user_rc_path}/.bashrc" ] || [ ! -s "${user_rc_path}/.bashrc" ]; then
    cp /etc/skel/.bashrc "${user_rc_path}/.bashrc"
fi

# Restore user .profile defaults from skeleton file if it doesn't exist or is empty
if [ ! -f "${user_rc_path}/.profile" ] || [ ! -s "${user_rc_path}/.profile" ]; then
    cp /etc/skel/.profile "${user_rc_path}/.profile"
fi

# Add RC snippet and custom bash prompt
# Check if the user exists
if id "${USERNAME}" &>/dev/null; then
    println "${rc_snippet}" >>"${user_rc_path}/.bashrc"
    println 'export PROMPT_DIRTRIM=4' >>"${user_rc_path}/.bashrc"
    chown "${USERNAME}":"${group_name}" "${user_rc_path}/.bashrc"
else
    println "${rc_snippet}" >>/etc/bash.bashrc
fi

# Configure WSL Startup Script
println "${WSL_CONF}" >"${WSL_CONF_PATH}"
