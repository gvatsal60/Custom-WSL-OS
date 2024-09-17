#!/bin/dash

##########################################################################################
# File: alpine-util.sh
# Author: Vatsal Gupta (gvatsal60)
# Date: 17-Sep-2024
# Description:
# This script contains utility functions and common operations for managing
# a Alpine-based system. It includes functions for system maintenance,
# package management, and configuration tasks. The script is designed to
# simplify and automate common administrative tasks, ensuring a consistent
# setup across multiple Alpine-based environments.
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

# Set non-interactive mode (not strictly necessary for apk, but included for completeness)
export APK_INTERACTIVE="false"

# Select the en_US.UTF-8 UTF-8 locale is available
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Set default username if not provided as an argument
USERNAME=${1:-"root"}
USER_UID=${2:-"root"}
USER_GID=${3:-"root"}

# .bashrc snippet
rc_snippet="$(
    cat <<'EOF'

# Add bin path
if [[ "${PATH}" != *"${HOME}/.local/bin"* ]]; then
    export PATH="${PATH}:${HOME}/.local/bin";
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
alias sou='. ${HOME}/.profile'

# Add 'update' as an alias in 'bash_history'
echo -e 'update' >> ${HOME}/.ash_history

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

##########################################################################################
# Main Script
##########################################################################################

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    print_err "==> Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script."
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
# rm -f /etc/profile.d/00-restore-env.sh
# echo "export PATH=${PATH//$(sh -lc "echo \$PATH")/\$PATH}" > /etc/profile.d/00-restore-env.sh
# chmod +x /etc/profile.d/00-restore-env.sh

# Update rc-service
if type rc-update >/dev/null 2>&1; then
    rc-update add docker
else
    print_err "==> Error: Unsupported or unrecognized service."
fi

# Ensure at least the en_US.UTF-8 UTF-8 locale is available.
if [ "${LOCALE_ALREADY_SET}" != "true" ]; then
    println 'export LC_ALL=en_GB.UTF-8' >>/etc/profile.d/locale.sh
    sed -i 's|LANG=C.UTF-8|LANG=en_GB.UTF-8|' /etc/profile.d/locale.sh
    locale
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
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/${USERNAME}" >/dev/null
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
if id "${USERNAME}" >/dev/null 2>&1; then
    println "${rc_snippet}" >>"${user_rc_path}/.profile"
    println 'export PROMPT_DIRTRIM=4' >>"${user_rc_path}/.profile"
    chown "${USERNAME}":"${group_name}" "${user_rc_path}/.profile"
else
    println "${rc_snippet}" >>/etc/profile
fi

# Configure WSL Startup Script
println "${WSL_CONF}" >"${WSL_CONF_PATH}"
