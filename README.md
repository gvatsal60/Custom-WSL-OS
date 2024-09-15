# Custom WSL OS

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://img.shields.io/github/license/gvatsal60/Custom-WSL-OS)
[![Build and Push Docker Image](https://github.com/gvatsal60/Custom-WSL-OS/actions/workflows/docker-img-push.yaml/badge.svg)](https://github.com/gvatsal60/Custom-WSL-OS/actions/workflows/docker-img-push.yaml)
[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/gvatsal60/Custom-WSL-OS/master.svg)](https://results.pre-commit.ci/latest/github/gvatsal60/Custom-WSL-OS/HEAD)
![GitHub pull-requests](https://img.shields.io/github/issues-pr/gvatsal60/Custom-WSL-OS)
![GitHub Issues](https://img.shields.io/github/issues/gvatsal60/Custom-WSL-OS)
![GitHub forks](https://img.shields.io/github/forks/gvatsal60/Custom-WSL-OS)
![GitHub stars](https://img.shields.io/github/stars/gvatsal60/Custom-WSL-OS)

Welcome! This guide will walk you through the process of setting up Windows Subsystem for Linux (WSL) with a custom image.

## Prerequisites

1. Windows Version: Ensure you're running Windows 10 version 1903 or later, or Windows 11

2. WSL Installed: If you haven't installed WSL yet, follow the instructions on Microsoft's official [WSL documentation](https://learn.microsoft.com/en-us/windows/wsl/install) before proceeding

3. Custom Ubuntu Image: You should have your custom Ubuntu image ready in .tar format

4. Docker: Ensure Docker and Docker Compose are installed on your system. Follow Docker’s [installation instructions](https://docs.docker.com/engine/install/) if you haven't installed Docker yet.

### Steps for Installation

1. Install WSL and Ubuntu

   If you haven’t already installed WSL, you can do so with the following steps:

   1. Open PowerShell as Administrator:
      Right-click the Start menu and select "Windows PowerShell (Admin)"

   2. Install WSL:

      ```sh
       wsl --install
      ```

      This command will install the WSL feature and download the default Linux distribution.

   3. Restart Your Computer:
      A restart may be required for the WSL feature to be fully installed.

2. Download and Install the Custom Ubuntu Image

   1. Open PowerShell as Administrator:

      - Ensure you're running PowerShell with administrative privileges.

   2. Import the Custom Image:

      - Replace `path\to\your\custom-image.tar` with the path to your custom Ubuntu .tar image and YourCustomUbuntu with a name for your WSL instance.

        ```sh
        wsl --import YourCustomUbuntu path\to\installation\folder path\to\your\custom-image.tar
        ```

      - YourCustomUbuntu: The name you assign to your WSL instance.

      - `path\to\installation\folder`: Directory where you want to store the WSL instance. For example, `C:\WSL\YourCustomUbuntu`

   3. Set Default Distribution (Optional):

      - If you want to make your custom image the default WSL distribution, run:

        ```sh
        wsl --set-default YourCustomUbuntu
        ```

   4. Launch Your Custom Ubuntu Instance:

      You can now start your custom Ubuntu instance with:

      ```sh
      wsl -d YourCustomUbuntu
      ```

3. Verify the Installation

   1. Check WSL Versions:

      - To verify that your custom image is installed and recognized, you can list your WSL distributions:

        ```sh
        wsl -l -v
        ```

      This command will list all installed WSL distributions and their versions.

   2. Verify Ubuntu Version:

   - Inside your WSL terminal, check the Ubuntu version to ensure it’s correctly installed:

     ```sh
     lsb_release -a
     ```

4. Troubleshooting

   - Custom Image Issues: If you encounter issues with your custom image, ensure that the .tar file is valid and not corrupted. You might need to recreate or download a fresh version.

   - Permissions: Ensure you have the necessary permissions for the directory where you are installing the WSL instance.

   - Update WSL: Make sure your WSL installation is up-to-date:

     ```sh
     wsl --update
     ```

5. Build and Run with Docker Compose

   Open a terminal (PowerShell or Command Prompt) and navigate to the directory containing docker-compose.yml.

   Build and run the Docker containers:

   ```sh
   docker-compose up --build
   ```

   This command will build the Docker image according to the Dockerfile and start the container as specified in docker-compose.yml.

## Additional Resources

[Microsoft WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)

[Ubuntu WSL Guide](https://ubuntu.com/wsl)

[Troubleshooting WSL](https://docs.microsoft.com/en-us/windows/wsl/install-troubleshoot)

## Contributing

Contributions are welcome! Please read our
[Contribution Guidelines](https://github.com/gvatsal60/Custom-WSL-OS/blob/HEAD/CONTRIBUTING.md)
before submitting pull requests.

## License

This project is licensed under the Apache License 2.0 License - see the
[LICENSE](https://github.com/gvatsal60/Custom-WSL-OS/blob/HEAD/LICENSE) file for details.
