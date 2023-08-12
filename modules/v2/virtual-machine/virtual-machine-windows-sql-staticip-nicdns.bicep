@description('Virtual machine name. Do not include numerical identifier.')
@maxLength(14)
param virtualMachineNameSuffix string

@description('Optional. Can be used to deploy multiple instances in a single deployment.')
@minValue(1)
param vmCount int = 1

@description('Optional. If doing multiple instances, you can change what number it starts from for naming purposes. Default is start from 01.')
@minValue(1)
param startIndex int = 1

@description('Virtual machine location.')
param location string = resourceGroup().location

@description('Virtual machine size, e.g. Standard_D2_v3, Standard_DS3, etc.')
param virtualMachineSize string

@description('Operating system disk type. E.g. If your VM is a standard size you must use a standard disk type.')
@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
  'UltraSSD_LRS'
])
param osDiskType string = 'Premium_LRS'

@description('Array of objects defining data disks, including diskType and size')
@metadata({
  note: 'Sample input'
  dataDisksDefinition: [
    {
      diskType: 'Premium_LRS'
      diskSize: 64
      caching: 'ReadOnly'
      createOption: 'Empty'
    }
  ]
})
param dataDisksDefinition array

@description('Virtual machine Windows operating system.')
@allowed([
  'enterprise'
  'Standard'
])
param operatingSystem string = 'Standard'

@description('Enable if want to use Hybrid Benefit Licensing.')
param enableHybridBenefit bool = true

@description('Virtual machine local administrator username.')
param adminUsername string

@description('Local administrator password.')
@secure()
param adminPassword string

@description('(Optional) Create SQL Server sysadmin login user name')
param sqlAuthUpdateUserName string = ''

@description('(Optional) Create SQL Server sysadmin login password')
@secure()
param sqlAuthUpdatePassword string = ''

@description('ResourceId of the Storage Account to send Diagnostic Logs')
param storageId string

@description('Resource Id of Subnet to place VM into.')
param subnetId string

@description('If set to true, the availability zone will be picked based on instance ID.')
param useAvailabilityZones bool = false

@description('Resource Id of Log Analytics Workspace for VM Diagnostics')
param logAnalyticsId string

@description('True/False on whether to domain join VM as part of deployment.')
param enableDomainJoin bool = true

@description('FQDN of Domain to Join.')
param domainToJoin string

@description('OU to join VM into.')
param OUPath string = ''

@description('Username of the Domain Join process. Required when enableDomainJoin is true')
param domainJoinUser string

@description('Time Zone setting for Virtual Machine')
param timeZone string = 'AUS Eastern Standard Time'

@description('Password for the user of the Domain Join process. Required when enableDomainJoin is true')
@secure()
param domainJoinPassword string

@description('Private Address')
param privateIPAddress string = ''

@description('Object containing resource tags.')
param tags object = {}

@description('Path for SQL Data files. Please choose drive letter from F to Z, and other drives from A to E are reserved for system')
param dataPath string = 'F:\\SQLData'

@description('Path for SQL Log files. Please choose drive letter from F to Z and different than the one used for SQL data. Drive letter from A to E are reserved for system')
param logPath string = 'L:\\SQLLog'

///////////////////////////////////////

@description('Select the version of SQL Server Image type')
@allowed([
  'SQL2017-WS2016'
  'SQL2016SP2-WS2016'
  'SQL2019-WS2019'
  ''
])
param sqlServerImageType string = 'SQL2019-WS2019'

@description('SQL server connectivity option')
@allowed([
  'LOCAL'
  'PRIVATE'
  'PUBLIC'
])
param sqlConnectivityType string = 'PRIVATE'

@description('SQL server port')
param sqlPortNumber int = 1433

@description('SQL server workload type')
@allowed([
  'DW'
  'GENERAL'
  'OLTP'
])
param sqlStorageWorkloadType string = 'GENERAL'

@description('SQL server license type')
@allowed([
  'AHUB'
  'PAYG'
  'DR'
])
param sqlServerLicenseType string = 'AHUB'

