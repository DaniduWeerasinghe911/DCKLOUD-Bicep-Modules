@description('Virtual machine name. Do not include numerical identifier.')
param virtualMachineNameSuffix string

@description('Recovery Services Vault Name')
param vaultName string

@description('Recovery Services Vault Name')
param vmId string = 'rsv-backup'

@description('Backup Policy Name')
param backupPolicyName string = 'vm-policy'

@description('''If selective backup is enabled pass the parameter accordingly
{
  diskLunList:[0,1]
  isInclusionList:true
}
''')
param diskExclusionProperties object = {}

var vmRgName = split(vmId,'/')[4]

var backupFabric = 'Azure'
var protectionContainer = 'iaasvmcontainer;iaasvmcontainerv2;${vmRgName};${virtualMachineNameSuffix}'
var protectedItem = 'vm;iaasvmcontainerv2;${vmRgName};${virtualMachineNameSuffix}'


resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2022-01-01' existing = {
  //scope:resourceGroup(subscription().subscriptionId,shdsvcRgName)
  name: vaultName
}


resource vaultName_backupFabric_protectionContainer_protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2023-01-01' = {
  name: '${vaultName}/${backupFabric}/${protectionContainer}/${protectedItem}'
//r  scope:resourceGroup(shdsvcRgName)
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: '${recoveryServicesVault.id}/backupPolicies/${backupPolicyName}'
    sourceResourceId: vmId
    extendedProperties:{
      diskExclusionProperties: (diskExclusionProperties != {})  ? diskExclusionProperties : null
    }

  }
}
