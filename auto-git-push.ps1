# auto-git-push.ps1
# Automatically detects network and pushes to GitHub with or without proxy

Write-Host "Attempting to push to GitHub..." -ForegroundColor Cyan

# Try direct connection first (without proxy)
Write-Host "Trying direct connection..." -ForegroundColor Yellow
git -c http.sslVerify=false push 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "Push successful (direct connection)!" -ForegroundColor Green
    exit 0
}

# If direct connection failed, try with proxy
Write-Host "Direct connection failed. Trying with corporate proxy..." -ForegroundColor Yellow
git -c http.proxy=http://gateway.schneider.zscaler.net:443 -c http.sslVerify=false push

if ($LASTEXITCODE -eq 0) {
    Write-Host "Push successful (via proxy)!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Push failed. Please check your connection or credentials." -ForegroundColor Red
    exit 1
}
