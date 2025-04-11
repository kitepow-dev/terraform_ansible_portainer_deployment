# Terraform Ansible Portainer Deployment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) This repository contains Terraform and Ansible code to automate the deployment of Portainer CE/BE on a virtual machine. Terraform provisions the necessary infrastructure (e.g., a VM, network rules), and Ansible configures the server, installs Docker, and deploys Portainer.

## Overview

The goal of this project is to provide a repeatable and automated way to set up a Portainer instance.

* **Terraform:** Handles infrastructure creation (e.g., Virtual Machine, Security Group/Firewall Rules, potentially networking) on a cloud provider [Specify Provider, e.g., AWS, Azure, GCP, Hetzner, DigitalOcean] or virtualization platform [e.g., Proxmox].
* **Ansible:** Configures the provisioned server, including:
    * System updates
    * Docker installation
    * Portainer container deployment
    * [Add any other specific configuration steps Ansible performs]

## Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Terraform:** [Link to Terraform Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
2.  **Ansible:** [Link to Ansible Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
3.  **[Cloud Provider/Platform] Account:** Access credentials configured for Terraform (e.g., API keys set as environment variables, configuration files).
4.  **SSH Key Pair:** An SSH key pair is required for Ansible to connect to the provisioned server. Ensure the public key is available to be added to the server by Terraform, and the private key is accessible by Ansible.
5.  **Git:** To clone this repository.

## Setup and Usage

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/kitepow-dev/terraform_ansible_portainer_deployment.git](https://github.com/kitepow-dev/terraform_ansible_portainer_deployment.git)
    cd terraform_ansible_portainer_deployment
    ```

2.  **Configure Terraform Variables:**
    * Review the variables defined in `variables.tf`.
    * Create a `terraform.tfvars` file (or use environment variables prefixed with `TF_VAR_`) to set your desired values. Key variables likely include:
        * `region`: Your cloud provider region.
        * `instance_type`: The size/type of the virtual machine.
        * `ssh_public_key`: The path to your public SSH key or the key content itself.
        * `project_name` or similar tags.
        * [Add any other crucial Terraform variables]
    * *Example `terraform.tfvars`:*
        ```hcl
        # Example - replace with your actual values
        region         = "us-east-1"
        instance_type  = "t3.micro"
        ssh_public_key = "~/.ssh/id_rsa.pub"
        ```

3.  **Configure Ansible Variables:**
    * Review Ansible variables, typically found in `ansible/group_vars/all.yml` or similar inventory files. Key variables might include:
        * `ansible_user`: The user Ansible will connect as (often configured by Terraform).
        * `ansible_ssh_private_key_file`: Path to the private SSH key corresponding to the public key used by Terraform.
        * `portainer_version`: Specific Portainer version to install.
        * `portainer_data_volume`: Path for Portainer persistent data.
        * [Add any other crucial Ansible variables, e.g., domain name if using Traefik/Nginx]
    * *Note:* Avoid committing sensitive information like passwords directly. Use Ansible Vault for sensitive data.

4.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
    This downloads the necessary provider plugins.

5.  **Plan the Deployment (Optional but Recommended):**
    ```bash
    terraform plan -out=tfplan
    ```
    Review the output to see what resources Terraform will create.

6.  **Apply the Configuration:**
    ```bash
    terraform apply "tfplan"
    # Or, if you skipped the plan step:
    # terraform apply --auto-approve
    ```
    Terraform will provision the infrastructure. If configured (often using a `remote-exec` or `local-exec` provisioner calling Ansible, or using the Ansible provider), Terraform will trigger the Ansible playbook to configure the server and deploy Portainer.

7.  **Access Portainer:**
    * Once `terraform apply` completes successfully, find the public IP address of the created server (usually output by Terraform).
    * Open your web browser and navigate to: `http://<SERVER_IP>:9000` (or `https://<SERVER_IP>:9443` if using HTTPS/Portainer's default self-signed cert).
    * Follow the Portainer initial setup instructions to create your admin user.

## Architecture / Workflow

1.  User runs `terraform apply`.
2.  Terraform communicates with the [Cloud Provider/Platform] API to provision resources (VM, firewall rules, etc.).
3.  Terraform outputs the server's IP address and potentially adds it to an Ansible inventory file.
4.  Terraform triggers the Ansible playbook (e.g., via a provisioner).
5.  Ansible connects to the new server via SSH.
6.  Ansible executes tasks: updates packages, installs Docker, pulls the Portainer image, starts the Portainer container.
7.  Deployment is complete. User can access Portainer via the server's IP address.

## Configuration Details

* **Terraform:** See `variables.tf` for all configurable infrastructure parameters. Core infrastructure definitions are in `main.tf` [adjust filename if different].
* **Ansible:** The main playbook is likely located at `ansible/playbook.yml` [adjust filename if different]. Roles (if used) are in `ansible/roles/`. Configuration variables are primarily in `ansible/group_vars/` or `ansible/host_vars/`.

## Destroying the Infrastructure

To remove all resources created by this Terraform configuration:

```bash
terraform destroy
