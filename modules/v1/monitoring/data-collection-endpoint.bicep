@description('Data Collection Endpoint Name')
param dataCollectionEndpointName string 


@description('Location For the Resource')
param location string


resource dataCollectionEndPoint 'Microsoft.Insights/dataCollectionEndpoints@2021-09-01-preview' = {
  name: dataCollectionEndpointName
  location: location
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Enabled'
  }
  }
}
