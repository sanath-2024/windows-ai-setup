$ErrorActionPreference = "Stop"

$image = "pi-sbx:local"
$context = Join-Path $PSScriptRoot ".."
$tar = Join-Path $PSScriptRoot "pi-sbx.tar"

docker build -t $image $context

if ($LASTEXITCODE -ne 0) {
    throw "Docker image build failed."
}

Write-Host "Built $image"

docker image save $image -o $tar

if ($LASTEXITCODE -ne 0) {
    throw "Docker image export failed."
}

Write-Host "Exported image to $tar"

sbx template load $tar

if ($LASTEXITCODE -ne 0) {
    throw "Sandbox image load failed."
}

Write-Host "Loaded $image into the sandbox runtime."
