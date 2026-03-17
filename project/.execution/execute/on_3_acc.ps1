# Execution of Refresh of Data in the Database.
# -ip_cd_environment       | (mandatory) | Code for Environment "O" (Development), "T" (Test) , "A" (Acceptance) or "P" (Production)
# -ip_skip_processing_data | (optional)  | Providing this parameter will cause the processing to skip the data processing
."$PSScriptRoot\execute.ps1"; execute -ip_cd_environment "A" #-ip_skip_processing_data