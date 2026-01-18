@{
    RootModule        = 'psmusictagger.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'c50ef283-8557-4fb1-8bf8-7b3439dfc5ce'
    Author            = 'David Alderman'
    CompanyName       = ''
    Description       = 'PowerShell module for music tagging with TagLib#'
    PowerShellVersion = '5.1'
    
    FunctionsToExport = @(
        'Get-Id3Text'
        'Get-Id3Txxx'
        'Get-Id3Wxxx'
        'Get-XiphField'
        'Get-AppleFreeForm'
        'Resolve-AudioPath'
        'Read-TrackMetadataSingle'
        'Get-TrackMetadata'
        'Set-TrackMetadata'
        'Set-Id3CustomText'
        'Remove-Id3CustomText'
        'Remove-CustomTag'
        'Get-TagWritablePropertiesTemplate'
        'Get-TrackArtwork'
        'Export-TrackArtwork'
    )
    
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    
    PrivateData       = @{
        PSData = @{
            Tags       = @('music', 'tagging', 'metadata', 'taglib')
            ProjectUri = ''
        }
    }
}