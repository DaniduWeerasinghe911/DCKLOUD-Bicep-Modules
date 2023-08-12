targetScope = 'subscription'

@description('Policy Assignment Name')
param policyAssignmentName string

@description('Policy Definition ID')
param policyDefinitionID string

@description('Parameter Values for the Policy')
param parameters object

@description('Location for the identity')
param location string

resource assignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: policyAssignmentName
  location:location
  properties: {
      policyDefinitionId: policyDefinitionID 
      parameters:parameters
  }
  identity: {
    type: 'SystemAssigned'
  }

}

output assignmentId string = assignment.id
