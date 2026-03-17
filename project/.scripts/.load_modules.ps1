# -----------------------------------------------------------------------------
# Read and execute the script content
# -----------------------------------------------------------------------------
. "$global:fp_root\project\.configuration\.environments.ps1" -Raw;
. "$global:fp_root\.framework\.scripts\.load_modules.ps1" -Raw;

# Add your project PowerShell scripts here
. "$global:fp_root\project\.scripts\example.ps1" -Raw;
#. "$global:fp_root\project\.scripts\add-more-script.ps1" -Raw;