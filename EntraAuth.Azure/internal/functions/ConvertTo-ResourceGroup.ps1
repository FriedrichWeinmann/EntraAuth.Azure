function ConvertTo-ResourceGroup {
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