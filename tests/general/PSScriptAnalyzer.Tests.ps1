[CmdletBinding()]
param (
	[switch]
	$SkipTest,

	[string[]]
	$CommandPath = @("$global:testroot\..\EntraAuth.Azure\functions", "$global:testroot\..\EntraAuth.Azure\internal\functions")
)

BeforeDiscovery {
	if ($SkipTest) { return }

	$global:__pester_data.ScriptAnalyzer = New-Object System.Collections.ArrayList

	# Create an array containing the path and basename of all files to test
	$commandFiles = $CommandPath | ForEach-Object {
		Get-ChildItem -Path $_ -Recurse | Where-Object Name -Like '*.ps1'
	} | ForEach-Object {
		@{
			BaseName = $_.BaseName
			FullName = $_.FullName
		}
	}

	# Create an array contain all rules
	$scriptAnalyzerRules = Get-ScriptAnalyzerRule | ForEach-Object {
		@{
			RuleName = $_.RuleName
		}
	}
}

Describe 'Invoking PSScriptAnalyzer against commandbase' {

	Context 'Analyzing <BaseName>' -ForEach $commandFiles {
		BeforeAll {
			$settings = Import-PowerShellDataFile -Path "$PSScriptRoot\PSScriptAnalyzer.Config.psd1"
			$analysis = Invoke-ScriptAnalyzer -Path $FullName -ExcludeRule PSAvoidTrailingWhitespace, PSShouldProcess -Settings $settings
		}

		It 'Should pass <RuleName>' -ForEach $scriptAnalyzerRules {
			# Test if the rule is present and if so create a string containing more info which will be shown in the details of the test output. If it's empty the test is succesfull as there is no problem with this rule.
			$analysis | Where-Object RuleName -EQ $RuleName | ForEach-Object {
				# Create a string
				"$($_.Severity) at Line $($_.Line) Column $($_.Column) with '$($_.Extent)'"
				# Add the data (and supress the output) to the global variable for later use
				$null = $global:__pester_data.ScriptAnalyzer.Add($_)
			} | Should -BeNullOrEmpty
		}
	}
}