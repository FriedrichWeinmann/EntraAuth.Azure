---
name: document-powershell-functions
description: 'Write or complete PowerShell comment-based help. Use when a module contains top-level functions with no help, undocumented parameters, or parameter sets without examples. Preserve complete help and existing documented segments; add only missing documentation and syntax-check each changed file.'
argument-hint: 'Optionally specify files, folders, or function names'
---

# Document PowerShell Functions

Create or complete comment-based help for PowerShell functions without rewriting documentation that already satisfies the requirements.

## Scope

- Process functions declared with the `function` keyword.
- Exclude functions nested inside another function.
- Respect any file, folder, module, or function scope supplied by the user.
- When no scope is supplied, inspect the current module or workspace surface relevant to the request.
- Change a function only when it has no comment-based help or when required coverage is missing.
- Leave a function's help unchanged when all required sections, parameters, and parameter sets are already documented.

## Required Help

Help created for a previously undocumented function contains only these sections:

- `.SYNOPSIS`: one sentence summarizing what the function does.
- `.DESCRIPTION`: the command's purpose, behavior, filtering or output details, and other facts a user needs.
- `.PARAMETER <Name>`: one entry for every declared parameter, explaining its use. State an explicitly assigned default value. For switches, describe the behavior when specified and, when useful, the behavior when omitted.
- `.EXAMPLE`: at least one example for every parameter set. Put the command first, followed by a blank line and prose explaining what executing it does.

Do not add `.NOTES`, `.LINK`, `.INPUTS`, `.OUTPUTS`, or any other unrequested help section.

## Style

- Write for users of the command, not maintainers of its implementation.
- Keep the synopsis to one direct sentence.
- Keep parameter descriptions concise. Do not narrate parameter-set selection unless that fact helps a user invoke the command correctly.
- Parameters that have a default value should explain this in a separate line with `Defaults to: {{value}}`. This does not apply to Switch parameters.
- Use concrete, realistic values in examples.
- Use `PS C:\>` as the example prompt.
- Explain the observable result of each example rather than merely repeating its syntax.
- Follow established wording for recurring module parameters. For example, when a module uses a service mapping parameter, prefer its existing multiline explanation over inventing a new variant.
- Match the indentation, line endings, spelling, terminology, and voice of nearby manually maintained help.

## Procedure

1. Inventory explicit `function` declarations in scope and identify nesting from the PowerShell AST or surrounding syntax.
2. Read each top-level function's current help, attributes, parameter block, parameter-set declarations, default parameter set, and behavior-controlling implementation.
3. Build a coverage list for each function:
   - comment-based help is absent;
   - `.SYNOPSIS` is absent or empty;
   - `.DESCRIPTION` is absent or empty;
   - a declared parameter has no matching `.PARAMETER` section or its section is empty;
   - an explicitly assigned parameter default is not described;
   - a parameter set has no `.EXAMPLE` that demonstrates a valid invocation and explains its result.
4. Skip functions whose coverage list is empty.
5. For a function with no help, add one complete help block containing only the required sections.
6. For partial help, make additive, localized changes only:
   - preserve existing wording and formatting;
   - add only missing or empty required sections;
   - add only missing parameter documentation;
   - add only examples needed for uncovered parameter sets;
   - amend a parameter description only when needed to document a newly introduced explicit default;
   - do not reorder, normalize, or rewrite already documented sections.
7. Place a new help block immediately beneath the line containing the `function` keyword and above attributes such as `[CmdletBinding()]` and the `param` block. Insert missing sections into an existing block without moving that block.
8. Re-read the edited help against the current parameter block and parameter sets. Confirm every declared parameter is covered and every parameter set has at least one valid example.
9. Parse each updated file independently with the PowerShell parser. Report and fix syntax errors introduced by the documentation edit.
10. Report which functions changed, which missing coverage was added, and the syntax result for every updated file.

## Parameter-Set Coverage

- Count named parameter sets declared through `ParameterSetName` and account for `DefaultParameterSetName`.
- Treat parameters without a `ParameterSetName` as common parameters available across sets.
- An example covers a set only when its arguments form a valid invocation of that set.
- A single example may cover only the set selected by its set-specific arguments. If it uses only common parameters and is ambiguous, count it for the default parameter set only.
- When no named parameter sets exist, require at least one example.

## Preservation Rules

- Never replace an entire existing help block merely to improve its prose.
- Never change a documented synopsis, description, parameter, or example unless it is empty, factually invalidated by the current function, or must be minimally amended to describe a new explicit default.
- Do not remove extra sections from pre-existing help during a coverage-only update; the instruction against extra sections applies to newly generated content.
- Do not document nested helper functions unless the user explicitly asks for them.
- Do not modify function behavior while documenting it.
- Do not change files that require no documentation additions.

## Syntax Validation

For each changed file, use the PowerShell parser and fail on parser errors. An equivalent validation is:

```powershell
$tokens = $null
$errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path $file),
    [ref] $tokens,
    [ref] $errors
)

if ($errors.Count) {
    $errors | ForEach-Object { Write-Error $_.Message }
    throw "PowerShell syntax validation failed for $file"
}
```

Validation must run after the final edit to each updated file. Do not claim syntax correctness based only on editor diagnostics or visual review.
