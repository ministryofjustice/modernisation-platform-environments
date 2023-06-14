<powershell>
### Powershell script for OnPrem Gateway

## pre-req
# install choco
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
#install openssl
choco install openssl -y

# install powershell 7
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } –useMSI -EnablePSRemoting -Quiet"

# use Powershell 7 from this point
pwsh

# grab cert parameters from ssm
$Cert = $(aws ssm get-parameter --name MANUAL-OPDGW-HMPPS-Jitbit-Dev-Cert)
$Key = $(aws ssm get-parameter --name MANUAL-OPDGW-HMPPS-Jitbit-Dev-Key)
$Passphrase = ConvertTo-SecureString -String $(aws ssm get-parameter --name MANUAL-OPDGW-HMPPS-Jitbit-Dev-Passphrase) -Force -AsPlainText
$RecoveryKey = $(aws ssm get-parameter --name MANUAL-OPDGW-HMPPS-Jitbit-Dev-Recovery)

# store the above cert and key in files for use in the next step

# create pfx and import to local cert store
# (double check this works after the openssl install, I found it only worked after opening a new terminal window)
openssl pkcs12 -export -out C:\Scripts\new.pfx -inkey C:\Scripts\key.pem -in C:\Scripts\cert.pem -passin pass:$Passphrase -passout pass:$Passphrase
Import-PfxCertificate -FilePath C:\Scripts\new.pfx -CertStoreLocation Cert:\LocalMachine\My -Password $Passphrase
$CertificateThumbprint = $(Get-ChildItem  -Path Cert:\LocalMachine\MY).thumbprint

$ApplicationId = "dc03769e-5d0c-41bf-b5bf-a1f846743b31"
$Tenant = "c6874728-71e6-41fe-a9e1-2e8c36776ad8"
### auth with cert
Connect-DataGatewayServiceAccount -ApplicationId $ApplicationId -CertificateThumbprint $CertificateThumbprint -Tenant $Tenant

## install onprem gateway
Import-Module DataGateway
Install-Module -Name DataGateway -Force
Install-DataGateway -AcceptConditions

Add-DataGatewayCluster
   -RecoveryKey $RecoveryKey
   -GatewayName "delius-jitbit-onprem-gateway" # refer to env here

$GatewayClusterId = $(Get-DataGatewayCluster).Id

$GatewayUsers =  @{
   Admin =
      "9cb0d2d9-9fd8-4da2-b2f6-79d400bb3803", # seb.norris
      "aec74324-b11e-49fc-9239-e99f99e13a50" # kyle.hodgetts
   ;
   ConnectionCreatorWithReshare = 
      "c3d09d4f-e9ec-47e2-a738-b460a1f056f0" # peter.redfern
   ;
}

# change this to iterate through user hash
Add-DataGatewayClusterUser -GatewayClusterId $GatewayClusterId -PrincipalObjectId 9cb0d2d9-9fd8-4da2-b2f6-79d400bb3803 -Role Admin
</powershell>
