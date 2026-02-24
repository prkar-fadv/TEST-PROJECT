@description('Azure region for the gallery.')
param location string

@description('Gallery resource name (no spaces).')
param galleryName string

@description('Friendly description shown in the portal.')
param galleryDescription string = 'FA Hybrid Golden Images Registry'

resource sig 'Microsoft.Compute/galleries@2025-03-03' = {
  name: galleryName
  location: location
  properties: {
    description: galleryDescription
  }
}

output galleryId string = sig.id
