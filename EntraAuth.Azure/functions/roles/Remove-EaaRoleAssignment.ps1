function Remove-EaaRoleAssignment {
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