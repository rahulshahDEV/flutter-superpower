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
} else {
  Write-Host "Cloning into $Dest"
  git clone --depth 1 $Repo $Dest | Out-Null
}

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
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  $target = Join-Path $parent $Name
  if (Test-Path $target) { Remove-Item -Recurse -Force $target }
  New-Item -ItemType Junction -Path $target -Target $Dest | Out-Null
  Write-Host "linked   $target"
}

Write-Host "Done. Restart your agent session to pick up the skill."
