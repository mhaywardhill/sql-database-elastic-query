@description('SQL Server name (must be globally unique)')
param sqlServerName string

@description('Azure region')
param location string

@description('SQL administrator login')
param adminLogin string

@description('SQL administrator password')
@secure()
param adminPassword string

@description('Name of the SQL database')
param databaseName string

@description('SQL database SKU name')
param skuName string = 'Standard'

@description('SQL database SKU tier')
param skuTier string = 'Standard'

@description('SQL database capacity (DTU)')
param skuCapacity int = 10

@description('Tags to apply')
param tags object = {}

@description('Allow Azure services to access this server (required for elastic query)')
param allowAzureServices bool = false

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    publicNetworkAccess: allowAzureServices ? 'Enabled' : 'Disabled'
    minimalTlsVersion: '1.2'
  }
}

// Required for elastic query: SQL-to-SQL connections use the Azure backbone,
// not private endpoints. This rule only allows Azure-internal traffic.
resource allowAzureServicesRule 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = if (allowAzureServices) {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
    capacity: skuCapacity
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2 GB
  }
}

output sqlServerId string = sqlServer.id
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlServerName string = sqlServer.name
output databaseName string = sqlDatabase.name
