@description('Enter managed instance name.')
param managedInstanceName string

@description('Enter user name.')
param administratorLogin string

@description('Enter password.')
@secure()
param administratorLoginPassword string

@description('Enter location. If you leave this field blank resource group location would be used.')
param location string = resourceGroup().location

@description('Enter virtual network name. If you leave this field blank name will be created by the template.')
param virtualNetworkName string = 'SQLMI-VNET'

@description('Enter the subnet ID')
param subnetId string = 'ManagedInstance'

@description('Enter sku name.')
@allowed([
  'GP_Gen5'
  'BC_Gen5'
])
param skuName string = 'GP_Gen5'

@description('Enter number of vCores.')
@allowed([
  8
  16
  24
  32
  40
  64
  80
])
param vCores int = 16

@description('Enter storage size.')
@minValue(32)
@maxValue(8192)
param storageSizeInGB int = 256

@description('Enter license type.')
@allowed([
  'BasePrice'
  'LicenseIncluded'
])
param licenseType string = 'LicenseIncluded'

@description('''
{
  administratorType: 'ActiveDirectory'
  azureADOnlyAuthentication: false
  login: 'string'
  principalType: 'string'
  sid: 'string'
  tenantId: 'string'
}'''
)
param authenticationType object = {}

resource managedInstance 'Microsoft.Sql/managedInstances@2022-05-01-preview' = {
  name: managedInstanceName
  location: location
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    subnetId: subnetId //resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    storageSizeInGB: storageSizeInGB
    vCores: vCores
    licenseType: licenseType
    servicePrincipal: {
      type: 'SystemAssigned'
    }
    minimalTlsVersion: '1.2'
    administrators: authenticationType
  }

}
