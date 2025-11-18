#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
Set-Location 'C:\Pro\Ecole\Ticketing'

$max=60
for($i=1;$i -le $max;$i++){
    Write-Host ("Attempt {0} of {1}: running php artisan key:generate --force --show" -f $i,$max)
    $proc = Start-Process -FilePath 'docker' -ArgumentList 'compose','exec','snipe-it','php','artisan','key:generate','--force','--show' -NoNewWindow -RedirectStandardOutput 'out.txt' -RedirectStandardError 'err.txt' -Wait -PassThru
    $out = Get-Content 'out.txt' -Raw
    $err = Get-Content 'err.txt' -Raw
    if($proc.ExitCode -eq 0){
        Write-Host "Success:\n$out"
        Remove-Item 'out.txt','err.txt' -ErrorAction SilentlyContinue
        exit 0
    } else {
        Write-Host "Exit $($proc.ExitCode), stdout:\n$out\n stderr:\n$err"
        Start-Sleep -Seconds 3
    }
}
Write-Host "Timed out after $max attempts"
exit 1
