@description('Required. Name of the Public IP Prefix.')
@minLength(1)
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. Length of the Public IP Prefix.')
@minValue(28)
@maxValue(31)
param prefixLength int

@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = ''

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. The customIpPrefix that this prefix is associated with. A custom IP address prefix is a contiguous range of IP addresses owned by an external customer and provisioned into a subscription. When a custom IP prefix is in Provisioned, Commissioning, or Commissioned state, a linked public IP prefix can be created. Either as a subset of the custom IP prefix range or the entire range.')
param customIPPrefix object = {}


resource publicIpPrefix 'Microsoft.Network/publicIPPrefixes@2022-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    customIPPrefix: !empty(customIPPrefix) ? customIPPrefix : null
    publicIPAddressVersion: 'IPv4'
    prefixLength: prefixLength
  }
}

resource publicIpPrefix_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock)) {
  name: '${publicIpPrefix.name}-${lock}-lock'
  properties: {
    level: any(lock)
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: publicIpPrefix
}


@description('The resource ID of the public IP prefix.')
output resourceId string = publicIpPrefix.id

@description('The resource group the public IP prefix was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The name of the public IP prefix.')
output name string = publicIpPrefix.name

@description('The location the resource was deployed into.')
output location string = publicIpPrefix.location
