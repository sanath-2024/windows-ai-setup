param(
    [Parameter(Mandatory = $true)]
    [string]$Project
)

$ErrorActionPreference = "Stop"

$Project = (Resolve-Path $Project).Path
$Repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Name = "pi-" + ([guid]::NewGuid().ToString("N").Substring(0, 12))

try {
    sbx run `
        --name $Name `
        --kit $Repo `
        --template pi-sbx:local `
        pi `
        $Project
}
finally {
    sbx rm --force $Name 2>$null
}
