function Resolve-EntraPrincipal {
	<#
	.SYNOPSIS
		Resolves a principal name or object ID to a Microsoft Entra object ID.

	.DESCRIPTION
		Returns a supplied GUID unchanged or resolves an exact user principal name or display name through Microsoft Graph for supported principal types.
		Name resolution succeeds only when exactly one principal matches and reports errors through the calling cmdlet.

	.PARAMETER Name
		The principal name or object ID to resolve.

	.PARAMETER Type
		The principal type used for name resolution. Supported name lookups are User, Group, ServicePrincipal, and Devices.
		Other types require a GUID in Name.

	.PARAMETER Services
		A hashtable containing the service mappings used to query Microsoft Graph.

	.PARAMETER Cmdlet
		The calling cmdlet context used to report resolution errors.

	.EXAMPLE
		PS C:\> Resolve-EntraPrincipal -Name 'admin@contoso.com' -Type User -Services $services -Cmdlet $PSCmdlet

		Resolves the specified user principal name through Microsoft Graph and returns its object ID.
	#>
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