function Get-EaaRoleAssignment {
	<#
	.SYNOPSIS
		Retrieves Azure role assignments by resource or assignment ID.

	.DESCRIPTION
		Retrieves Azure role assignments.
		Resource queries can return assignments at the resource, inherited from parent scopes, assigned to child scopes, or all assignments visible from the resource.

	.PARAMETER ResourceID
		The Azure resource ID whose role assignments are retrieved.

	.PARAMETER Assignment
		The full Azure resource ID of a specific role assignment to retrieve.

	.PARAMETER Scope
		Controls which role assignments are returned for a resource: Direct, All, Children, or Effective.
		+ Direct: Only returns role assignments on the object itself.
		+ All: Returns all role assignments on parent scopes, the object itself and any child-scopes.
		+ Children: Return only role assignments on child objects of the specified resource
		+ Effective: Return all role assignments on the resource itself and those it inherits from its parents.

		Defaults to: Effective

	.PARAMETER ServiceMap
		Optional hashtable to map service names to specific EntraAuth service instances.
		Used for advanced scenarios where you want to use something other than the default Azure connection.
		Example: @{ Azure = 'MyAzure' }
		This will switch all Azure API calls to use the configuration defined in MyAzure.
		Defaults to: @{}

	.EXAMPLE
		PS C:\> Get-EaaRoleAssignment -ResourceID '/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/Production' -Scope Direct

		Retrieves role assignments made directly on the Production resource group.

	.EXAMPLE
		PS C:\> Get-EaaRoleAssignment -Assignment '/subscriptions/00000000-0000-0000-0000-000000000001/providers/Microsoft.Authorization/roleAssignments/11111111-1111-1111-1111-111111111111'

		Retrieves the role assignment with the specified resource ID.
	#>
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