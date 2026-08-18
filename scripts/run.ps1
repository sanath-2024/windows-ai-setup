param(
    [Parameter(Mandatory = $true, ParameterSetName = "Run")]
    [string]$Project,

    # Default model + provider passed to pi on every launch. ~/.pi/agent
    # (settings.json, models.json, auth.json) is NOT persisted across sandbox
    # starts because each sandbox is fresh from the pi-sbx:local template, so we
    # set the default model here via CLI flags instead of relying on settings.
    [Parameter(ParameterSetName = "Run")]
    [string]$Provider = "openrouter",

    [Parameter(ParameterSetName = "Run")]
    [string]$Model = "z-ai/glm-5.2",

    [Parameter(ParameterSetName = "Help")]
    [switch]$Help
)

if ($Help) {
    @"
Usage:
    .\scripts\run.ps1 -Project <path> [-Provider <name>] [-Model <id>]
    .\scripts\run.ps1 -Help

Launches a disposable Pi sandbox against a project, with Pi preinstalled and
OpenRouter-only network access. Each run creates a fresh sandbox from the
pi-sbx:local template and destroys it when Pi exits.

Parameters:
    -Project   (Required) Path to the project directory to mount into the sandbox.

    -Provider  Pi provider name. Default: openrouter
               Passes through to pi as --provider.

    -Model     Model id (supports "provider/id" form and ":<thinking>").
               Default: z-ai/glm-5.2
               Passes through to pi as --model.

    -Help      Show this help and exit.

Notes:
    ~/.pi/agent (settings.json, models.json, auth.json) is NOT persisted
    across sandbox starts, so the default model is set via pi CLI flags
    (--provider/--model) rather than the in-sandbox settings file.

    Pi session history is persisted on the host at
    ~\.pi-sbx-sessions so /resume works across disposable sandboxes.

    The OpenRouter API key is injected by the SBX credential proxy
    (configured in spec.yaml); it does not live in ~/.pi.

Examples:
    .\scripts\run.ps1 C:\code\my-project
    .\scripts\run.ps1 -Project C:\code\my-project -Model anthropic/claude-sonnet-4
    .\scripts\run.ps1 -Project C:\code\my-project -Provider openrouter -Model z-ai/glm-5.2
"@
    exit 0
}

$ErrorActionPreference = "Stop"

$Project = (Resolve-Path $Project).Path
$Repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Name = "pi-" + ([guid]::NewGuid().ToString("N").Substring(0, 12))

# Persist Pi session history on the host so /resume works across the
# disposable sandboxes that run.ps1 creates. sbx run has no --mount flag,
# but additional workspaces are bind-mounted into the sandbox at their host
# path (C:\... -> /c/...). We pass a host dir as a workspace and point
# pi's --session-dir at the in-sandbox copy of that path.
$PiData = Join-Path $env:USERPROFILE ".pi-sbx-sessions"
New-Item -ItemType Directory -Force -Path $PiData | Out-Null

# Convert Windows path to the in-sandbox mount path:
#   C:\Users\...\.pi-sbx-sessions -> /c/Users/.../.pi-sbx-sessions
$drive = $PiData.Substring(0, 1).ToLower()
$rest = $PiData.Substring(2) -replace '\\', '/'
$PiDataSandbox = "/$drive$rest"

try {
    sbx run `
        --name $Name `
        --kit $Repo `
        --template pi-sbx:local `
        pi-openrouter `
        $Project `
        $PiData `
        -- --provider $Provider --model $Model --session-dir $PiDataSandbox
}
finally {
    sbx rm --force $Name 2>$null
}
