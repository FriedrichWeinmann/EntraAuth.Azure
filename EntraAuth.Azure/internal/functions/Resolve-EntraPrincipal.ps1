function Resolve-EntraPrincipal {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,

		[Parameter(Mandatory = $true)]
		[AllowEmptyString()]
		[string]
		$Type,

		[Parameter(Mandatory = $true)]
		[hashtable]
		$Services,

		[Parameter(Mandatory = $true)]
		$Cmdlet
	)
	process {
		if ($Name -as [guid]) { return $Name }

		Assert-EntraConnection -Cmdlet $Cmdlet -Service $Services.Graph

		$param = switch ($Type) {
			'User' {
				@{
					Path  = 'users'
					Query = @{ '$filter' = "userPrincipalName eq '$Name'" }
				}
			}
			'Group' {
				@{
					Path  = 'groups'
					Query = @{ '$filter' = "displayName eq '$Name'" }
				}
			}
			'ServicePrincipal' {
				@{
					Path  = 'servicePrincipals'
					Query = @{ '$filter' = "displayName eq '$Name'" }
				}
			}
			'Devices' {
				@{
					Path  = 'devices'
					Query = @{ '$filter' = "displayName eq '$Name'" }
				}
			}
			default {
				Stop-PSFFunction -Message "Cannot resolve identities of type '$($Type)'! Provide a Guid as Principal ID." -Target $Name -EnableException $true -Cmdlet $Cmdlet
			}
		}

		try { $results = Invoke-EntraRequest -Service $Services.Graph @param -ErrorAction Stop }
		catch { Stop-PSFFunction -Message "Error resolving $Type $Name" -ErrorRecord $_ -Target $Name -EnableException $true -Cmdlet $Cmdlet }

		if (-not $results) {
			Stop-PSFFunction -Message "Cannot resolve $Type $Name - no match found" -Target $Name -Category ObjectNotFound -EnableException $true -Cmdlet $Cmdlet
		}

		if (@($results).Count -gt 1) {
			Stop-PSFFunction -Message "Cannot resolve $Type $Name - ambiguous results: $(@($results).Count) ($($results.id -join ', '))" -Target $Name -Category ObjectNotFound -EnableException $true -Cmdlet $Cmdlet
		}

		$results.id
	}
}