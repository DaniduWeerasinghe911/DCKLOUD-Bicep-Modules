
@description('Log Analytics ID')
param logAnalyticsID string

@description('The list of email receivers that are part of this action group.')
param emailReceivers array = []

//VM Restart or Shutdown Alert
resource vmShutdownLogAlert 'Microsoft.Insights/scheduledQueryRules@2021-02-01-preview' = {
  name: 'Vm-Win-Events-Vm-Restart-or-Shutdown'
  location: resourceGroup().location
  properties: {
    actions:{
      actionGroups:[
        actionGroup.id
      ]
    }
    severity: 2
    enabled: true
    scopes: [
      logAnalyticsID
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'Event | where EventID == 1074'
          operator: 'GreaterThan'
          timeAggregation: 'Count'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
  }
}

resource vmCheckServerheartbeat 'Microsoft.Insights/scheduledQueryRules@2021-02-01-preview' = {
  name: 'Vm-Check Server heartbeat'
  location: resourceGroup().location
  properties: {
    actions:{
      actionGroups:[
        actionGroup.id
      ]
    }
    severity: 1
    enabled: true
    scopes: [
      logAnalyticsID
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'Heartbeat | summarize TimeGenerated=max(TimeGenerated) by Computer| extend Duration = datetime_diff("minute",now(),TimeGenerated) | summarize AggregatedValue = min(Duration) by Computer, bin(TimeGenerated,5m)'
          operator: 'GreaterThan'
          timeAggregation: 'Count'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 5
            minFailingPeriodsToAlert: 5
          }
        }
      ]
    }
    autoMitigate: false
  }
}

resource vmCPUutilization 'Microsoft.Insights/scheduledQueryRules@2021-02-01-preview' = {
  name: 'CPU Utliization'
  location: resourceGroup().location
  properties: {
    actions:{
      actionGroups:[
        actionGroup.id
      ]
    }
    severity: 2
    enabled: true
    scopes: [
      logAnalyticsID
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: '''
          InsightsMetrics
          | where Origin == "vm.azm.ms"
          | where (_ResourceId contains "/providers/Microsoft.Compute/virtualMachines/" or _ResourceId contains "/providers/Microsoft.Compute/virtualMachineScaleSets/") 
          | where Namespace == "Processor" and Name == "UtilizationPercentage" | summarize AggregatedValue = avg(Val) by bin(TimeGenerated, 15m), _ResourceId
         
          '''
          operator: 'GreaterThan'
          timeAggregation: 'Count'
          threshold: 5
          failingPeriods: {
            numberOfEvaluationPeriods: 5
            minFailingPeriodsToAlert: 5
          }
        }
      ]
    }
    autoMitigate: false
  }
}

resource vmMemutilization 'Microsoft.Insights/scheduledQueryRules@2021-02-01-preview' = {
  name: 'Mem Utliization'
  location: resourceGroup().location
  properties: {
    actions:{
      actionGroups:[
        actionGroup.id
      ]
    }
    severity: 2
    enabled: true
    scopes: [
      logAnalyticsID
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: '''
          InsightsMetrics
          | where Origin == "vm.azm.ms"
          | where Namespace == "Memory" and Name == "AvailableMB"
          | extend TotalMemory = toreal(todynamic(Tags)["vm.azm.ms/memorySizeMB"]) | extend AvailableMemoryPercentage = (toreal(Val) / TotalMemory) * 100.0
          | summarize AggregatedValue = avg(AvailableMemoryPercentage) by bin(TimeGenerated, 5m), Computer
          '''
          operator: 'GreaterThan'
          timeAggregation: 'Count'
          threshold: 10
          failingPeriods: {
            numberOfEvaluationPeriods: 5
            minFailingPeriodsToAlert: 5
          }
        }
      ]
    }
    autoMitigate: false
  }
}

resource vmDiskutilization 'Microsoft.Insights/scheduledQueryRules@2021-02-01-preview' = {
  name: 'Disk Utliization'
  location: resourceGroup().location
  properties: {
    actions:{
      actionGroups:[
        actionGroup.id
      ]
    }
    severity: 2
    enabled: true
    scopes: [
      logAnalyticsID
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: '''
          InsightsMetrics
          | where Origin == "vm.azm.ms"
          | where Namespace == "Memory" and Name == "AvailableMB"
          | extend TotalMemory = toreal(todynamic(Tags)["vm.azm.ms/memorySizeMB"]) | extend AvailableMemoryPercentage = (toreal(Val) / TotalMemory) * 100.0
          | summarize AggregatedValue = avg(AvailableMemoryPercentage) by bin(TimeGenerated, 5m), Computer

          '''
          operator: 'GreaterThan'
          timeAggregation: 'Count'
          threshold: 5
          failingPeriods: {
            numberOfEvaluationPeriods: 5
            minFailingPeriodsToAlert: 5
          }
        }
      ]
    }
    autoMitigate: false
  }
}

resource vmMissingUpdates 'Microsoft.Insights/scheduledQueryRules@2021-02-01-preview' = {
  name: 'VM Missing Updates'
  location: resourceGroup().location
  properties: {
    actions:{
      actionGroups:[
        actionGroup.id
      ]
    }
    severity: 2
    enabled: true
    scopes: [
      logAnalyticsID
    ]
    evaluationFrequency: 'P1D'
    windowSize: 'P1D'
    criteria: {
      allOf: [
        {
          query: '''
          Update
          | where Classification in ("Security Updates", "Critical Updates")
          | where UpdateState == 'Needed' and Optional == false and Approved == true
          | summarize count() by Classification, Computer, _ResourceId  
          '''
          operator: 'GreaterThan'
          timeAggregation: 'Count'
          threshold: 1
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: false
  }
}


resource actionGroup 'Microsoft.Insights/actionGroups@2019-06-01' = {
  name: 'resource-alerts'
  location: 'Global'
  properties: {
    groupShortName: 'res-alerts'
    enabled: true
    emailReceivers: emailReceivers
  }
}

