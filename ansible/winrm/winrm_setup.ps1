########################################################################
#
# IMPORT CLIENT CERTIFICATE
#
########################################################################
# path to the genereated client cert
$pubKeyFilePath = '..\ansible_server\cert.pem'
# Import the public key into Trusted Root Certification Authorities and Trusted People
$null = Import-Certificate -FilePath $pubKeyFilePath -CertStoreLocation 'Cert:\LocalMachine\Root'
$null = Import-Certificate -FilePath $pubKeyFilePath -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople'
########################################################################
#
# ENABLE WINRM
#
########################################################################
# Start the WinRM service and enable automatic boot
Set-Service -Name "WinRM" -StartupType Automatic
Start-Service -Name "WinRM"
# Ensure PowerShell remoting is enabled
if (-not (Get-PSSessionConfiguration) -or (-not (Get-ChildItem WSMan:\localhost\Listener))) {
    Enable-PSRemoting -SkipNetworkProfileCheck -Force
}
########################################################################
#
# IMPORT WINDOWS CERTIFICATE
#
########################################################################
$params = @{
    FilePath = '..\ansible_server\cert.pfx'
    CertStoreLocation = 'Cert:\LocalMachine\My'
}
Import-PfxCertificate @params
########################################################################
#
# CREATE ANSBILE USER
#
########################################################################
# Load Web Assembly
Add-Type -AssemblyName 'System.Web'
# Min/Max Password Characters
$minChar = 10
$maxChar = 16
$len = Get-Random -Minimum $minChar -Maximum $maxChar
$symbols = 6
$password = 'ansiblepassword'#[System.Web.Security.Membership]::GeneratePassword($len, $symbols)
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableFirstLogonAnimation -Value 0 -Force
# Create Ansible user
$ansibleRunnerUsername = 'ansiblerunner'
$ansibleRunnerPassword = (ConvertTo-SecureString -String $password -AsPlainText -Force)
if (-not (Get-LocalUser -Name $ansibleRunnerUsername -ErrorAction Ignore)) {
    $newUserParams = @{
        Name                 = $ansibleRunnerUsername
        AccountNeverExpires  = $true
        PasswordNeverExpires = $true
        Password             = $ansibleRunnerPassword
    }
    $null = New-LocalUser @newUserParams
}
# Add the local user to the administrator's group.
Get-LocalUser -Name $ansibleRunnerUsername | Add-LocalGroupMember -Group 'Administrators'
# Allow WinRM with User Account Control
$newItemParams = @{
    Path         = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    Name         = 'LocalAccountTokenFilterPolicy'
    Value        = 1
    PropertyType = 'DWORD'
    Force        = $true
}
$null = New-ItemProperty @newItemParams
# Map generated certificates to the ansible runner
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ansibleRunnerUsername, $ansibleRunnerPassword
# Find the cert thumbprint for the client certificate created on the Ansible host
$ansibleCert = Get-ChildItem -Path 'Cert:\LocalMachine\Root' | Where-Object {$_.Subject -eq 'CN=ansiblerunner'}
# Get-ChildItem wsman:\localhost\Listener\ | Where-Object -Property Keys -like 'Transport=HTTP*' | Remove-Item -Recurse
Get-ChildItem -Path WSMan:\localhost\ClientCertificate
Remove-Item -Recurse -Path WSMan:\localhost\ClientCertificate\*
$params = @{
	Path = 'WSMan:\localhost\ClientCertificate'
	Subject = "$ansibleRunnerUsername@localhost"
	URI = '*'
	Issuer = $ansibleCert.Thumbprint
    Credential = $credential
	Force = $true
}
New-Item @params
########################################################################
#
# CREATE WINRM LISTENER
#
########################################################################
$cert_host = 'PC-NAME'
# Get the server certificate generated previously
$serverCert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.DnsNameList -contains $cert_host}
# Find all HTTPS listners
$httpsListeners = Get-ChildItem -Path WSMan:\localhost\Listener\ | where-object { $_.Keys -match 'Transport=HTTPS' }
# Remove listener
if ($httpsListeners){
    $selectorset = @{
        Address = "*"
        Transport = "HTTPS"
    }
    Remove-WSManInstance -ResourceURI 'winrm/config/Listener' -SelectorSet $selectorset
}
# Create a new listener
$newWsmanParams = @{
    ResourceUri = 'winrm/config/Listener'
    SelectorSet = @{ Transport = "HTTPS"; Address = "*" }
    ValueSet    = @{ Hostname = $cert_host; CertificateThumbprint = $serverCert.Thumbprint }
    # UseSSL = $true
}
$null = New-WSManInstance @newWsmanParams
# set to certificate authentication
winrm set WinRM/Config/Client/Auth '@{Basic="false";Digest="false";Kerberos="false";Negotiate="true";Certificate="true";CredSSP="false"}'
# enable winrm service certificate auth
Set-Item -Path WSMan:\localhost\Service\Auth\Certificate -Value $true
########################################################################
#
# UPDATE FIREWALL
#
########################################################################
# Ensure WinRM port 5986 is open
$ruleDisplayName = 'Windows Remote Management (HTTPS-In)'
if (-not (Get-NetFirewallRule -DisplayName $ruleDisplayName -ErrorAction Ignore)) {
     $newRuleParams = @{
         DisplayName   = $ruleDisplayName
         Direction     = 'Inbound'
         LocalPort     = 5986
         RemoteAddress = 'Any'
         Protocol      = 'TCP'
         Action        = 'Allow'
         Enabled       = 'True'
         Group         = 'Windows Remote Management'
     }
     $null = New-NetFirewallRule @newRuleParams
 }