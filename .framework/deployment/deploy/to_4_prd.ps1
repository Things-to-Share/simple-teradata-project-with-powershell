# Build and Public options (providing the switches will "active" them)
# -ip_cd_environment  | (mandatory) | Code for Environment "O" (Development), "T" (Test) , "A" (Acceptance) or "P" (Production)
# -ip_publish         | (switch)    | If provided -> SQL statement form BUILD-file will be executed one by one
# -ip_excl_tables     | (switch)    | If provided -> Table change are ignored
# -ip_excl_views      | (switch)    | If provided -> Table change are ignored
# -ip_excl_procedures | (switch)    | If provided -> Procedure change are ignored
# -ip_is_override     | (Optional)  | If provided -> All Views and Procedures are replaced. regardless of up-to-date status
."$PSScriptRoot\deploy.ps1"; deploy -ip_cd_environment "P" -ip_publish