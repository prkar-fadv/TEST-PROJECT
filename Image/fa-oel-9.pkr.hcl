packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = ">= 2.0.0"
    }
  }
}

# --------------------------
# Variables (externalized)
# --------------------------
variable "location" {
  type    = string
  default = "eastus2"
}

# Only allow overriding the base image SKU
variable "image_sku" {
  type        = string
  default     = "ol97-lvm-gen2"
  description = "Base OS SKU (Oracle-Linux). This is the ONLY overridable variable."
}

# Gallery params (normally fixed per environment)
variable "gallery_resource_group" { type = string }
variable "gallery_name"           { type = string }
variable "image_definition_name"  { type = string }
variable "image_version" {
  type    = string
  default = "1.0.0"
}

# --------------------------
# Source (Azure ARM builder)
# --------------------------
source "azure-arm" "oel" {
  # Auth from env: ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET
  use_azure_cli_auth = true
  os_type  = "Linux"
  location = var.location
  vm_size  = "Standard_D2s_v3"

  # Base image (Marketplace)
  image_publisher = "Oracle"
  image_offer     = "Oracle-Linux"
  image_sku       = var.image_sku

  # Publish to Azure Compute Gallery (Shared Image Gallery)
  shared_image_gallery_destination {
    resource_group = var.gallery_resource_group
    gallery_name   = var.gallery_name
    image_name     = var.image_definition_name
    image_version  = var.image_version

    # Replicate in the same home region for now
    target_region {
      name     = var.location
      replicas = 1
    }
  }

  communicator = "ssh"
  ssh_username = "packer"
}

# --------------------------
# Build
# --------------------------
build {
  name    = "fa-hybrid-oel-9-golden"
  sources = ["source.azure-arm.oel"]

  provisioner "shell" {
    execute_command = "sudo -E sh -euxo pipefail '{{ .Path }}'"
    inline = [
      # example provisioning
      "dnf -y install tree || true"
    ]
  }
}



