$log = "C:\Users\USER\Documents\CampusCoreNew\.agents\tasks\admin_analyze.log"
$featFiles = @("community_moderation_screen.dart","admin_router.dart","admin_shell.dart")
$out = @()
foreach ($f in $featFiles) {
  $hits = @(Select-String -Path $log -Pattern ([regex]::Escape($f)))
  $out += "$f : $($hits.Count)"
  foreach ($h in $hits) { $out += "   " + $h.Line.Trim() }
}
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
$out += ""
$out += "--- NON-DATACONNECT ISSUE FILES ---"
foreach ($l in $nonDcIssues) {
  if ($l -match "- (lib\\[^ ]+|[^ ]+\.dart)") { $out += $matches[1] }
}
Set-Content -Path "C:\Users\USER\Documents\CampusCoreNew\.agents\tasks\admin_hits.txt" -Value $out -Encoding UTF8
Write-Output "DONE"
