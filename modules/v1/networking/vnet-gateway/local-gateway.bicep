@description('Required. Name of the Local Network Gateway')
@minLength(1)
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. List of the local (on-premises) IP address ranges')
param localAddressPrefixes array

@description('Required. Public IP of the local gateway')
param localGatewayPublicIpAddress string

@description('Optional. The BGP speaker\'s ASN. Not providing this value will automatically disable BGP on this Local Network Gateway resource.')
param localAsn string = ''

@description('Optional. The BGP peering address and BGP identifier of this BGP speaker. Not providing this value will automatically disable BGP on this Local Network Gateway resource.')
param localBgpPeeringAddress string = ''

@description('Optional. The weight added to routes learned from this BGP speaker. This will only take effect if both the localAsn and the localBgpPeeringAddress values are provided.')
param localPeerWeight string = ''

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = 'NotSpecified'

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param enableDefaultTelemetry bool = true

@description('Optional. FQDN of local network gateway.')
param fqdn string = ''

var bgpSettings = {
  asn: localAsn
  bgpPeeringAddress: localBgpPeeringAddress
  peerWeight: !empty(localPeerWeight) ? localPeerWeight : '0'
}

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name, location)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2021-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: localAddressPrefixes
    }
    fqdn: !empty(fqdn) ? fqdn : null
    gatewayIpAddress: localGatewayPublicIpAddress
    bgpSettings: !empty(localAsn) && !empty(localBgpPeeringAddress) ? bgpSettings : null
  }
}

resource localNetworkGateway_lock 'Microsoft.Authorization/locks@2017-04-01' = if (lock != 'NotSpecified') {
  name: '${localNetworkGateway.name}-${lock}-lock'
  properties: {
    level: lock
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: localNetworkGateway
}

@description('The resource ID of the local network gateway')
output resourceId string = localNetworkGateway.id

@description('The resource group the local network gateway was deployed into')
output resourceGroupName string = resourceGroup().name

@description('The name of the local network gateway')
output name string = localNetworkGateway.name
