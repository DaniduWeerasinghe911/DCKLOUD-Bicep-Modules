 
@description('The name of the resource.')
param imageGalleryName string

@description('Location of the resource.')
param location string

// @description('Location of the resource.')
// param hyperVGeneration string = 'V1'


@description('Detailed image information to set for the custom image produced by the Azure Image Builder build.')
param imageDefinitionProperties array 


resource imageDefinition 'Microsoft.Compute/galleries/images@2020-09-30' = [for imageDefinition in imageDefinitionProperties: {
  name: '${imageGalleryName}/${imageDefinition.name}'
  location: location
  properties: {
    osType: 'Windows'
    osState: 'Generalized'
    identifier: {
      publisher: imageDefinition.publisher
      offer: imageDefinition.offer
      sku: imageDefinition.sku
    }
    recommended: {
      vCPUs: {
        min: 2
        max: 8
      }
      memory: {
        min: 16
        max: 48
      }
    }
    hyperVGeneration: imageDefinition.hyperVGeneration
  }
}]
