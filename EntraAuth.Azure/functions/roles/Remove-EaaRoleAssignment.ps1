function Remove-EaaRoleAssignment {
	<#
	.SYNOPSIS
		Removes an Azure role assignment.

	.DESCRIPTION
		Resolves an Azure role assignment by its resource ID and removes it after confirmation. The command rejects IDs that do not identify exactly one assignment.

	.PARAMETER ID
		The full Azure resource ID of the role assignment to remove.

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
		PS C:\> Remove-EaaRoleAssignment -ID '/subscriptions/00000000-0000-0000-0000-000000000001/providers/Microsoft.Authorization/roleAssignments/11111111-1111-1111-1111-111111111111' -Confirm

		Removes the specified role assignment after displaying a confirmation prompt.
	#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
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
		$assignment = Get-EaaRoleAssignment -Assignment $ID -ServiceMap $services
		if (-not $assignment) {
			Stop-PSFFunction -Message "Role Assignment not found: $ID" -EnableException $true -Cmdlet $PSCmdlet -Category ObjectNotFound -Target $ID
		}
		if (@($assignment).Count -gt 1) {
			Stop-PSFFunction -Message "Ambiguous Role Assignment: $ID" -EnableException $true -Cmdlet $PSCmdlet -Category InvalidArgument -Target $ID
		}

		Invoke-PSFProtectedCommand -Action "Deleting Role Assignment $($assignment.RoleName) for $($assignment.PrincipalID) on $($assignment.Resource)" -Target $assignment.Scope -ScriptBlock {
			Invoke-EntraRequest -Service $services.Azure -Method DELETE -Path $ID -Query @{
				'api-version' = '2022-04-01'
			}
		} -EnableException $true -PSCmdlet $PSCmdlet
	}
}