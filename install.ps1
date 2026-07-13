param(
    [switch]$Global
)

$skillPath = Split-Path -Parent $PSCommandPath
$targets = @()

if ($Global) {
    # Per-user install paths
    $globalPaths = @(
        @{Path = "$env:USERPROFILE\.claude\skills"; Agent = "Claude Code"},
        @{Path = "$env:USERPROFILE\.config\opencode\skills"; Agent = "OpenCode"},
        @{Path = "$env:USERPROFILE\.agents\skills"; Agent = "Codex CLI"},
        @{Path = "$env:USERPROFILE\.gemini\skills"; Agent = "Gemini CLI"},
        @{Path = "$env:USERPROFILE\.copilot\skills"; Agent = "GitHub Copilot"}
    )
    $targets += $globalPaths
} else {
    # Project-scoped install paths
    $projectPaths = @(
        @{Path = ".claude\skills"; Agent = "Claude Code"},
        @{Path = ".cursor\skills"; Agent = "Cursor"},
        @{Path = ".windsurf\skills"; Agent = "Windsurf"},
        @{Path = ".opencode\skills"; Agent = "OpenCode"},
        @{Path = ".agents\skills"; Agent = "Codex CLI"},
        @{Path = ".gemini\skills"; Agent = "Gemini CLI"},
        @{Path = ".github\skills"; Agent = "GitHub Copilot"}
    )
    $targets += $projectPaths
}

$installed = 0
$found = 0

foreach ($t in $targets) {
    $parent = $t.Path
    if (Test-Path -LiteralPath $parent) {
        $found++
        $dest = Join-Path $parent "peer-review"
        if (Test-Path -LiteralPath $dest) {
            Write-Host "  [SKIP] $($t.Agent) — already installed at $dest"
        } else {
            New-Item -ItemType Directory -Path $dest -Force | Out-Null
            Copy-Item -Path "$skillPath\*" -Destination $dest -Recurse -Force
            Write-Host "  [ OK ] $($t.Agent) — installed to $dest"
            $installed++
        }
    }
}

if ($found -eq 0) {
    $scope = if ($Global) { "per-user" } else { "project" }
    Write-Host "No $scope agent directories found. Create one and re-run, or pass -Global for per-user install."
} else {
    Write-Host "Done. $installed installed, $($found - $installed) already present."
}
