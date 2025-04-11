# Terraform Ansible Portainer Deployment on Proxmox VE

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) This repository contains Terraform and Ansible code to automate the deployment of Portainer CE/BE on a virtual machine within a Proxmox VE environment. Terraform provisions the VM from a template, and Ansible configures the server, installs Docker, and deploys Portainer.

## Overview

The goal of this project is to provide a repeatable and automated way to set up a Portainer instance on Proxmox VE.

* **Terraform:** Handles infrastructure creation on Proxmox VE, including:
    * Cloning a VM from a specified template.
    * Configuring VM resources (CPU, memory, disk).
    * Setting up network interfaces.
    * [Add other Terraform tasks specific to your setup, e.g., firewall rules if managing Proxmox firewall]
* **Ansible:** Configures the provisioned VM, including:
    * System updates.
    * Setting hostname.
    * Docker installation.
    * Portainer container deployment.
    * [Add any other specific configuration steps Ansible performs]

## Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Terraform:** [Link to Terraform Installation Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) (Requires v1.0 or later for most Proxmox providers)
2.  **Ansible:** [Link to Ansible Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
3.  **Proxmox VE Environment:**
    * Access to a running Proxmox VE server or cluster.
    * A **VM template** configured in Proxmox (usually Debian/Ubuntu/CentOS based) with `cloud-init` support and the QEMU Guest Agent installed. This template will be cloned by Terraform.
    * A **Proxmox API Token** or user credentials with sufficient permissions to create and manage VMs. [Link to Proxmox API Token Documentation](https://pve.proxmox.com/wiki/User_Management#pveum_tokens)
4.  **Terraform Provider for Proxmox:** The configuration likely uses a provider like `telmate/proxmox` or the official `Proxmox/proxmox` provider. `terraform init` will handle the installation.
5.  **SSH Key Pair:** An SSH key pair. The public key should be configured within your Proxmox VM template (often via `cloud-init`) or passed via Terraform variables so the provisioned VM includes it for the specified user. The private key is needed for Ansible to connect.
6.  **Git:** To clone this repository.

## Setup and Usage

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/kitepow-dev/terraform_ansible_portainer_deployment.git](https://github.com/kitepow-dev/terraform_ansible_portainer_deployment.git)
    cd terraform_ansible_portainer_deployment
    ```

2.  **Configure Terraform Variables:**
    * Review the variables defined in `variables.tf`.
    * Create a `terraform.tfvars` file (or use environment variables prefixed with `TF_VAR_`) to set your desired values. **Do not commit sensitive data like API tokens directly into Git.** Consider using environment variables for secrets.
    * Key variables likely include:
        * `pm_api_url`: URL of your Proxmox API (e.g., `https://proxmox-server:8006/api2/json`).
        * `pm_api_token_id`: Your Proxmox API Token ID (e.g., `root@pam!terraform`).
        * `pm_api_token_secret`: Your Proxmox API Token Secret (Set this via environment variable `TF_VAR_pm_api_token_secret` for security).
        * `proxmox_node`: The target Proxmox node name where the VM will be created.
        * `template_name`: The name of the VM template in Proxmox to clone from.
        * `vm_name`: Desired hostname/name for the new VM.
        * `vm_cores`, `vm_memory`, `vm_disk_size`: VM resource allocation.
        * `ssh_public_key`: The public SSH key content to be added to the VM (if not handled by the template directly).
        * `network_bridge`: Proxmox network bridge (e.g., `vmbr0`).
        * [Add any other crucial Terraform variables specific to your Proxmox setup]
    * *Example `terraform.tfvars` (Secrets should ideally be environment variables):*
        ```hcl
        # Example - replace with your actual values
        pm_api_url      = "[https://pve.yourdomain.local:8006/api2/json](https://pve.yourdomain.local:8006/api2/json)"
        pm_api_token_id = "terraform@pve!mytoken"
        # pm_api_token_secret should be set as environment variable: export TF_VAR_pm_api_token_secret='YOUR_SECRET_TOKEN'
        proxmox_node    = "pve-node-1"
        template_name   = "ubuntu-2204-cloudinit-template"
        vm_name         = "portainer-vm"
        vm_cores        = 2
        vm_memory       = 2048 # MB
        vm_disk_size    = 20   # GB
        network_bridge  = "vmbr0"
        ssh_public_key  = "ssh-rsa AAAAB3NzaC1yc2..." # Or use file("~/.ssh/id_rsa.pub")
        ```

3.  **Configure Ansible Variables:**
    * Review Ansible variables, typically found in `ansible/group_vars/all.yml` or related inventory files.
    * Ensure Ansible knows how to connect to the newly created VM. Terraform might generate an inventory file, or you might need to configure it based on Terraform outputs.
    * Key variables might include:
        * `ansible_user`: The user configured in your VM template (e.g., `ubuntu`, `debian`).
        * `ansible_ssh_private_key_file`: Path to the private SSH key corresponding to the public key used.
        * `portainer_version`: Specific Portainer version to install.
        * `portainer_data_volume_path`: Path on the VM for Portainer persistent data (e.g., `/var/lib/portainer_data`).
    * *Note:* Use Ansible Vault for sensitive data if needed.

4.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
    This downloads the Proxmox provider plugin and any other required providers.

5.  **Plan the Deployment (Optional but Recommended):**
    ```bash
    terraform plan -out=tfplan
    ```
    Review the output to see the VM and related resources Terraform will create or modify in Proxmox.

6.  **Apply the Configuration:**
    ```bash
    # Make sure the API secret is set as an environment variable first!
    # export TF_VAR_pm_api_token_secret='YOUR_SECRET_TOKEN'

    terraform apply "tfplan"
    # Or, if you skipped the plan step:
    # terraform apply --auto-approve
    ```
    Terraform will interact with the Proxmox API to clone the template and configure the VM. If configured (e.g., using Terraform's `remote-exec` provisioner, `local-exec` calling Ansible, or the Ansible provider with dynamic inventory), Terraform will trigger the Ansible playbook to configure the VM and deploy Portainer once the VM is ready.

7.  **Access Portainer:**
    * Once `terraform apply` completes, find the IP address of the created VM. This might be output by Terraform or visible in the Proxmox console/via `qm config <VMID>`. Cloud-init often takes a minute or two to assign the IP after the VM starts.
    * Open your web browser and navigate to: `http://<VM_IP_ADDRESS>:9000` (or `https://<VM_IP_ADDRESS>:9443` if using HTTPS/Portainer's default self-signed cert).
    * Follow the Portainer initial setup instructions to create your admin user.

## Architecture / Workflow

1.  User ensures `TF_VAR_pm_api_token_secret` is set and runs `terraform apply`.
2.  Terraform communicates with the Proxmox VE API (`pm_api_url`) using the provided token.
3.  Terraform instructs Proxmox to clone the specified `template_name` onto the target `proxmox_node`, configuring resources (CPU, RAM, disk, network) and potentially cloud-init settings (like the SSH key).
4.  Terraform waits for the VM to be ready and potentially retrieves its IP address.
5.  Terraform triggers the Ansible playbook (e.g., via provisioner or dynamic inventory).
6.  Ansible connects to the new VM via SSH using its IP address and the provided private key.
7.  Ansible executes tasks: updates packages, installs Docker, pulls the Portainer image, starts the Portainer container using the defined `portainer_data_volume_path`.
8.  Deployment is complete. User can access Portainer via the VM's IP address.

## Configuration Details

* **Terraform:** See `variables.tf` for configurable parameters. Core Proxmox resource definitions are in `main.tf` [adjust filename if different]. Ensure your Proxmox provider block is correctly configured.
* **Ansible:** Main playbook: `ansible/playbook.yml` [adjust filename]. Roles: `ansible/roles/`. Variables: `ansible/group_vars/`, `ansible/host_vars/`. Inventory might be statically defined or dynamically generated by Terraform.

## Destroying the Infrastructure

To remove the VM and any other resources created by this Terraform configuration:

```bash
# Ensure the API secret is set as an environment variable if needed for destroy
# export TF_VAR_pm_api_token_secret='YOUR_SECRET_TOKEN'

terraform destroy
