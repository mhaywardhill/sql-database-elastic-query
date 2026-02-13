// ============================================================================
// Hub-Spoke VNET Topology with Azure SQL Private Endpoints
// ============================================================================
// Topology:
//   Hub VNET (10.0.0.0/16)
//     └── default subnet (10.0.0.0/24)
//   Spoke 1 VNET (10.1.0.0/16)  ←→  Hub (peered)
//     └── pe-subnet (10.1.1.0/24) → Private Endpoint → SQL Server 1
//   Spoke 2 VNET (10.2.0.0/16)  ←→  Hub (peered)
//     └── pe-subnet (10.2.1.0/24) → Private Endpoint → SQL Server 2
// ============================================================================

targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Azure region for all resources')
param location string

@description('Project prefix for naming')
param projectPrefix string

@description('SQL administrator login name')
param sqlAdminLogin string

@description('SQL administrator password')
@secure()
param sqlAdminPassword string

@description('Tags applied to all resources')
param tags object = {
  project: 'sql-elastic-query'
  environment: 'dev'
}

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

var hubVnetName = '${projectPrefix}-hub-vnet'
var spoke1VnetName = '${projectPrefix}-spoke1-vnet'
var spoke2VnetName = '${projectPrefix}-spoke2-vnet'

var sqlServer1Name = '${projectPrefix}-sql1-${uniqueString(resourceGroup().id, 'sql1')}'
var sqlServer2Name = '${projectPrefix}-sql2-${uniqueString(resourceGroup().id, 'sql2')}'

// ---------------------------------------------------------------------------
// Hub VNET
// ---------------------------------------------------------------------------

