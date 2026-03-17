function ps_example { param(
    [Parameter(Mandatory = $true)] [System.Boolean] $ip_is_debugging
  )

  if ($true -eq $ip_is_debugging) {
    Write-Host "This is a Example, the parameter ip_is_debugging is set to $($ip_is_debugging)" -ForegroundColor Green
  } 
  else {
    Write-Host "This is a Example, the parameter ip_is_debugging is set to $($ip_is_debugging)" -ForegroundColor DarkYellow
  }

}