$ErrorActionPreference = 'Stop'

$project = 'E:\projects\Smart-Private-Educational-Institute-Program'
$desktopMirror = Join-Path $HOME 'Desktop\Smart-Private-Educational-Institute-Program'
$downloads = Join-Path $HOME 'Downloads'
$temp = Join-Path $env:TEMP 'maehdi_sync_v36'

$zipCandidates = @(
  'maehdi_sync_all_v36_finance.zip',
  'maehdi_sync_all_v36b_finance.zip',
  'maehdi_sync_all_v36c_hotfix.zip'
)

$fullZip = $null
foreach ($name in $zipCandidates) {
  $candidate = Join-Path $downloads $name
  if (Test-Path $candidate) {
    $fullZip = $candidate
    break
  }
}

Write-Host '== Check files ==' -ForegroundColor Cyan
if (-not $fullZip) { throw 'Project zip not found in Downloads.' }
if (-not (Test-Path $project)) { throw 'Project folder not found.' }

if (Test-Path $temp) {
  Remove-Item -LiteralPath $temp -Recurse -Force
}
New-Item -ItemType Directory -Path $temp | Out-Null

Write-Host '== Extract zip ==' -ForegroundColor Cyan
Expand-Archive -LiteralPath $fullZip -DestinationPath $temp -Force

Write-Host '== Sync local project ==' -ForegroundColor Cyan
Copy-Item -Path (Join-Path $temp '*') -Destination $project -Recurse -Force

if (Test-Path $desktopMirror) {
  Write-Host '== Sync desktop mirror ==' -ForegroundColor Cyan
  Copy-Item -Path (Join-Path $temp '*') -Destination $desktopMirror -Recurse -Force
} else {
  Write-Host 'Desktop mirror not found. Skipped.' -ForegroundColor Yellow
}

Write-Host '== Quick verify ==' -ForegroundColor Cyan
$dartCount = (Get-ChildItem (Join-Path $project 'flutter_app\lib') -Recurse -Filter *.dart).Count
Write-Host ("Dart files in flutter_app/lib = {0}" -f $dartCount)
Select-String -Path (Join-Path $project 'flutter_app\lib\main.dart') -Pattern 'v3.6' | Out-Host
Select-String -Path (Join-Path $project 'flutter_app\lib\screens\accounting.dart') -Pattern 'three|Audit|policy|v3.6|Audit Log|قفل الدورة المالية|دفتر ثلاثي' | Out-Host

Write-Host '== Run app ==' -ForegroundColor Cyan
Write-Host ("cd {0}\flutter_app" -f $project)
Write-Host 'flutter run -d windows'

Write-Host '== Git sync ==' -ForegroundColor Cyan
Push-Location $project
try {
  if (Test-Path '.git') {
    git status
    git add .
    git commit -m "v3.6 adopt all financial policies"
    if ($LASTEXITCODE -eq 0) {
      git push
    } else {
      Write-Host 'No new commit was created. Maybe there are no changes yet.' -ForegroundColor Yellow
    }
  } else {
    Write-Host 'This folder is not a git repo. Skipped git sync.' -ForegroundColor Yellow
  }
} finally {
  Pop-Location
}

Write-Host '== Done ==' -ForegroundColor Green
