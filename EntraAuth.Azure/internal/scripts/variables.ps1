# Module-wide variables go here
# For example if you want to cache some data, have some module-wide config settings, etc. ... those could go here
# Example:
# $script:config = @{ }
$script:_services = @{
	Azure = 'Azure'
	Graph = 'Graph'
}

$script:_serviceSelector = New-EntraServiceSelector -DefaultServices $script:_services

$script:_RoleDefinitionCache = New-PSFCache -MaxItems 1000 -Lifetime 30m