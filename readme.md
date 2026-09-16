# EntraAuth.Azure

Welcome to `EntraAuth.Azure`, the PowerShell module providing core functionality for interacting with the Azure Resource Manager API using the [EntraAuth module](https://github.com/FriedrichWeinmann/EntraAuth).
This provides tools needed to usefully interact with most of the APIs in the service.

Notably:

+ Subscription Resolution / Listing
+ Location Resolution / Listing
+ Creating, maintiaining, and deleting resource groups

It also offers related conveniences for [PSFramework tab completion](https://psframework.org/docs/PSFramework/TabExpansion/overview), enabling you to provide better user experiences for your own commands' paramters.

> This module implements the [PSFramework Scripting Framework](https://psframework.org)

## Installation

To install the module, run:

```powershell
Install-Module -Name 'EntraAuth.Azure' -Scope CurrentUser
```

Alternatively, if you have any trouble getting modules installed, this might work instead:

```powershell
Invoke-WebRequest 'https://raw.githubusercontent.com/PowershellFrameworkCollective/PSFramework.NuGet/refs/heads/master/bootstrap.ps1' -UseBasicParsing | Invoke-Expression
Install-PSFModule -Name 'EntraAuth.Azure'
```

## Profit

> Connect

```powershell
Connect-EntraService -Service Azure -ClientID Azure
```

Note: See [the EntraAuth module documentation](https://github.com/FriedrichWeinmann/EntraAuth) for more ways to authenticate.

> List Subscriptions

```powershell
Get-EaaSubscription
```

> List Locations

```powershell
Get-EaaLocation -Subscription 00000000-0000-0000-0000-000000000000
```

> List Resource Groups

```powershell
Get-EaaResourceGroup -Subscription 00000000-0000-0000-0000-000000000000
```

> Create Resource Group

```powershell
New-EaaResourceGroup -Subscription 00000000-0000-0000-0000-000000000000 -Name Test_PS -Location westeurope
```

> Add Tab Completion to Subscription, ResourceGroup, or Location

```powershell
function New-AzureLogAnalyticsWorkspace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PsfArgumentCompleter('EntraAuth.Azure.Subscription')]
        [string]
        $Subscription,

        [Parameter(Mandatory = $true)]
        [PsfArgumentCompleter('EntraAuth.Azure.Location')]
        [string]
        $Location,

        [Parameter(Mandatory = $true)]
        [PsfArgumentCompleter('EntraAuth.Azure.ResourceGroup')]
        [string]
        $ResourceGroup

        # ...
    )
    # ...
}
```

> Add Tab Completion to a command without changing its code

```powershell
Register-PSFTeppArgumentCompleter -Command New-AzureLogAnalyticsWorkspace -Parameter Subscription -Name 'EntraAuth.Azure.Subscription'
```

Notes:

+ All completers will pass through the [ServiceMap parameter](https://github.com/FriedrichWeinmann/EntraAuth/blob/master/docs/building-on-entraauth.md) of the commands they are attached to. If the commands do not have that, the completers will use the default EntraAuth service: `Azure`. This is an advanced implementation aspect - if this does not mean anything to you, you likely need not worry about this caveat.
+ The Argument Completer for Locations require a Parameter `Subscription` to be present and provided on the command it is attached to, in order to work.
