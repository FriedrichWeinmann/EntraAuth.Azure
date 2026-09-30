function ConvertTo-RoleDefinition {
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject
	)
	process {
		if (-not $InputObject) { return }

		[PSCustomObject]@{
			PSTypeName       = 'EntraAuth.Azure.RoleDefinition'
			RoleName         = $InputObject.properties.roleName
			RoleID           = $InputObject.name
			ID               = $InputObject.id
			Type             = $InputObject.properties.type
			AssignableScopes = $InputObject.properties.assignableScopes
			CreatedOn        = $InputObject.properties.createdOn
			UpdatedOn        = $InputObject.properties.updatedOn
			Allow            = $InputObject.properties.permissions.actions
			DataAllow        = $InputObject.properties.permissions.dataActions
			Deny             = $InputObject.properties.permissions.notActions
			DataDeny         = $InputObject.properties.permissions.notDataActions

			Permissions      = $InputObject.properties.permissions

			Object           = $InputObject
		}
	}
}