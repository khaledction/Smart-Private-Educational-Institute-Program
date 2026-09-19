$ErrorActionPreference = 'Stop'

$Repo = 'E:\projects\Smart-Private-Educational-Institute-Program'
$Desk = Join-Path $env:USERPROFILE 'Desktop\Smart-Private-Educational-Institute-Program'
$Zip = Join-Path $Repo 'x16a.zip'
$Extract = Join-Path $Repo 'x16x'

if (-not (Test-Path $Zip)) {
  throw "ZIP not found: $Zip"
}

if (-not (Test-Path $Desk)) {
  New-Item -ItemType Directory -Path $Desk -Force | Out-Null
}

foreach ($name in @('x15x','x16x')) {
  $p = Join-Path $Repo $name
  if (Test-Path $p) { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }
  $d = Join-Path $Desk $name
  if (Test-Path $d) { Remove-Item -LiteralPath $d -Recurse -Force -ErrorAction SilentlyContinue }
}

Expand-Archive -LiteralPath $Zip -DestinationPath $Extract -Force
Copy-Item -Path (Join-Path $Extract 'lib') -Destination $Repo -Recurse -Force
Copy-Item -Path (Join-Path $Extract 'pubspec.yaml') -Destination $Repo -Force
Copy-Item -Path (Join-Path $Extract 'test') -Destination $Repo -Recurse -Force -ErrorAction SilentlyContinue

Copy-Item -Path (Join-Path $Repo 'lib') -Destination $Desk -Recurse -Force
Copy-Item -Path (Join-Path $Repo 'pubspec.yaml') -Destination $Desk -Force
Copy-Item -Path (Join-Path $Repo 'test') -Destination $Desk -Recurse -Force -ErrorAction SilentlyContinue

(Get-ChildItem -Path (Join-Path $Repo 'lib') -Recurse -Filter *.dart | Measure-Object).Count
Select-String -Path (Join-Path $Repo 'lib\main.dart') -Pattern 'v3.8-fix16'
Select-String -Path (Join-Path $Repo 'pubspec.yaml') -Pattern '3.8.10\+16'
Select-String -Path (Join-Path $Repo 'lib\data\local_registration_db.dart') -Pattern '_migrateToV4|group_id|target_group_id'
Select-String -Path (Join-Path $Repo 'lib\data\registration_store.dart') -Pattern 'removeStudentFromCourse|_fillVacanciesFromWaiting|_notifyStudentOnWhatsApp|w.group_id IS NULL'

if (Test-Path (Join-Path $Repo '.git')) {
  git -C $Repo add lib pubspec.yaml test
  git -C $Repo add -u
  $pending = git -C $Repo status --porcelain
  if ($pending) {
    git -C $Repo commit -m "fix16: repair waitlist migration and whatsapp diagnostics"
    git -C $Repo push
  }
}
