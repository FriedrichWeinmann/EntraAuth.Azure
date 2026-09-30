function ConvertTo-RoleAssignment {
	<#
	.SYNOPSIS
		Converts Azure API role assignment data into module role assignment objects.

	.DESCRIPTION
		Transforms role assignment data returned by the Azure API into EntraAuth.Azure.RoleAssignment objects.
		The conversion resolves role details, identifies inherited assignments relative to the requested resource, and preserves the original object.

	.PARAMETER InputObject
		The Azure API role assignment object to convert.

	.PARAMETER Resource
		The resource ID used to determine whether the role assignment is inherited.

	.PARAMETER Services
		A hashtable containing the service mappings used to resolve role definitions.

	.EXAMPLE
		PS C:\> $response | ConvertTo-RoleAssignment -Resource 'subscriptions/00000000-0000-0000-0000-000000000001' -Services $services

		Converts each Azure API role assignment into an EntraAuth.Azure.RoleAssignment object with resolved role and inheritance details.
	#>
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