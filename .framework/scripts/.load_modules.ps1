# -----------------------------------------------------------------------------
# Read and execute the script content
# -----------------------------------------------------------------------------
. "$global:fp_root\project\.configuration\.environments.ps1" -Raw;
. "$global:fp_root\.framework\.scripts\modules\classes.ps1" -Raw;
. "$global:fp_root\.framework\.scripts\modules\functions.ps1" -Raw; 
. "$global:fp_root\.framework\.scripts\modules\build_and_publish.ps1" -Raw;
. "$global:fp_root\.framework\.scripts\modules\process_data.ps1" -Raw;