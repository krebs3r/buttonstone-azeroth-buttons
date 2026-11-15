<#
.SYNOPSIS
Copies this checkout into the WoW clients' AddOns folders as Buttonstone.

.DESCRIPTION
WoW finds Buttonstone_Mainline.toc only inside a folder named Buttonstone, so
the checkout is copied under that name, without anything that does not belong
in an addon folder. Without -Flavor it goes to every client installed under
the WoW path; the TOC for each client picks itself.

The WoW path is remembered in tools/.wowpath (ignored by Git) after the first run.

.EXAMPLE
.\tools\install.ps1 -WowPath "C:\Games\World of Warcraft"

.EXAMPLE
.\tools\install.ps1

.EXAMPLE
.\tools\install.ps1 -Flavor forever
#>
[CmdletBinding()]
param(
	[string]$WowPath,

	[ValidateSet('all', 'retail', 'mists', 'anniversary', 'era', 'forever')]
	[string]$Flavor = 'all'
)

$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$pathFile = Join-Path $PSScriptRoot '.wowpath'

if (-not $WowPath) {
	if (Test-Path $pathFile) {
		$WowPath = (Get-Content $pathFile -Raw).Trim()
	} else {
		throw "No WoW path known. Pass -WowPath once, for example: .\tools\install.ps1 -WowPath 'C:\Games\World of Warcraft'"
	}
}
if (-not (Test-Path $WowPath)) {
	throw "WoW path does not exist: $WowPath"
}
Set-Content -Path $pathFile -Value $WowPath -Encoding utf8

# The launcher's folder per client family, as of November 2026.
$clients = [ordered]@{
	retail = '_retail_'
	mists = '_classic_'
	anniversary = '_anniversary_'
	era = '_classic_era_'
	forever = '_forever_'
}
$wanted = if ($Flavor -eq 'all') { $clients.Keys } else { @($Flavor) }

# The packager substitutes @project-version@ on release. A checkout has no
# release to name, so the installed copy gets the commit it was built from.
$version = 'dev'
$sha = (git -C $repo rev-parse --short HEAD 2>$null)
if ($LASTEXITCODE -eq 0 -and $sha) {
	$version = "dev-$sha"
	git -C $repo diff --quiet HEAD 2>$null
	if ($LASTEXITCODE -ne 0) { $version += '-dirty' }
}

# Every dot-folder and dot-file (Git, CI, editors, virtual environments) stays behind.
$excludeDirs = @('.*', 'docs', 'assets', 'tools', 'tests', 'dist')
$excludeFiles = @('.*', 'requirements-dev.txt')
$installed = 0

foreach ($name in $wanted) {
	$addons = Join-Path $WowPath "$($clients[$name])\Interface\AddOns"
	if (-not (Test-Path $addons)) {
		if ($Flavor -ne 'all') { throw "AddOns folder not found: $addons" }
		Write-Host "Skipped $name, not installed ($addons)"
		continue
	}
	$target = Join-Path $addons 'Buttonstone'

	# /MIR so that files deleted in the checkout also disappear from the install.
	robocopy $repo $target /MIR /XD @excludeDirs /XF @excludeFiles /NFL /NDL /NJH /NJS /NP | Out-Null
	if ($LASTEXITCODE -ge 8) {
		throw "robocopy failed for $name with exit code $LASTEXITCODE"
	}
	# /MIR keeps what /XD and /XF skipped, so an earlier hand-copy could leave them behind.
	Get-ChildItem -Path $target -Force | Where-Object {
		$_.Name -like '.*' -or $excludeDirs -contains $_.Name -or $excludeFiles -contains $_.Name
	} | Remove-Item -Recurse -Force
	foreach ($toc in Get-ChildItem -Path $target -Filter '*.toc') {
		$text = [System.IO.File]::ReadAllText($toc.FullName)
		$text = $text -replace '@project-version@', $version
		[System.IO.File]::WriteAllText($toc.FullName, $text, (New-Object System.Text.UTF8Encoding $false))
	}
	Write-Host "Installed $version to $target"
	$installed++
}

if ($installed -eq 0) {
	throw "No client found under $WowPath"
}
Write-Host 'A newly added addon folder is read only when the client starts; restart it fully the first time.'

# robocopy answers 1 for "files copied" and git diff --quiet 1 for "dirty";
# both are ordinary here. Anything that went wrong has thrown by now.
exit 0
