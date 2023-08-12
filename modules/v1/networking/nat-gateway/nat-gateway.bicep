@description('Required. Name of the NAT Gateway')
param natName string

@description('Optional. The idle timeout of the nat gateway.')
param idleTimeoutInMinutes int = 5


@description('Optional. The idle timeout of the nat gateway.')
param publicIpPrefixLength int = 31


@description('Optional. Use to have a new Public IP Address created for the NAT Gateway.')
param requiredPipPrefix bool = false

@description('Optional. Use to have a new Public IP Address created for the NAT Gateway.')
param requiredPip bool = true

@description('Optional. A list of availability zones denoting the zone in which Nat Gateway should be deployed.')
param zones array = []

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = ''

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Tags for the resource.')
param tags object = {}


var natGatewayPropertyPublicIPPrefixes = {
  id: az.resourceId('Microsoft.Network/publicIPPrefixes', publicPrefix.outputs.name)
}

var natGatewayPropertyPublicIPAddresses = {
  id: az.resourceId('Microsoft.Network/publicIPAddresses', publicIp.outputs.name)
}

//Public IP

module publicIp '../public-ip/public-ip.bicep' = if(requiredPip) {
  name: 'deploy_NAT_Gateway_IP'
  params: {
    location: location
    publicIpName: '${natName}-pip'
  }
}

module publicPrefix '../public-ip/public-ip-prefixes.bicep' =  if(requiredPipPrefix) {
  name: 'deploy_NAT_Gateway_PipPrefix'
  params: {
    location:location
    name: '${natName}-pipp'
    prefixLength: publicIpPrefixLength
  }
}

// NAT GATEWAY
// ===========
resource natGateway 'Microsoft.Network/natGateways@2022-07-01' = {
  name: natName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: idleTimeoutInMinutes
    publicIpPrefixes: requiredPipPrefix ? [ natGatewayPropertyPublicIPPrefixes] : null
    publicIpAddresses: requiredPip ? [natGatewayPropertyPublicIPAddresses] : null
  }
  zones: zones
}

resource natGateway_lock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(lock)) {
  name: '${natGateway.name}-${lock}-lock'
  properties: {
    level: any(lock)
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: natGateway
}

module natGateway_roleAssignments './nested_roleAssignments.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${uniqueString(deployment().name, location)}-NatGateway-Rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    condition: contains(roleAssignment, 'condition') ? roleAssignment.condition : ''
    delegatedManagedIdentityResourceId: contains(roleAssignment, 'delegatedManagedIdentityResourceId') ? roleAssignment.delegatedManagedIdentityResourceId : ''
    resourceId: natGateway.id
  }
}]

@description('The name of the NAT Gateway.')
output name string = natGateway.name

@description('The resource ID of the NAT Gateway.')
output resourceId string = natGateway.id

@description('The resource group the NAT Gateway was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The location the resource was deployed into.')
output location string = natGateway.location
