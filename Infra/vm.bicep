@description('Name of the Virtual Machine')
param vmName string = 'fa-oel9-vm01'

@description('Admin username for the VM')
param adminUsername string = 'azureuser'

@secure()
@description('Admin password for the VM')
param adminPassword string

@description('Location of the VM')
param location string = resourceGroup().location

@description('Gallery Name')
param galleryName string = 'fa_hybrid_golden_images'

@description('Image Definition Name')
param imageDefinitionName string = 'fa-oel-9-golden'

@description('Image Version (e.g., 1.0.0 or latest)')
param imageVersion string = 'latest'

@description('VM Size')
param vmSize string = 'Standard_D2s_v3'

@description('Existing Virtual Network Name')
param vnetName string = 'fa-hybrid-vnet'

@description('Existing Subnet Name')
param subnetName string = 'default'

//
// Build the SIG image version resource ID as ONE interpolated string.
// (Correct Bicep interpolation; avoid '+' concatenation.)
//
var sigImageId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/galleries/${galleryName}/images/${imageDefinitionName}/versions/${imageVersion}'
// String interpolation with ${} is the idiomatic way in Bicep. [1](https://github.com/hashicorp/setup-packer)[2](https://www.infralovers.com/blog/2024-10-17-hashicorp-packer-github-actions/)

//
// Reference existing VNet (syntax with `existing` per Bicep docs).
//
resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' existing = {
  name: vnetName
}
// Existing resource usage is documented in Bicep. [4](https://docs.azure.cn/en-us/virtual-machines/linux/image-builder-json)

var subnetId = '${vnet.id}/subnets/${subnetName}'

//
// NIC
//
resource nic 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

//
// VM using SIG image via imageReference.id
//
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        id: sigImageId
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
