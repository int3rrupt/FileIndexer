function Get-FileMetaData {
    param (
        [parameter(Mandatory)][string] $FilePath,
        [parameter(Mandatory)][MetaDataProperty[]] $Properties
    )

    $fileMetaData = New-Object -TypeName psobject
    $shell = New-Object -COMObject Shell.Application
    $folder = Split-Path $FilePath
    $file = Split-Path $FilePath -Leaf
    $shellfolder = $shell.Namespace($folder)
    $shellfile = $shellfolder.ParseName($file)
        
    # $metaDataPropertyNames = Get-MetaDataPropertyNames
    foreach ($metaDataPropertyName in $Properties) {
        $metaDataPropertyId = $metaDataPropertyName.Value__
        # $propertyName = ($metaDataPropertyName.Trim())
        # $propertyName = (Get-Culture).TextInfo.ToTitleCase($propertyName).Replace(' ', '')
        $propertyValue = $shellfolder.GetDetailsOf($shellfile, $metaDataPropertyId) 
        if ($metaDataPropertyName -eq [MetaDataProperty]::Attributes) {
            switch ($propertyValue) {
                'A' {
                    $propertyValue = 'Archive (A)'
                }
                'D' {
                    $propertyValue = 'Directory (D)'
                }
                'H' {
                    $propertyValue = 'Hidden (H)'
                }
                'L' {
                    $propertyValue = 'Symlink (L)'
                }
                'R' {
                    $propertyValue = 'Read-Only (R)'
                }
                'S' {
                    $propertyValue = 'System (S)'
                }
            }
        }
        if ($propertyValue -and ($propertyValue -ne '')) {
            $fileMetaData | Add-Member -MemberType NoteProperty -Name $metaDataPropertyName -Value $propertyValue
        }
    }

    return $fileMetaData
}