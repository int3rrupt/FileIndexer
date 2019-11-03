function Show-VideoInfo (
    [parameter(Mandatory)][string] $ProcessedFileMetaDataPath) {

    $processedFileInfo = Get-Content -Raw $ProcessedFileMetaDataPath | ConvertFrom-Json
    if ($IsWindows) {
        $processedFileInfo.Files.psobject.Properties.Value | Select-Object -Property Name, Length, FrameWidth, FrameHeight, FrameRate, DataRate, BitRate, Size | Out-GridView -Title "Videos"
    }
    else {
        $processedFileInfo.Files.psobject.Properties.Value | Format-Table -
    }
}