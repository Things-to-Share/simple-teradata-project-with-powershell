function deploy { param(
    [Parameter(Mandatory = $true)][ValidateSet("O", "T", "A", "P")] 
    [string]$ip_cd_environment,
    [switch]$ip_publish,
    [switch]$ip_excl_drop_objects,
    [switch]$ip_excl_tables,
    [switch]$ip_excl_views,
    [switch]$ip_excl_procedrues,
    [switch]$ip_is_override
  )

  # Set floderpath for Root and Script then load modules
  $global:fp_root = $PSScriptRoot.Replace("\.framework\deployment\deploy", ""); . "$global:fp_root\.framework\scripts\load_modules.ps1" -Raw;

  # Build and Public options (providing the switches will "active" them)
  $param = @{
    ip_cd_environment    = $ip_cd_environment    # (mandatory) | Code for Environment "O" (Development), "T" (Test) , "A" (Acceptance) or "P" (Production)
    ip_publish           = $ip_publish           # (switch) | If provided -> SQL statement form BUILD-file will be executed one by one
    ip_excl_drop_objects = $ip_excl_drop_objects # (switch) | If provided -> Object that are not defined will be dropped
    ip_excl_tables       = $ip_excl_tables       # (switch) | If provided -> Table change are ignored
    ip_excl_views        = $ip_excl_views        # (switch) | If provided -> View change are ignored
    ip_excl_procedrues   = $ip_excl_procedrues   # (switch) | If provided -> Procedure change are ignored
    ip_is_override       = $ip_is_override       # (switch) | If provided -> All Views and Procedures are replaced. regardless of up-to-date status
  }
  ps_build_and_publish @param
}
m