$DscScript = '.\ConfigureJumpServer.ps1'
$ArchivePath = '.\ConfigureJumpServer.zip'

Write-Host -ForegroundColor Green "Publishing DSC configuration archive $ArchivePath"
Publish-AzVMDscConfiguration $DscScript -OutputArchivePath $ArchivePath -Force
