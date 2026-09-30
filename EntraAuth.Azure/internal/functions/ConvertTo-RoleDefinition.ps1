function ConvertTo-RoleDefinition {
	<#
	.SYNOPSIS
		Converts Azure API role definition data into module role definition objects.

	.DESCRIPTION
		Transforms role definition data returned by the Azure API into EntraAuth.Azure.RoleDefinition objects with normalized identity, scope, permission, and timestamp properties while preserving the original object.

	.PARAMETER InputObject
		The Azure API role definition object to convert.

	.EXAMPLE
		PS C:\> $response | ConvertTo-RoleDefinition

		Converts each role definition in the Azure API response into an EntraAuth.Azure.RoleDefinition object.
	#>
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