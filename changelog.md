# Changelog

## 1.1.10 (2026-09.30)

+ Fix: Get-EaaRoleAssignment - incorrect resource identifcation when retrieving a specific assignment by its ID
+ Fix: Get-EaaRoleDefinition - fails to convert raw data when retrieving a specified role definition
+ Fix: New-EaaRoleAssignment - failed to resolve devices
+ Fix: Search-EaaGraph - Options hashtable would be modified in the caller scope if combined with explicit parameters
+ Fix: Set-EaaResourceGroup - Cannot clear ManagedBy or Tags

## 1.1.5 (2026-09-30)

+ New: Command Get-EaaRoleAssignment
+ New: Command Get-EaaRoleDefinition
+ New: Command New-EaaRoleAssignment
+ New: Command Search-EaaGraph
+ New: Command Remove-EaaRoleAssignment

## 1.0.0 (2026-09-16)

+ New: Initial Release