@description('Logical Disk Numbers (LUN) for SQL data disks.')
param dataDisksLUNs array

@description('Logical Disk Numbers (LUN) for SQL log disks.')
param logDisksLUNs array

@description('Default path for SQL Temp DB files.')
param tempDBPath string = 'D:\\SQLTemp'

@description('Enable or disable R services (SQL 2016 onwards).')
param rServicesEnabled bool = false

@description('Name of the SQL Always-On cluster name. Only required when deploying a SQL cluster.')
param sqlVmGroupName string = ''

@description('password for the cluster bootstrap account. Only required when deploying a SQL cluster.')
@secure()
param sqlClusterBootstrapAccountPassword string = ''

@description('password for the cluster operator account. Only required when deploying a SQL cluster.')
@secure()
param sqlClusterOperatorAccountPassword string = ''

@description('password for the sql service account. Only required when deploying a SQL cluster.')
@secure()
param sqlServiceAccountPassword string = ''

@description('dataCollectionRuleAssociationName')
param dataCollectionRuleAssociationName string = 'VM-Health-Dcr-Association'

@description('healthDataCollectionRuleResourceId')
param healthDataCollectionRuleResourceId string 

// @description('Recovery Services Vault Rg Name')
// param shdsvcRgName string = 'shared-rg'

@description('Name of the Storage account for configuration data')
param dscStorageAccount string = 'sgsadscmgmtaue001'

@description('Name of the Storage account continer for configuration data')
param dscStorageAccountContainer string = 'dsccontainer'

@description('DSC Configuration ZIP Filename')
param dscConfigZip string = 'sgconfig.zip'

param dscProperties object = {}


var configFilePath = 'https://${dscStorageAccount}.blob.core.windows.net/${dscStorageAccountContainer}/${dscConfigZip}'

@description('Enable a Can Not Delete Resource Lock.  Useful for production workloads.')
param enableResourceLock bool = false

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = { 
  name: '${virtualMachineNameSuffix}-nic01'
  location: location
  tags: !empty(tags) ? tags : json('null')
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: empty(privateIPAddress) ? 'Dynamic' : 'Static'
          privateIPAddress:privateIPAddress
        }
      }
    ]
  }
}

resource dataDisk 'Microsoft.Compute/disks@2020-12-01' = [for (item, j) in dataDisksDefinition: {
  name: '${virtualMachineNameSuffix}_datadisk_${j}'
  location: location
  properties: {
    creationData: {
      createOption: item.createOption
    }
    diskSizeGB: item.diskSize
  }
  sku: {
    name: item.diskType
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: virtualMachineNameSuffix
  location: location
  tags: !empty(tags) ? tags : json('null')
  zones: []
  properties: {
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${virtualMachineNameSuffix}-nic01')
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineNameSuffix
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        timeZone: timeZone
      }
    }
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'microsoftsqlserver'
        offer: sqlServerImageType
        sku: operatingSystem
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachineNameSuffix}_osdisk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      dataDisks: [for (item, j) in dataDisksDefinition: {
        diskSizeGB: item.diskSize
        lun: j
        caching: item.caching
        createOption: 'Attach'
        managedDisk: {
          id: resourceId('Microsoft.Compute/disks', '${virtualMachineNameSuffix}_datadisk_${j}')
          storageAccountType: item.diskType
        }
      }]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri:storageId
      }
    }
    licenseType: (enableHybridBenefit ? 'Windows_Server' : json('null'))
  }
  dependsOn: [
    nic
   // dataDisk
  ]
}

