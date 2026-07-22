$config = @{
    DisableSMBv1     = $true
    EnableFirewall   = $true
    EnableBitLocker  = $false
    EnableDefender   = $true
    AuditPolicyLevel = "Advanced"
    AppLockerMode    = "AllowList"
}

function Disable-LegacyProtocols {
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -Value 0 -PropertyType DWord -Force
    Write-Host "SMBv1 disabled"
}

function Set-SecurityPolicy {
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LMCompatibilityLevel" -Value 5 -PropertyType DWord -Force
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymous" -Value 1 -PropertyType DWord -Force
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymousSAM" -Value 1 -PropertyType DWord -Force
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictRemoteSAM" -Value "O:BAG:BAD:(A;;RC;;;BA)" -PropertyType String -Force
    Write-Host "Security policy applied"
}

function Set-AuditPolicy {
    auditpol /set /subcategory:"Logon" /success:enable /failure:enable
    auditpol /set /subcategory:"Process Creation" /success:enable
    auditpol /set /subcategory:"Directory Service Changes" /success:enable /failure:enable
    auditpol /set /subcategory:"Account Management" /success:enable /failure:enable
    Write-Host "Audit policy configured"
}

function Set-WindowsDefender {
    Set-MpPreference -DisableRealtimeMonitoring $false
    Set-MpPreference -PUAProtection Enabled
    Set-MpPreference -CloudBlockLevel High
    Set-MpPreference -CloudTimeout 50
    Set-MpPreference -SubmitSamplesConsent Always
    Write-Host "Windows Defender configured"
}

Disable-LegacyProtocols
Set-SecurityPolicy
Set-AuditPolicy

if ($config.EnableDefender) {
    Set-WindowsDefender
}

Write-Host "Windows hardening baseline applied"
