
@description('Location of the resource')
param location string

@description('Name of the Vitual Machine')
param vmName string

@description('Name of the Vitual Machine')
param fileUrl string


resource customscriptextension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  name: '${vmName}/SetPageFile'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        fileUrl
      ]
      commandToExecute: 'powershell -ExecutionPolicy Bypass -File deployment.ps1'
    }
  }
}
