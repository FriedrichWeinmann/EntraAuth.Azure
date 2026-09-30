function Resolve-Role {
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