resource sql_vm 'Microsoft.SqlVirtualMachine/sqlVirtualMachines@2022-08-01-preview' = {
  name: virtualMachineNameSuffix
  location: location
  properties: {
    virtualMachineResourceId: resourceId('Microsoft.Compute/virtualMachines', virtualMachineNameSuffix)
    sqlManagement: 'Full'
    sqlServerLicenseType: sqlServerLicenseType
    sqlVirtualMachineGroupResourceId: (!empty(sqlVmGroupName)) ? resourceId('Microsoft.SqlVirtualMachine/sqlVirtualMachineGroups', sqlVmGroupName) : null
    
    assessmentSettings:{
      enable:true
    }
    autoPatchingSettings: {
      enable: false
    }
    storageConfigurationSettings: {
      diskConfigurationType: 'NEW'
      storageWorkloadType: sqlStorageWorkloadType
      sqlDataSettings: {
        luns: dataDisksLUNs
        defaultFilePath: dataPath
      }
      sqlLogSettings: {
        luns: logDisksLUNs
        defaultFilePath: logPath
      }
      sqlTempDbSettings: {
        //luns: tempDBDisksLUNs
        defaultFilePath: tempDBPath
      }
      sqlSystemDbOnDataDisk:true
    }
    serverConfigurationsManagementSettings: {
      sqlConnectivityUpdateSettings: {
        connectivityType: sqlConnectivityType
        port: sqlPortNumber
        sqlAuthUpdateUserName: sqlAuthUpdateUserName
        sqlAuthUpdatePassword: sqlAuthUpdatePassword
      }
      additionalFeaturesServerConfigurations: {
        isRServicesEnabled: rServicesEnabled
      }
      sqlInstanceSettings:{
        isLpimEnabled:true
      }

    }
    wsfcDomainCredentials: {
      clusterBootstrapAccountPassword: (!empty(sqlVmGroupName)) ? sqlClusterBootstrapAccountPassword : null
      clusterOperatorAccountPassword: (!empty(sqlVmGroupName)) ? sqlClusterOperatorAccountPassword : null
      sqlServiceAccountPassword: (!empty(sqlVmGroupName)) ? sqlServiceAccountPassword : null
    }


    
  }
  dependsOn: [
    vm
    extension_domainJoin
  ]
}

resource extension_monitoring 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' =  {
  parent: vm
  name: 'MicrosoftMonitoringAgent'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(logAnalyticsId, '2015-03-20').customerId
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsId, '2015-03-20').primarySharedKey
    }
  }
}

resource extension_depAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: vm
  name: 'DependencyAgentWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    extension_monitoring
  ]
}

resource extension_guesthealth 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: vm
  name: 'GuestHealthWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor.VirtualMachines.GuestHealth'
    type: 'GuestHealthWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    extension_depAgent
    extension_monitoring
    extension_domainJoin
  ]
}

resource extension_AzureMonitorWindowsAgent 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = {
  parent: vm
  name: 'AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    extension_guesthealth
  ]
}

resource extension_domainJoin 'Microsoft.Compute/virtualMachines/extensions@2021-04-01' = if (enableDomainJoin) {
  parent: vm
  name: 'joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainToJoin
      OUPath: OUPath
      User: '${domainToJoin}\\${domainJoinUser}'
      Restart: 'true'
      Options: 3 // Join Domain and Create Computer Account
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
  dependsOn: [
    extension_depAgent
  ]
}

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRuleAssociations@2021-04-01' = {
  name: '${virtualMachineNameSuffix}-Microsoft.Insights-${dataCollectionRuleAssociationName}'
  scope: vm
  properties: {
    dataCollectionRuleId:healthDataCollectionRuleResourceId
    description: 'Association of data collection rule for VM Insights Health.'
  }
  dependsOn:[
    extension_AzureMonitorWindowsAgent
    extension_guesthealth
  ]
}

//dsc configurations
resource dscextension 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  name: '${virtualMachineNameSuffix}/dscextension'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: configFilePath
      configurationFunction: 'sgconfig.ps1\\sgconfig'
      properties: dscProperties
    }
  }
  dependsOn: [
    vm
    extension_domainJoin
  ]
}


// Resource Lock
resource deleteLock 'Microsoft.Authorization/locks@2016-09-01' = if (enableResourceLock) {
  name: '${virtualMachineNameSuffix}-delete-lock'
  scope: vm
  properties: {
    level: 'CanNotDelete'
    notes: 'Enabled as part of IaC Deployment'
  }
}

output vmName string = vm.name
output vmId string = vm.id
