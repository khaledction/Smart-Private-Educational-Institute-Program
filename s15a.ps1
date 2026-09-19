$ErrorActionPreference = 'Stop'

$Repo = 'E:\projects\Smart-Private-Educational-Institute-Program'
$Desk = Join-Path $env:USERPROFILE 'Desktop\Smart-Private-Educational-Institute-Program'
$Zip = Join-Path $Repo 'x15a.zip'
$Extract = Join-Path $Repo 'x15x'

if (-not (Test-Path $Zip)) {
  throw "ZIP not found: $Zip"
}

if (-not (Test-Path $Desk)) {
  New-Item -ItemType Directory -Path $Desk -Force | Out-Null
}

$cleanupRepo = @(
  'x10a.zip','x11a.zip','x12a.zip','x13a.zip','x14a.zip',
  'x10x','x11x','x12x','x13x','x14x','x15x',
  'fx10x',
  'maehdi_flat_v383_fix9_teachers_db_clean.zip',
  'maehdi_flat_v384_fix10_overflow_clean.zip',
  'maehdi_flat_v385_fix11_teachers_white_screen.zip',
  'maehdi_flat_v386_fix12_teachers_white_page_real_fix.zip',
  'maehdi_flat_v387_fix13_registration_buttons_amount.zip',
  'maehdi_flat_v388_fix14_course_states_filters.zip'
)

$cleanupDesk = @('x10a.zip','x11a.zip','x12a.zip','x13a.zip','x14a.zip','x15x','x10x','x11x','x12x','x13x','x14x','fx10x')

foreach ($name in $cleanupRepo) {
  $p = Join-Path $Repo $name
  if (Test-Path $p) { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }
}
foreach ($name in $cleanupDesk) {
  $p = Join-Path $Desk $name
  if (Test-Path $p) { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }
}

Expand-Archive -LiteralPath $Zip -DestinationPath $Extract -Force
Copy-Item -Path (Join-Path $Extract 'lib') -Destination $Repo -Recurse -Force
Copy-Item -Path (Join-Path $Extract 'pubspec.yaml') -Destination $Repo -Force
Copy-Item -Path (Join-Path $Extract 'test') -Destination $Repo -Recurse -Force -ErrorAction SilentlyContinue

Copy-Item -Path (Join-Path $Repo 'lib') -Destination $Desk -Recurse -Force
Copy-Item -Path (Join-Path $Repo 'pubspec.yaml') -Destination $Desk -Force
Copy-Item -Path (Join-Path $Repo 'test') -Destination $Desk -Recurse -Force -ErrorAction SilentlyContinue

(Get-ChildItem -Path (Join-Path $Repo 'lib') -Recurse -Filter *.dart | Measure-Object).Count
Select-String -Path (Join-Path $Repo 'lib\main.dart'),(Join-Path $Repo 'lib\screens\courses.dart'),(Join-Path $Repo 'lib\screens\registration.dart'),(Join-Path $Repo 'lib\screens\students.dart'),(Join-Path $Repo 'lib\data\registration_store.dart') -Pattern 'v3.8-fix15|حذف اسم الطالب من هذه الدورة|حفظ وإتمام عملية التسجيل|مرشحات العرض|انتقال تلقائي عند التوفر|removeStudentFromCourse|_fillVacanciesFromWaiting|_notifyStudentOnWhatsApp|_statusDropdown'

if (Test-Path (Join-Path $Repo '.git')) {
  git -C $Repo add lib pubspec.yaml test
  git -C $Repo add -u
  git -C $Repo commit -m "fix15: waitlist auto-fill + whatsapp notice + withdrawal + course status cleanup"
  git -C $Repo push
}
