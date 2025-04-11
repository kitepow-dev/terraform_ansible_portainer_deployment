
provider "proxmox" {
  endpoint = var.proxmox_endpoint
  # api_token = var.virtual_environment_api_token
  username = "root@pam"
  password = var.proxmox_password
  insecure = true
}

resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_host

  url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

resource "proxmox_virtual_environment_vm" "ubuntu" {
  count = 3
  name      = "test-0${count.index + 1}"
  node_name = var.proxmox_host

  initialization {
    dns {
      servers = ["1.1.1.1"]
    }
    ip_config {
      ipv4 {
        address = "111.111.111.111${1 + count.index + 1}/24"
        gateway = "111.111.111.111"
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [var.ssh_key]
    }
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }
  disk {
    datastore_id = "local-lvm"
    interface    = "virtio1"
    iothread     = true
    replicate = false
    discard      = "on"
    file_format = "raw"
    size         = 30
  }

  network_device {
    bridge = "vmbr0"
  }
}

