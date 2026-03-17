function execution { param(
    [Parameter(Mandatory = $true)] [ValidateSet("O", "T", "A", "P")]
    [string]$ip_cd_environment,
    [switch]$ip_skip_processing_data
  )

  # Set floderpath for Root and Script then load modules (the root need ajustment, for this files is already in de ".scripts"-folder)
  $global:fp_root = $PSScriptRoot.Replace("\project\.execution\", ""); . "$global:fp_root\project\.scripts\.load_modules.ps1" -Raw;

  # Update Data in the Database
  if ($true -eq $ip_skip_processing_data.IsPresent) { 
    ps_process_data -ip_cd_environment $ip_cd_environment -ip_skip_processing_data
  } else { ps_process_data -ip_cd_environment $ip_cd_environment }

  # Add Additional Script Executions
  ps_example -ip_is_debugging 1

}