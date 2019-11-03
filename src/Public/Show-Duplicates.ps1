function Show-Duplicates (
    [parameter(Mandatory)][string] $ProcessedFileMetaDataPath) {

    $processedFileInfo = Get-Content -Raw $ProcessedFileMetaDataPath | ConvertFrom-Json
    if ($IsWindows) {
        $processedFileInfo.Duplicates | Out-GridView -Title "Duplicates"
    }
    else {
        Format-Table
    }
 }