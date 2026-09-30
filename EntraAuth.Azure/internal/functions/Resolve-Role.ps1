function Resolve-Role {
	<#
	.SYNOPSIS
		Resolves an Azure role definition ID to a role definition object.

	.DESCRIPTION
		Retrieves and caches role definitions for the resource scope embedded in an Azure role definition ID, then returns the definition whose full ID matches the supplied value.

	.PARAMETER ID
		The full Azure resource ID of the role definition to resolve.

	.PARAMETER Services
		A hashtable containing the service mappings used to retrieve role definitions.

	.EXAMPLE
		PS C:\> Resolve-Role -ID '/subscriptions/00000000-0000-0000-0000-000000000001/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7' -Services $services

		Returns the matching role definition, retrieving and caching definitions for the subscription scope when necessary.
	#>
	[CmdletBinding()]
	param (
		[string]
		$ID,

		[hashtable]
		$Services
	)
	process {
		$resource = $ID -replace '/providers/Microsoft.Authorization/roleDefinitions/([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$'
		if (-not $script:_RoleDefinitionCache[$resource]) {
			$script:_RoleDefinitionCache[$resource] = Get-EaaRoleDefinition -ServiceMap $Services -ResourceID $resource
		}
		$script:_RoleDefinitionCache[$resource] | Where-Object ID -EQ $ID
	}
}