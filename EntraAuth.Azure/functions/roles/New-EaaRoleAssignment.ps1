function New-EaaRoleAssignment {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$ResourceID,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
		[string]
		$RoleName,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'ByID')]
		[string]
		$RoleID,

		[Parameter(Mandatory = $true)]
		[string]
		$PrincipalID,

		[ValidateSet('User', 'Group', 'ServicePrincipal', 'ForeignGroup', 'Device', 'AgentUser', 'AgentServicePrincipal')]
		[string]
		$PrincipalType,

		[string]
		$Description,

		[string]
		$Condition,

		[string]
		$DelegatedManagedIdentityResourceId,

		[guid]
		$Name = ([guid]::NewGuid()),

		[ServiceTransformAttribute()]
		[hashtable]
		$ServiceMap = @{}
	)
	begin {
		$services = $script:_serviceSelector.GetServiceMap($ServiceMap)
		Assert-EntraConnection -Cmdlet $PSCmdlet -Service $services.Azure
	}
	process {
		if ($RoleName) { $role = Get-EaaRoleDefinition -ResourceID $ResourceID -Name $RoleName -ServiceMap $services -ErrorAction Stop }
		elseif ($RoleID -match '/providers/Microsoft\.Authorization/roleDefinitions/([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$') {
			$role = @{ ID = $RoleID; RoleName = ($RoleID -split '/')[-1] }
		}
		else { $role = Get-EaaRoleDefinition -ResourceID $ResourceID -ID $RoleID -ServiceMap $services -ErrorAction Stop }
		$principal = Resolve-EntraPrincipal -Name $PrincipalID -Type $PrincipalType -Services $services -Cmdlet $PSCmdlet

		$body = @{
			properties = @{
				roleDefinitionId = $role.ID
				principalId      = $principal
			}
		}
		if ($PrincipalType) { $body.properties.principalType = $PrincipalType }
		if ($Description) { $body.properties.description = $Description }
		if ($Condition) { $body.properties.condition = $Condition }
		if ($DelegatedManagedIdentityResourceId) { $body.properties.delegatedManagedIdentityResourceId = $DelegatedManagedIdentityResourceId }

		Invoke-PSFProtectedCommand -Action "Create Role Assignment $($role.RoleName) for $($PrincipalID) on $($ResourceID)" -Target $ResourceID -ScriptBlock {
			Invoke-EntraRequest -Service $services.Azure -Method PUT -Path "$($ResourceID.Trim('/'))/providers/Microsoft.Authorization/roleAssignments/$Name" -Query @{
				'api-version' = '2022-04-01'
			} -ContentType 'application/json' -Body $body | ConvertTo-RoleAssignment -Resource $ResourceID.Trim('/') -Services $services
		} -EnableException $true -PSCmdlet $PSCmdlet
	}
}