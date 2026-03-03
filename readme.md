# FA Hybrid Golden Image Pipeline

Build hardened Oracle Enterprise Linux 9 golden images with Packer and deploy infrastructure with Bicep on Azure.

## Repository Structure

```
├── Image/                        # Packer image build
│   ├── fa-oel-9.pkr.hcl          # Packer template (Azure ARM builder)
│   └── vars.pkrvars.hcl          # Variable values for the build
├── Infra/                        # Azure infrastructure (Bicep)
│   ├── sig.bicep                 # Azure Compute Gallery definition
│   ├── sig.parameters.json       # Gallery deployment parameters
│   ├── vm.bicep                  # VM deployed from the golden image
│   └── vm.parameters.json        # VM deployment parameters
└── readme.md
```

## Prerequisites

- [Packer](https://developer.hashicorp.com/packer/install) >= 1.9
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) >= 2.50
- [Bicep CLI](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install) (bundled with Azure CLI)
- An Azure subscription with a resource group (`rg-hybrid-packer-sb`)
- Authenticated session (`az login`)

## Image Build (Packer)

The Packer template creates an Oracle Linux 9 golden image and publishes it to an Azure Compute Gallery.

### Configuration

| Variable                | Default                    | Description                          |
|-------------------------|----------------------------|--------------------------------------|
| `location`              | `eastus2`                  | Azure region                         |
| `image_sku`             | `ol97-lvm-gen2`            | Oracle Linux marketplace SKU         |
| `gallery_resource_group`| —                          | Resource group hosting the gallery   |
| `gallery_name`          | —                          | Azure Compute Gallery name           |
| `image_definition_name` | —                          | Image definition within the gallery  |
| `image_version`         | `1.0.0`                    | Semantic version for the image       |

### Build Commands

```bash
cd Image

# Initialize Packer plugins
packer init fa-oel-9.pkr.hcl

# Validate the template
packer validate -var-file=vars.pkrvars.hcl fa-oel-9.pkr.hcl

# Build the image
packer build -var-file=vars.pkrvars.hcl fa-oel-9.pkr.hcl
```

Authentication uses Azure CLI by default (`use_azure_cli_auth = true`). Alternatively, set the environment variables `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`, `ARM_CLIENT_ID`, and `ARM_CLIENT_SECRET`.

## Infrastructure Deployment (Bicep)

### 1. Deploy the Azure Compute Gallery

```bash
az deployment group create \
  --resource-group rg-hybrid-packer-sb \
  --template-file Infra/sig.bicep \
  --parameters @Infra/sig.parameters.json
```

### 2. Deploy a VM from the Golden Image

```bash
az deployment group create \
  --resource-group rg-hybrid-packer-sb \
  --template-file Infra/vm.bicep \
  --parameters @Infra/vm.parameters.json
```

The VM template references the golden image version from the Compute Gallery and provisions a NIC attached to an existing VNet/subnet.

## Customising the Image

Add provisioning steps in the `build` block of [Image/fa-oel-9.pkr.hcl](Image/fa-oel-9.pkr.hcl). The default template installs `tree` as a placeholder. Replace or extend the inline shell commands (or switch to Ansible/script provisioners) to apply your hardening baseline.