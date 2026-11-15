<#
.SYNOPSIS
Releases Buttonstone: dates the changelog, commits, tags and pushes.

.DESCRIPTION
Run on an up-to-date, clean main. The script checks that the version is new,
that both TOC project IDs are in place, that CHANGELOG.md opens with an
"## Unreleased" section that says something, and that the tests pass. It then
turns that heading into "## <version> - <date>", commits "Release <version>",
tags the commit and pushes branch and tag. The tag starts the release
workflow, which uploads to GitHub, CurseForge and Wago.

With -DryRun it checks everything and changes nothing.

.EXAMPLE
.\tools\release.ps1 0.1.0

.EXAMPLE
.\tools\release.ps1 0.1.1 -DryRun
#>
[CmdletBinding()]
param(
	[Parameter(Mandatory = $true, Position = 0)]
	[string]$Version,

	[switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$changelogPath = Join-Path $repo 'CHANGELOG.md'
# Written as code points so Windows PowerShell 5.1 reads this file the same in any code page.
$dash = [char]0x2014

function Step($text) { Write-Host "- $text" }
function Fail($text) { throw "Release stopped: $text" }
# Runs a native command and returns its output as text. Windows PowerShell 5.1
# turns a native command's stderr into errors, and unittest and git write
# there; the exit code in $LASTEXITCODE says whether it worked.
function Run([scriptblock]$Command) {
	$previous = $ErrorActionPreference
	$ErrorActionPreference = 'Continue'
	try { & $Command 2>&1 | ForEach-Object { "$_" } }
	finally { $ErrorActionPreference = $previous }
}

Push-Location $repo
try {
	if ($Version -notmatch '^\d+\.\d+\.\d+$') { Fail "'$Version' is not a version like 0.1.0" }

	Step 'main, clean and up to date'
	$branch = (git rev-parse --abbrev-ref HEAD).Trim()
	if ($branch -ne 'main') { Fail "on '$branch'; switch to main first" }
	if (git status --porcelain) { Fail 'uncommitted changes; commit or stash them first' }
	Run { git fetch --quiet origin } | Out-Null
	if ($LASTEXITCODE -ne 0) { Fail 'could not reach GitHub' }
	if ((git rev-parse HEAD).Trim() -ne (git rev-parse origin/main).Trim()) { Fail 'main differs from origin/main; pull or push first' }

	Step "tag $Version is new"
	if (git tag --list $Version) { Fail "tag $Version exists already" }
	if (git ls-remote --tags origin "refs/tags/$Version") { Fail "tag $Version exists on GitHub already" }

	Step 'CurseForge and Wago projects named in the TOCs'
	foreach ($toc in Get-ChildItem -Path $repo -Filter 'Buttonstone_*.toc') {
		$text = [System.IO.File]::ReadAllText($toc.FullName)
		if ($text -notmatch '(?m)^## X-Curse-Project-ID: \d+') { Fail "$($toc.Name) names no CurseForge project (## X-Curse-Project-ID)" }
		if ($text -notmatch '(?m)^## X-Wago-ID: \w+') { Fail "$($toc.Name) names no Wago project (## X-Wago-ID)" }
	}

	Step 'CHANGELOG.md opens with a filled Unreleased section'
	$changelog = [System.IO.File]::ReadAllText($changelogPath)
	$sections = [regex]::Matches($changelog, '(?m)^## .*$')
	if ($sections.Count -eq 0 -or $sections[0].Value.Trim() -ne '## Unreleased') {
		Fail 'the first section of CHANGELOG.md is not "## Unreleased"'
	}
	$start = $sections[0].Index + $sections[0].Length
	$end = if ($sections.Count -gt 1) { $sections[1].Index } else { $changelog.Length }
	if (-not $changelog.Substring($start, $end - $start).Trim()) { Fail 'the Unreleased section is empty' }

	Step 'tests'
	$python = Join-Path $repo '.venv\Scripts\python.exe'
	if (-not (Test-Path $python)) { $python = 'python' }
	$out = Run { & $python tests/run.py }
	if ($LASTEXITCODE -ne 0) { $out | Write-Host; Fail 'tests/run.py failed' }
	Write-Host "  $($out | Select-Object -Last 1)"
	$out = Run { & $python -m unittest discover -s tests -p 'test_*.py' }
	if ($LASTEXITCODE -ne 0) { $out | Write-Host; Fail 'the TOC tests failed' }
	Write-Host "  TOC tests: $($out | Select-Object -Last 1)"
	if (Get-Command luacheck -ErrorAction SilentlyContinue) {
		$out = Run { luacheck . --quiet }
		if ($LASTEXITCODE -ne 0) { $out | Write-Host; Fail 'luacheck found problems' }
		Write-Host '  luacheck: no warnings'
	}

	$date = (Get-Date).ToString('d MMMM yyyy', [System.Globalization.CultureInfo]::InvariantCulture)
	$heading = "## $Version $dash $date"
	if ($DryRun) {
		Write-Host "Dry run: would date the section as '$heading', commit 'Release $Version', tag $Version and push."
		return
	}

	Step "dating the section: $heading"
	$changelog = $changelog.Substring(0, $sections[0].Index) + $heading + $changelog.Substring($start)
	[System.IO.File]::WriteAllText($changelogPath, $changelog, (New-Object System.Text.UTF8Encoding $false))

	Step "commit, tag and push $Version"
	Run { git add CHANGELOG.md } | Out-Null
	$out = Run { git commit --quiet -m "Release $Version" }
	if ($LASTEXITCODE -ne 0) { $out | Write-Host; Fail 'the release commit failed' }
	$out = Run { git tag -a $Version -m "Buttonstone $Version" }
	if ($LASTEXITCODE -ne 0) { $out | Write-Host; Fail "tagging $Version failed" }
	$out = Run { git push --quiet origin main }
	if ($LASTEXITCODE -ne 0) { $out | Write-Host; Fail 'pushing main failed; the tag is local only' }
	$out = Run { git push --quiet origin $Version }
	if ($LASTEXITCODE -ne 0) { $out | Write-Host; Fail "pushing tag $Version failed" }

	Write-Host "Released $Version. The release workflow uploads it now:"
	Write-Host "  https://github.com/krebs3r/buttonstone-azeroth-buttons/actions"
	Write-Host 'Next: start a new "## Unreleased" section in CHANGELOG.md with the next change.'
}
finally {
	Pop-Location
}
