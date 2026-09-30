function Get-EaaRoleDefinition {
	<#
	.SYNOPSIS
		Retrieves Azure role definitions by name or ID.

	.DESCRIPTION
		Retrieves Azure role definitions available at a resource scope.
		A subscription GUID can be supplied as the resource ID and is expanded to its subscription scope.

	.PARAMETER ResourceID
		The Azure resource ID or subscription ID at whose scope role definitions are retrieved.

	.PARAMETER Name
		A wildcard pattern used to filter role definition names.
		Defaults to: *

	.PARAMETER ID
		The role definition GUID or full Azure resource ID to retrieve.

	.PARAMETER ServiceMap
		Optional hashtable to map service names to specific EntraAuth service instances.
		Used for advanced scenarios where you want to use something other than the default Azure connection.
		Example: @{ Azure = 'MyAzure' }
		This will switch all Azure API calls to use the configuration defined in MyAzure.
		Defaults to: @{}

	.EXAMPLE
		PS C:\> Get-EaaRoleDefinition -ResourceID '00000000-0000-0000-0000-000000000001' -Name 'Reader'

		Retrieves the Reader role definition available to the specified subscription.

	.EXAMPLE
		PS C:\> Get-EaaRoleDefinition -ResourceID '00000000-0000-0000-0000-000000000001' -ID 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

		Retrieves the role definition with the specified ID at the subscription scope.
	#>
	[CmdletBinding(DefaultParameterSetName = 'ByName')]
	param (
		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('EntraAuth.Azure.Subscription')]
		[string]
		$ResourceID,

		[Parameter(ParameterSetName = 'ByName')]
		[string]
		$Name = '*',
		
		[Parameter(Mandatory = $true, ParameterSetName = 'ByID')]
		[string]
		$ID,

		[ServiceTransformAttribute()]
		[hashtable]
		$ServiceMap = @{}
	)
	begin {
		$services = $script:_serviceSelector.GetServiceMap($ServiceMap)
		Assert-EntraConnection -Cmdlet $PSCmdlet -Service $services.Azure
	}
	process {
		if ($ResourceID -as [guid]) {
			$resourceID = "subscriptions/$ResourceID"
		}

		if ($ID) {
			if ($ID -as [guid]) { $url = "$ResourceID/providers/Microsoft.Authorization/roleDefinitions/$ID" }
			else { $url = $ID }
			Invoke-EntraRequest -Service $services.Azure -Path $url -Query @{
				'api-version' = '2022-04-01'
			} | ConvertTo-RoleDefinition
			return
		}

		$query = @{
			'api-version' = '2022-04-01'
		}
		if ($Name -notmatch '\*') { $query.'$filter' = "roleName eq '$($Name -replace "'", "''")'" }

		Invoke-EntraRequest -Service $services.Azure -Path "$ResourceID/providers/Microsoft.Authorization/roleDefinitions" -Query $query | Where-Object {
			-not $Name -or
			$_.properties.roleName -like $Name
		} | ConvertTo-RoleDefinition
	}
}