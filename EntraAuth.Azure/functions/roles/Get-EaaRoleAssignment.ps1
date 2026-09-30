function Get-EaaRoleAssignment {
	[CmdletBinding(DefaultParameterSetName = 'ByResource')]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByResource')]
		[Alias('ID')]
		[string]
		$ResourceID,

		[Parameter(Mandatory = $true, ParameterSetName = 'ByID')]
		[string]
		$Assignment,

		[ValidateSet('Direct', 'All', 'Children', 'Effective')]
		[string]
		$Scope = 'Effective',
		
		[ServiceTransformAttribute()]
		[hashtable]
		$ServiceMap = @{}
	)
	begin {
		$services = $script:_serviceSelector.GetServiceMap($ServiceMap)
		Assert-EntraConnection -Cmdlet $PSCmdlet -Service $services.Azure
	}
	process {
		$query = @{
			'api-version' = '2022-04-01'
		}

		if ($Assignment) {
			$trimmedPath = $Assignment.Trim('/') -replace '/providers/Microsoft.Authorization/roleDefinitions/([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$'
			Invoke-EntraRequest -Service $services.Azure -Path $Assignment -Query $query -ErrorAction Stop | ConvertTo-RoleAssignment -Resource $trimmedPath -Services $services
			return
		}

		if ($Scope -in 'Direct', 'Effective') { $query.'$filter' = 'atScope()' }

		$trimmedPath = $ResourceID.Trim('/')
		Invoke-EntraRequest -Service $services.Azure -Path "$trimmedPath/providers/Microsoft.Authorization/roleAssignments" -Query $query | Where-Object {
			$Scope -eq 'All' -or
			(
				$Scope -eq 'Direct' -and
				$trimmedPath -eq $_.properties.scope.Trim('/')
			) -or
			(
				$Scope -eq 'Children' -and
				$_.properties.scope.Trim('/') -like "$trimmedPath/*"
			) -or
			(
				$Scope -eq 'Effective' -and
				$trimmedPath -like "$($_.properties.scope.Trim('/'))*"
			)
		} | ConvertTo-RoleAssignment -Resource $trimmedPath -Services $services
	}
}