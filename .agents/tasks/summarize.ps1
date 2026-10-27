function Summarize($log, $label) {
  $all = @(Get-Content $log)
  $errs = @($all | Where-Object { $_ -match "  error -" })
  $warns = @($all | Where-Object { $_ -match "  warning -" })
  $infos = @($all | Where-Object { $_ -match "  info -" })
  $dc = @($all | Where-Object { $_ -match "dataconnect_generated" })
  Write-Output ("$label : LINES=" + $all.Count + " ERRORS=" + $errs.Count + " WARNINGS=" + $warns.Count + " INFOS=" + $infos.Count + " DATACONNECT=" + $dc.Count)
  # list unique files with non-dataconnect issues
  $nonDc = @($all | Where-Object { $_ -match "  (error|warning|info) -" -and $_ -notmatch "dataconnect_generated" })
  $files = @{}
  foreach ($l in $nonDc) {
    if ($l -match "- (lib\\[^ ]+)") { $files[$matches[1]] = 1 }
  }
  Write-Output ("  non-dataconnect issue files: " + ($files.Keys -join ", "))
}
Summarize "C:\Users\USER\Documents\CampusCoreNew\.agents\tasks\web_app_analyze3.log" "web_app(post-exclude)"
Summarize "C:\Users\USER\Documents\CampusCoreNew\.agents\tasks\admin_analyze2.log" "admin(post-exclude)"
