@description('Name of the private endpoint')
param privateEndpointName string

@description('Azure region')
param location string

@description('Resource ID of the subnet to place the private endpoint in')
param subnetId string

@description('Resource ID of the target resource (e.g. SQL Server)')
param privateLinkServiceId string

@description('Group IDs for the private link (e.g. sqlServer)')
param groupIds array

@description('Resource ID of the Private DNS Zone to link')
param privateDnsZoneId string

@description('Tags to apply')
param tags object = {}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-connection'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

output privateEndpointId string = privateEndpoint.id
output networkInterfaceId string = privateEndpoint.properties.networkInterfaces[0].id
