$DscScript = '.\ConfigureHyperVServer.ps1'
$ArchivePath = '.\ConfigureHyperVServer.zip'

Write-Host -ForegroundColor Green "Publishing DSC configuration archive $ArchivePath"
Publish-AzVMDscConfiguration $DscScript -OutputArchivePath $ArchivePath -Force
