$ErrorActionPreference = 'Stop'

# ==============================
# Maehdi v3.6 Sync Script
# ==============================
# 1) ضع الملف التالي في Downloads:
#    - maehdi_sync_all_v36_finance.zip
# 2) حمّل هذا السكربت نفسه إلى Downloads ثم شغّله من PowerShell
# 3) لا تلصق مخرجات التشغيل داخل PowerShell نفسها 🙂

$project = 'E:\projects\Smart-Private-Educational-Institute-Program'
$desktopMirror = Join-Path $HOME 'Desktop\Smart-Private-Educational-Institute-Program'
$downloads = Join-Path $HOME 'Downloads'
$fullZip = Join-Path $downloads 'maehdi_sync_all_v36_finance.zip'
$temp = Join-Path $env:TEMP 'maehdi_sync_v36'

Write-Host "== التحقق من الملفات ==" -ForegroundColor Cyan
if (-not (Test-Path $fullZip)) { throw "لم أجد: $fullZip" }
if (-not (Test-Path $project)) { throw "لم أجد مجلد المشروع: $project" }

if (Test-Path $temp) {
  Remove-Item -Recurse -Force $temp
}
New-Item -ItemType Directory -Path $temp | Out-Null

Write-Host "== فك الحزمة الشاملة ==" -ForegroundColor Cyan
Expand-Archive -Path $fullZip -DestinationPath $temp -Force

Write-Host "== مزامنة المشروع المحلي ==" -ForegroundColor Cyan
Copy-Item -Path (Join-Path $temp '*') -Destination $project -Recurse -Force

if (Test-Path $desktopMirror) {
  Write-Host "== مزامنة نسخة سطح المكتب ==" -ForegroundColor Cyan
  Copy-Item -Path (Join-Path $temp '*') -Destination $desktopMirror -Recurse -Force
} else {
  Write-Host "مجلد نسخة سطح المكتب غير موجود، تخطيه: $desktopMirror" -ForegroundColor Yellow
}

Write-Host "== تحقق سريع ==" -ForegroundColor Cyan
$dartCount = (Get-ChildItem (Join-Path $project 'flutter_app\lib') -Recurse -Filter *.dart).Count
Write-Host "عدد ملفات Dart داخل flutter_app/lib = $dartCount"
Select-String -Path (Join-Path $project 'flutter_app\lib\main.dart') -Pattern 'v3.6' | Out-Host
Select-String -Path (Join-Path $project 'flutter_app\lib\screens\accounting.dart') -Pattern 'دفتر ثلاثي|Audit Log|قفل الدورة المالية' | Out-Host
Select-String -Path (Join-Path $project 'الحلول_المالية_المعتمدة_معهدي_v3_6.md') -Pattern 'الاستحقاق بالجلسة المنفذة|دفتر ثلاثي|قفل الدورة المالية' | Out-Host

Write-Host "== اختبار تشغيل اختياري ==" -ForegroundColor Cyan
Write-Host "cd $project\flutter_app"
Write-Host "flutter run -d windows"

Write-Host "== مزامنة Git ==" -ForegroundColor Cyan
Push-Location $project
try {
  if (Test-Path '.git') {
    git status
    git add .
    git commit -m "v3.6 adopt all financial policies"
    git push
  } else {
    Write-Host 'هذا المجلد ليس مستودع Git مهيأ محليًا. نفذ git init / اربطه بالمستودع أولًا إن لزم.' -ForegroundColor Yellow
  }
} finally {
  Pop-Location
}

Write-Host "== تم ==" -ForegroundColor Green