module hubVnet 'modules/vnet.bicep' = {
  name: 'deploy-hub-vnet'
  params: {
    vnetName: hubVnetName
    location: location
    addressPrefix: '10.0.0.0/16'
    subnets: [
      { name: 'default', addressPrefix: '10.0.0.0/24' }
      { name: 'AzureFirewallSubnet', addressPrefix: '10.0.1.0/24' }
      { name: 'GatewaySubnet', addressPrefix: '10.0.2.0/24' }
    ]
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Spoke 1 VNET
// ---------------------------------------------------------------------------

module spoke1Vnet 'modules/vnet.bicep' = {
  name: 'deploy-spoke1-vnet'
  params: {
    vnetName: spoke1VnetName
    location: location
    addressPrefix: '10.1.0.0/16'
    subnets: [
      { name: 'default', addressPrefix: '10.1.0.0/24' }
      { name: 'pe-subnet', addressPrefix: '10.1.1.0/24', privateEndpointNetworkPolicies: 'Disabled' }
    ]
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Spoke 2 VNET
// ---------------------------------------------------------------------------

module spoke2Vnet 'modules/vnet.bicep' = {
  name: 'deploy-spoke2-vnet'
  params: {
    vnetName: spoke2VnetName
    location: location
    addressPrefix: '10.2.0.0/16'
    subnets: [
      { name: 'default', addressPrefix: '10.2.0.0/24' }
      { name: 'pe-subnet', addressPrefix: '10.2.1.0/24', privateEndpointNetworkPolicies: 'Disabled' }
    ]
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// VNET Peerings: Hub ↔ Spoke 1
// ---------------------------------------------------------------------------

module hubToSpoke1 'modules/vnetPeering.bicep' = {
  name: 'peer-hub-to-spoke1'
  params: {
    localVnetName: hubVnetName
    remoteVnetName: spoke1VnetName
    remoteVnetId: spoke1Vnet.outputs.vnetId
    allowGatewayTransit: true
  }
  dependsOn: [ hubVnet ]
}

module spoke1ToHub 'modules/vnetPeering.bicep' = {
  name: 'peer-spoke1-to-hub'
  params: {
    localVnetName: spoke1VnetName
    remoteVnetName: hubVnetName
    remoteVnetId: hubVnet.outputs.vnetId
    useRemoteGateways: false // set to true if hub has a VPN/ER gateway
  }
  dependsOn: [ spoke1Vnet ]
}

// ---------------------------------------------------------------------------
// VNET Peerings: Hub ↔ Spoke 2
// ---------------------------------------------------------------------------

module hubToSpoke2 'modules/vnetPeering.bicep' = {
  name: 'peer-hub-to-spoke2'
  params: {
    localVnetName: hubVnetName
    remoteVnetName: spoke2VnetName
    remoteVnetId: spoke2Vnet.outputs.vnetId
    allowGatewayTransit: true
  }
  dependsOn: [ hubVnet ]
}

module spoke2ToHub 'modules/vnetPeering.bicep' = {
  name: 'peer-spoke2-to-hub'
  params: {
    localVnetName: spoke2VnetName
    remoteVnetName: hubVnetName
    remoteVnetId: hubVnet.outputs.vnetId
    useRemoteGateways: false
  }
  dependsOn: [ spoke2Vnet ]
}

// ---------------------------------------------------------------------------
// Azure SQL Server 1 (Private Endpoint in Spoke 1)
// ---------------------------------------------------------------------------

module sqlServer1 'modules/sqlServer.bicep' = {
  name: 'deploy-sql-server-1'
  params: {
    sqlServerName: sqlServer1Name
    location: location
    adminLogin: sqlAdminLogin
    adminPassword: sqlAdminPassword
    databaseName: '${projectPrefix}-db1'
    skuName: 'Standard'
    skuTier: 'Standard'
    skuCapacity: 10
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Azure SQL Server 2 (Private Endpoint in Spoke 2)
// ---------------------------------------------------------------------------

module sqlServer2 'modules/sqlServer.bicep' = {
  name: 'deploy-sql-server-2'
  params: {
    sqlServerName: sqlServer2Name
    location: location
    adminLogin: sqlAdminLogin
    adminPassword: sqlAdminPassword
    databaseName: '${projectPrefix}-db2'
    skuName: 'Standard'
    skuTier: 'Standard'
    skuCapacity: 10
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Private DNS Zone for Azure SQL (privatelink.database.windows.net)
// Linked to all three VNETs so DNS resolution works across the topology
// ---------------------------------------------------------------------------

module sqlPrivateDnsZone 'modules/privateDnsZone.bicep' = {
  name: 'deploy-sql-private-dns-zone'
  params: {
    zoneName: 'privatelink.database.windows.net'
    vnetLinks: [
      hubVnet.outputs.vnetId
      spoke1Vnet.outputs.vnetId
      spoke2Vnet.outputs.vnetId
    ]
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Private Endpoint: SQL Server 1 → Spoke 1
// ---------------------------------------------------------------------------

module peSqlServer1 'modules/privateEndpoint.bicep' = {
  name: 'deploy-pe-sql1-spoke1'
  params: {
    privateEndpointName: '${projectPrefix}-pe-sql1'
    location: location
    subnetId: spoke1Vnet.outputs.subnets[1].id  // pe-subnet
    privateLinkServiceId: sqlServer1.outputs.sqlServerId
    groupIds: [ 'sqlServer' ]
    privateDnsZoneId: sqlPrivateDnsZone.outputs.privateDnsZoneId
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Private Endpoint: SQL Server 2 → Spoke 2
// ---------------------------------------------------------------------------

module peSqlServer2 'modules/privateEndpoint.bicep' = {
  name: 'deploy-pe-sql2-spoke2'
  params: {
    privateEndpointName: '${projectPrefix}-pe-sql2'
    location: location
    subnetId: spoke2Vnet.outputs.subnets[1].id  // pe-subnet
    privateLinkServiceId: sqlServer2.outputs.sqlServerId
    groupIds: [ 'sqlServer' ]
    privateDnsZoneId: sqlPrivateDnsZone.outputs.privateDnsZoneId
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output hubVnetId string = hubVnet.outputs.vnetId
output spoke1VnetId string = spoke1Vnet.outputs.vnetId
output spoke2VnetId string = spoke2Vnet.outputs.vnetId
output sqlServer1Fqdn string = sqlServer1.outputs.sqlServerFqdn
output sqlServer2Fqdn string = sqlServer2.outputs.sqlServerFqdn
output sqlServer1Name string = sqlServer1.outputs.sqlServerName
output sqlServer2Name string = sqlServer2.outputs.sqlServerName
