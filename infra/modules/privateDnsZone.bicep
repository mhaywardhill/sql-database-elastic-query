@description('Private DNS zone name')
param zoneName string

@description('Array of VNET resource IDs to link to this DNS zone')
param vnetLinks array

@description('Tags to apply')
param tags object = {}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'
  tags: tags
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [
  for (link, i) in vnetLinks: {
    parent: privateDnsZone
    name: '${zoneName}-link-${i}'
    location: 'global'
    properties: {
      virtualNetwork: {
        id: link
      }
      registrationEnabled: false
    }
  }
]

output privateDnsZoneId string = privateDnsZone.id
