function New-EaaResourceGroup {
	<#
	.SYNOPSIS
		Creates an Azure resource group.

	.DESCRIPTION
		Creates a resource group with the specified name and location in an Azure subscription. The new group can optionally be associated with a managing resource and initialized with tags.

	.PARAMETER Subscription
		The subscription name or ID in which the resource group is created.

	.PARAMETER Name
		The name of the resource group to create.

	.PARAMETER Location
		The Azure location in which resource group metadata is stored.

	.PARAMETER ManagedBy
		The resource ID, represented as a GUID, of the resource that manages this resource group.

	.PARAMETER Tags
		A hashtable of tag names and values assigned to the new resource group.

	.PARAMETER WhatIf
		If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.PARAMETER Confirm
		If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

	.PARAMETER ServiceMap
		Optional hashtable to map service names to specific EntraAuth service instances.
		Used for advanced scenarios where you want to use something other than the default Azure connection.
		Example: @{ Azure = 'MyAzure' }
		This will switch all Azure API calls to use the configuration defined in MyAzure.

	.EXAMPLE
		PS C:\> New-EaaResourceGroup -Subscription 'Production' -Name 'WebApps' -Location 'eastus' -Tags @{ Environment = 'Prod' }

		Creates the WebApps resource group in eastus under the Production subscription and assigns it an Environment tag with the value Prod.
	#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	param (
		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('EntraAuth.Azure.Subscription')]
		[string]
		$Subscription,

		[Parameter(Mandatory = $true)]
		[PsfValidatePattern('^[-\w\._\(\)]{1,90}$', ErrorMessage = 'Resource Groups must not be longer than 90 characters, not contain whitespace or special characters!')]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[PsfArgumentCompleter('EntraAuth.Azure.Location')]
		[string]
		$Location,

		[string]
		$ManagedBy,

		[hashtable]
		$Tags,

		[ServiceTransformAttribute()]
		[hashtable]
		$ServiceMap = @{}
	)
	begin {
		$services = $script:_serviceSelector.GetServiceMap($ServiceMap)
		Assert-EntraConnection -Cmdlet $PSCmdlet -Service $services.Azure
		$subscriptionID = Resolve-Subscription -Name $Subscription -Services $services -Cmdlet $PSCmdlet
	}
	process {
		$body = @{
			location = $Location
		}
		if ($ManagedBy) { $body.managedBy = $ManagedBy }
		if ($Tags) { $body.tags = $Tags }

		Invoke-PSFProtectedCommand -Action "Create Resource Group $Name in $Location under Subscription $SubscriptionID" -Target $Name -ScriptBlock {
			Invoke-EntraRequest -Service $services.Azure -Method PUT -Path "subscriptions/$subscriptionID/resourcegroups/$Name" -Query @{
				'api-version' = '2021-04-01'
			} -Body $body -ContentType 'application/json' | ConvertTo-ResourceGroup -SubscriptionID $subscriptionID
		} -EnableException $true -PSCmdlet $PSCmdlet
	}
}