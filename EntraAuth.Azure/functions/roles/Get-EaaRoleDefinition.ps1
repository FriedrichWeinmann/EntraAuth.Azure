function Get-EaaRoleDefinition {
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
			}
			return
		}

		$query = @{
			'api-version' = '2022-04-01'
		}
		if ($Name -notmatch '\*') { $query.'$filter' = "roleName eq '$Name'" }

		Invoke-EntraRequest -Service $services.Azure -Path "$ResourceID/providers/Microsoft.Authorization/roleDefinitions" -Query $query | Where-Object {
			-not $Name -or
			$_.properties.roleName -like $Name
		} | ConvertTo-RoleDefinition
	}
}