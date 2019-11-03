function Start-FileIndexer (
    [parameter(Mandatory)][string[]] $Directories,
    [parameter(Mandatory)][string] $ProcessedFileMetaDataPath) {

    # if (!$ProcessedFileMetaDataPath) {
    #     $ProcessedFileMetaDataPath = Join-Path $env:TEMP
    # }

    # Start time
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Get all files in each directory
    foreach ($directory in $Directories) {
        $availableFileTypes = Get-AllFileTypes -Directory $directory
    }
    # Prompt user for file types to run checks against
    $fileTypePrompt = "Choose File Types (Comma Separated)"
    # if ($IsWindows) {
    #     $fileTypes = Out-GridView -InputObject $availableFileTypes -Title $fileTypePrompt -OutputMode Multiple
    # }
    # if ($IsMacOS) {
    if ($availableFileTypes.Count -gt 1) {
        Write-Host "Option | Type" -ForegroundColor Green
        Write-Host "-------------" -ForegroundColor Green
        # Display file types to user
        for ($i = 0; $i -lt $availableFileTypes.Count; $i++) {
            Write-Host "   $($i.ToString("00")) " -ForegroundColor DarkGreen -NoNewline
            Write-Host " | " -ForegroundColor Green -NoNewline
            Write-Host "$($availableFileTypes[$i].Extension)" -ForegroundColor DarkGreen
        }
        # User select file types
        $selectedFileTypeIndexes = Read-Host -Prompt $fileTypePrompt
        $selectedFileTypeIndexes = $selectedFileTypeIndexes.Split(',')
        $fileTypes = @()
        foreach ($fileTypeIndex in $selectedFileTypeIndexes) {
            $fileTypes += $availableFileTypes[$fileTypeIndex]
        }
    }
    else {
        $fileTypes = $availableFileTypes
    }
        
    # }

    # Display selected file types to user
    Write-Host "File types to process: $($fileTypes.Extension -join ", ")"

    # Check whether metadata file exists
    if (Test-Path $ProcessedFileMetaDataPath) {
        # Read metadata file
        $processedFileInfoContents = Get-Content -Raw $ProcessedFileMetaDataPath
        if ($processedFileInfoContents) {
            $processedFileInfo = $processedFileInfoContents | ConvertFrom-Json
        }
    }
    else {
        $processedFileInfo = New-Object -TypeName psobject
        Add-Member -InputObject $processedFileInfo -MemberType NoteProperty -Name "Files" -Value (New-Object -TypeName psobject)
        Add-Member -InputObject $processedFileInfo -MemberType NoteProperty -Name "Hashes" -Value (New-Object -TypeName psobject)
        Add-Member -InputObject $processedFileInfo -MemberType NoteProperty -Name "Duplicates" -Value (New-Object -TypeName psobject)
        #     $files = @()
        # $processedFileInfo = @{
        #     Files = @{};
        #     Hashes = @{};
        #     Duplicates = @()
        # }

    }

    # Get subset of files with selected extensions
    $files = $files | Where-Object { $fileTypes.Extension.Contains($_.Extension) }
    # Check all files
    # foreach ($file in $files) {
    for ($i = 0; $i -lt $files.Count; $i++) {
        $file = $files[$i]
        $percentComplete = $i / $files.Count
        $percentComplete = $percentComplete.ToString("000.0000")
        $activity = "Processing $($file.Name)"
        $status = "$percentComplete% Complete"
        # Write-Progress -Activity "Duplicate File Search in Progress" -Status $status -PercentComplete $percentComplete
        Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete
        # If file not already in processed
        if (!$processedFileInfo.Files.($file.FullName)) {
            # Write-Host "Processing $($file.Name)" -ForegroundColor Green
            # Get metadata for file
            # Write-Host "Getting MetaData..."
            $activity = "Processing $($file.Name) - Getting MetaData"
            Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete
            $metaData = Get-MetaData -FileName $file.FullName
            # Get file hash
            # Write-Host "Getting Hash..."
            $activity = "Processing $($file.Name) - Calculating Hash"
            Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete
            $fileHash = Get-FileHash $file.FullName
            if ($fileHash) {
                # Add file hash to metadata object
                Add-Member -InputObject $metaData -MemberType NoteProperty -Name "FileHash" -Value $fileHash
                # Check for duplicate
                $duplicateFileName = $processedFileInfo.Hashes.($fileHash.Hash)
                if ($duplicateFileName) {
                    # Add to duplicates
                    Write-Host "Duplicate found!"
                    Write-Host $file.FullName
                    Write-Host $duplicateFileName
                    Add-Member -InputObject $processedFileInfo.Duplicates -MemberType NoteProperty -Name $processedFileInfo.Hashes.($fileHash.Hash) -Value $file.FullName
                    # $processedFileInfo.Duplicates += @($processedFileInfo.Hashes.($fileHash.Hash), $file.FullName)
                }
                # When file is not duplicate
                else {
                    # Add to hashes
                    # Write-Host "No duplicate found"
                    # $processedFileInfo.Hashes.Add($fileHash.Hash, $file.FullName)
                    Add-Member -InputObject $processedFileInfo.Hashes -MemberType NoteProperty -Name $fileHash.Hash -Value $file.FullName
                }
                # Add to files
                # $processedFileInfo.Files.Add($file.FullName, $metaData)
                Add-Member -InputObject $processedFileInfo.Files -MemberType NoteProperty -Name $file.FullName -Value $metaData
                # Save changes
                if ($ProcessedFileMetaDataPath) {
                    ConvertTo-Json -Depth 20 $processedFileInfo | Out-File -FilePath $ProcessedFileMetaDataPath
                }
            }
            else {
                Write-Error "Could not calculate file hash for $($file.Name)"
            }
        }
        else {
            $activity = "Processing $($file.Name) - Already Processed"
            Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete
            # Write-Host "Already Processed $($file.Name)" -ForegroundColor DarkGreen
        }
    }

    $stopwatch.Stop()
    Write-Host "Script Duration: $($stopwatch.Elapsed)"

    return $processedFileInfo
}