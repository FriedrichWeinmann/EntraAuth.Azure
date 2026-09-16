function ConvertTo-ResourceGroup {
	<#
	.SYNOPSIS
		Converts Azure API resource group data into module resource group objects.

	.DESCRIPTION
		Transforms resource group data returned by the Azure API into EntraAuth.Azure.ResourceGroup objects. The conversion preserves the original object and adds normalized resource group properties and subscription context.

	.PARAMETER InputObject
		The Azure API resource group object to convert. Objects are accepted from the pipeline.

	.PARAMETER SubscriptionID
		The subscription ID associated with the resource group, added to the converted object's Subscription property.

	.EXAMPLE
		PS C:\> $response | ConvertTo-ResourceGroup -SubscriptionID '00000000-0000-0000-0000-000000000001'

		Converts each resource group in the Azure API response into an EntraAuth.Azure.ResourceGroup object and records the specified subscription ID.
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,

		[string]
		$SubscriptionID
	)
	begin {
		$converter = { ConvertTo-PSFHashtable }.GetSteppablePipeline()
		$converter.Begin($true)
	}
	process {
		if (-not $InputObject) { return }

		[PSCustomObject]@{
			PSTypeName   = 'EntraAuth.Azure.ResourceGroup'
			Name         = $InputObject.name
			ID           = $InputObject.id
			Location     = $InputObject.location
			Tags         = $($converter.Process($InputObject.tags))
			Properties   = $InputObject.properties
			Subscription = $SubscriptionID

			Object       = $InputObject
		}
	}
	end {
		$converter.End()
	}
}