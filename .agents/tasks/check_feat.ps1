$log = "C:\Users\USER\Documents\CampusCoreNew\.agents\tasks\web_app_analyze2.log"
$featFiles = @(
  "profile_screen.dart","auth_provider.dart","study_groups_screen.dart",
  "api_constants.dart","app_router.dart","app_shell.dart",
  "activity_storage.dart","home_screen.dart","course_detail_screen.dart",
  "question_detail_screen.dart"
)
$out = @()
foreach ($f in $featFiles) {
  $hits = @(Select-String -Path $log -Pattern ([regex]::Escape($f)))
  $out += "$f : $($hits.Count)"
  foreach ($h in $hits) { $out += "   " + $h.Line.Trim() }
}
# Summary counts
$allLines = @(Get-Content $log)
$errLines = @($allLines | Where-Object { $_ -match "  error - " })
$warnLines = @($allLines | Where-Object { $_ -match "  warning - " })
$infoLines = @($allLines | Where-Object { $_ -match "  info - " })
$dcLines = @($allLines | Where-Object { $_ -match "dataconnect_generated" })
$nonDcIssues = @($allLines | Where-Object { $_ -match "  (error|warning|info) - " -and $_ -notmatch "dataconnect_generated" })
$out += ""
$out += "TOTAL ISSUE LINES: $($allLines.Count)"
$out += "ERRORS: $($errLines.Count)"
$out += "WARNINGS: $($warnLines.Count)"
$out += "INFOS: $($infoLines.Count)"
$out += "DATACONNECT-RELATED: $($dcLines.Count)"
$out += "NON-DATACONNECT ISSUES: $($nonDcIssues.Count)"
Set-Content -Path "C:\Users\USER\Documents\CampusCoreNew\.agents\tasks\feat_hits.txt" -Value $out -Encoding UTF8
Write-Output "DONE"
