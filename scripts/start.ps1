#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
Push-Location $PSScriptRoot/..
if (-not (Test-Path -Path .env)) {
    if (Test-Path -Path .env.example) {
        Copy-Item .env.example .env -Force
        Write-Host "Created .env from .env.example (edit values as needed in .env)"
    } else {
        Write-Error "No .env or .env.example found. Please create .env."; exit 1
    }
}

Write-Host "Starting docker compose services..."
docker compose up -d

Write-Host "Running LDAP bootstrap (idempotent)"
& "$PSScriptRoot\bootstrap-ldap.sh" 2>&1 | Write-Host

Write-Host "Running Snipe-IT bootstrap (idempotent)"
& "$PSScriptRoot\bootstrap-snipeit.sh" 2>&1 | Write-Host

Write-Host "All bootstraps attempted. Visit http://snipeit.projet.lan (add hosts entry or use localhost with Host header)."
Pop-Location
#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
Set-Location 'C:\Pro\Ecole\Ticketing'

Write-Host "Starting docker compose stack (background)..."
docker compose up -d

Write-Host "Running ldap-bootstrap (one-shot)..."
docker compose run --rm ldap-bootstrap

Write-Host "Showing ldap-bootstrap logs (tail 200)..."
docker compose logs --no-color --tail=200 ldap-bootstrap

Write-Host "Done."
