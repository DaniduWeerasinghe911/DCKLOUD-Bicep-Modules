// Private Endpoint for a Web App

@description('Name of the Resource for which to create the Private Endpoint')
param resourceName string

@description('Resource Id of the Resource for which to create the Private Endpoint')
param id string

@description('Location of the resource.')
param location string = resourceGroup().location

@description('Resource ID of the subnet that will host Private Endpoint.')
param pesubnetId string =''

@description('Vnet Integration Subnet ID')
param integrationsubnetId string = ''

@description('Resource Group of the Private DNS Zone Group to host Private Endpoint entry')
param dnsZoneResourceGroup string

@description('SubscriptionId of the Private DNS Zone Group to host Private Endpoint entry')
param dnsZoneSubscriptionId string

var webapp_dns_name = '.azurewebsites.net'

// resource webapp 'Microsoft.Web/sites@2022-03-01' existing = {
//   name: resourceName
// }

// var networkConfig = {
//   'WEBSITE_DNS_SERVER': '168.63.129.16'
//   'WEBSITE_VNET_ROUTE_ALL': '1'
// }
// var currentconfig = webapp.properties.siteConfig
// var updatedConfig = union(currentconfig ,networkConfig)

// resource webAppSettings 'Microsoft.Web/sites/config@2020-06-01' = {
//   name: '${resourceName}/appsettings'
//   properties: updatedConfig
// }

resource webAppBinding 'Microsoft.Web/sites/hostNameBindings@2019-08-01' = {
  name: '${resourceName}/${resourceName}${webapp_dns_name}'
  properties: {
    siteName: resourceName
    hostNameType: 'Verified'
  }
}

resource webAppNetworkConfig 'Microsoft.Web/sites/networkConfig@2022-03-01' = {
  name: '${resourceName}/VirtualNetwork'
  properties: {
    subnetResourceId: integrationsubnetId
    swiftSupported:true
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: '${resourceName}-pe'
  location: location
  properties: {
    subnet: {
      id: pesubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${resourceName}-plink'
        properties: {
          privateLinkServiceId: id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${privateEndpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.azurewebsites.net'
        properties: {
          privateDnsZoneId: resourceId(dnsZoneSubscriptionId,dnsZoneResourceGroup,'Microsoft.Network/privateDnsZones','privatelink.azurewebsites.net')
        }
      }
    ]
  }
}


// Output Resource Name and Resource Id as a standard to allow module referencing.
output name string = privateEndpoint.name
output id string = privateEndpoint.id
