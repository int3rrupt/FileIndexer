function Get-AllFileTypes {
    param (
        [parameter(Mandatory)][string] $Directory
    )

    $files += Get-ChildItem -Path $Directory -Recurse -File
    $availableFileTypes = $files | Select-Object -Property Extension -Unique | Sort-Object -Property Extension
    return $availableFileTypes
}