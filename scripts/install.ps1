# Install flutter-superpower into every known Agent Skills location (Windows).
#
#   iwr -useb https://raw.githubusercontent.com/rahulshahDEV/flutter-superpower/main/scripts/install.ps1 | iex
#
# Overrides: $env:FSP_REPO_URL (git remote), $env:FSP_DIR (clone location).
# Re-run any time; it updates the clone and relinks.

$ErrorActionPreference = "Stop"

$Repo = if ($env:FSP_REPO_URL) { $env:FSP_REPO_URL } else { "https://github.com/rahulshahDEV/flutter-superpower.git" }
$Dest = if ($env:FSP_DIR) { $env:FSP_DIR } else { Join-Path $HOME ".flutter-superpower" }
$Name = "flutter-superpower"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Error "git is required"
}

if (Test-Path (Join-Path $Dest ".git")) {
  Write-Host "Updating $Dest"
  git -C $Dest pull --ff-only | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "git pull failed" }
} else {
  Write-Host "Cloning into $Dest"
  git clone --depth 1 $Repo $Dest | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
}

# Resolve links in every existing ancestor before creating an installation directory.
function Get-PhysicalPath([string] $Path, [int] $Depth = 0) {
  if ($Depth -gt 64) { throw "Too many symbolic links in path: $Path" }
  $full = [IO.Path]::GetFullPath($Path)
  $root = [IO.Path]::GetPathRoot($full)
  if ($full -eq $root) { return $root }
  $parent = Get-PhysicalPath ([IO.Path]::GetDirectoryName($full)) ($Depth + 1)
  $candidate = Join-Path $parent ([IO.Path]::GetFileName($full))
  $item = Get-Item -LiteralPath $candidate -Force -ErrorAction SilentlyContinue
  if ($null -ne $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    $linkTarget = @($item.Target)[0]
    if (-not $linkTarget) { throw "Cannot resolve link: $candidate" }
    if (-not [IO.Path]::IsPathRooted($linkTarget)) {
      $linkTarget = Join-Path $parent $linkTarget
    }
    return Get-PhysicalPath $linkTarget ($Depth + 1)
  }
  return $candidate
}

$sourcePath = (Get-PhysicalPath $Dest).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
$comparison = if ($env:OS -eq "Windows_NT") { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }

$targets = @(
  (Join-Path $HOME ".claude\skills"),
  (Join-Path $HOME ".agents\skills"),
  (Join-Path $HOME ".config\opencode\skills"),
  (Join-Path $HOME ".gemini\skills"),
  (Join-Path $HOME ".copilot\skills"),
  (Join-Path $HOME ".codex\skills"),
  (Join-Path $HOME ".cursor\skills")
)

foreach ($parent in $targets) {
  $target = Join-Path $parent $Name
  $physicalTarget = Join-Path (Get-PhysicalPath $parent) $Name
  if ($physicalTarget.Equals($sourcePath, $comparison) -or
      $physicalTarget.StartsWith($sourcePath + [IO.Path]::DirectorySeparatorChar, $comparison)) {
    throw "Installation target is inside skill source: $target"
  }
  $existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
  if ($null -ne $existing) {
    if (-not ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
      Write-Host "SKIP     $target (existing path; remove it manually)"
      continue
    }
    if ((Get-PhysicalPath $target).Equals($sourcePath, $comparison)) {
      Write-Host "ok       $target"
      continue
    }
    # Delete the link itself; never recurse into a junction's destination.
    if ($existing.PSIsContainer) { [IO.Directory]::Delete($target) }
    else { [IO.File]::Delete($target) }
  }
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  New-Item -ItemType Junction -Path $target -Target $Dest | Out-Null
  Write-Host "linked   $target"
}

Write-Host "Done. Restart your agent session to pick up the skill."
