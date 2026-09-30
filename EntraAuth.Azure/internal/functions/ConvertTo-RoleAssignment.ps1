function ConvertTo-RoleAssignment {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,

		[string]
		$Resource,

		[hashtable]
		$Services
	)
	process {
		if (-not $InputObject) { return }

		$inheritedFrom = $InputObject.properties.scope.Trim()
		if ($inheritedFrom.Length -ge $Resource.Length) { $inheritedFrom = '' }

		$role = Resolve-Role -ID $InputObject.properties.roleDefinitionId -Services $Services

		[PSCustomObject]@{
			PSTypeName                         = 'EntraAuth.Azure.RoleAssignment'
			ID                                 = $InputObject.id
			Name                               = $InputObject.name
			RoleName                           = $role.RoleName
			RoleID                             = $InputObject.properties.roleDefinitionId
			PrincipalID                        = $InputObject.properties.principalID
			PrincipalType                      = $InputObject.properties.principalType
			InheritedFrom                      = $inheritedFrom
			Resource                           = $Resource
			Scope                              = $InputObject.properties.scope
			Condition                          = $InputObject.properties.condition
			ConditionVersion                   = $InputObject.properties.conditionVersion
			CreatedOn                          = $InputObject.properties.createdOn
			UpdatedOn                          = $InputObject.properties.updatedOn
			CreatedBy                          = $InputObject.properties.createdBy
			UpdatedBy                          = $InputObject.properties.updatedBy
			DelegatedManagedIdentityResourceId = $InputObject.properties.delegatedManagedIdentityResourceId

			Role                               = $role
			Object                             = $InputObject
		}
	}
}