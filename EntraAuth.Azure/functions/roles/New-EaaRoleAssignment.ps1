function New-EaaRoleAssignment {
	<#
	.SYNOPSIS
		Creates an Azure role assignment on a resource.

	.DESCRIPTION
		Creates an Azure role assignment for a principal at the specified resource scope. The role can be selected by name or ID, and the principal can be supplied as an object ID or a resolvable name for supported principal types.

	.PARAMETER ResourceID
		The Azure resource ID at which to create the role assignment.

	.PARAMETER RoleName
		The name of the role definition to assign.

	.PARAMETER RoleID
		The GUID or full Azure resource ID of the role definition to assign.

	.PARAMETER PrincipalID
		The object ID or resolvable name of the principal receiving the role.
		Non-IDs can only be resolved when providing a PrincipalType, and then only for specific principal types:

		- Device: DisplayName
		- Group: DisplayName
		- ServicePrincipalName: DisplayName
		- User: UserPrincipalName

		Since displaynames are not guaranteed to be unique, resolution by name fails if it resolves to more than one object.
		
		Resolving names requires an established Graph connection!
		This can be established like this, assuming you are connected with the default Azure service already:
		
		Connect-EntraService -Service Graph -ClientID Azure -UseRefreshToken

	.PARAMETER PrincipalType
		The type of principal receiving the role.
		For User, Group, ServicePrincipal, and Device names can be resolved, if the type is specified.

	.PARAMETER Description
		A description to store on the role assignment.

	.PARAMETER Condition
		An Azure role assignment condition that limits the granted permissions.

	.PARAMETER DelegatedManagedIdentityResourceId
		The resource ID of the delegated managed identity associated with the role assignment.

	.PARAMETER Name
		The GUID used as the role assignment name.
		Defaults to: a newly generated GUID

	.PARAMETER ServiceMap
		Optional hashtable to map service names to specific EntraAuth service instances.
		Used for advanced scenarios where you want to use something other than the default Azure connection.
		Example: @{ Azure = 'MyAzure' }
		This will switch all Azure API calls to use the configuration defined in MyAzure.
		Defaults to: @{}

	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

	.EXAMPLE
		PS C:\> New-EaaRoleAssignment -ResourceID '/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/Production' -RoleName 'Reader' -PrincipalID 'admin@contoso.com' -PrincipalType User

		Assigns the Reader role on the Production resource group to the specified user.

	.EXAMPLE
		PS C:\> New-EaaRoleAssignment -ResourceID '/subscriptions/00000000-0000-0000-0000-000000000001' -RoleID 'acdd72a7-3385-48ef-bd42-f606fba81ae7' -PrincipalID '11111111-1111-1111-1111-111111111111'

		Assigns the role definition with the specified ID at the subscription scope to the specified principal object ID.
	#>
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