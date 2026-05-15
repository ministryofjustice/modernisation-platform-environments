# Manual domain join script for troubleshooting
# Run this via SSM Session Manager if automatic domain join fails

# Domain configuration
$domain = "laa-workspaces.local"
$username = "Admin"

# Get password from SSM Parameter Store
Write-Host "Retrieving Admin password from SSM..."
try {
    $adminPassword = Get-SSMParameterValue -Name "/laa-workspaces/development/ad-admin-password" -WithDecryption $true | Select-Object -ExpandProperty Value
    Write-Host "Password retrieved successfully"
} catch {
    Write-Host "ERROR: Failed to retrieve password from SSM: $_"
    Write-Host "You may need to get it from Secrets Manager or AWS Console"
    exit 1
}

# Create credential
$securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$domain\$username", $securePassword)

# Check DNS resolution
Write-Host "`nTesting DNS resolution for domain..."
try {
    $dnsResult = Resolve-DnsName -Name $domain -ErrorAction Stop
    Write-Host "DNS resolution successful: $($dnsResult.IPAddress)"
} catch {
    Write-Host "WARNING: DNS resolution failed: $_"
    Write-Host "The domain controllers may not be reachable"
}

# Check network connectivity to domain controllers
Write-Host "`nTesting connectivity to AD domain controllers..."
$dcIPs = @("10.200.1.245", "10.200.2.11")
foreach ($ip in $dcIPs) {
    $pingResult = Test-Connection -ComputerName $ip -Count 2 -Quiet
    if ($pingResult) {
        Write-Host "✓ Can reach DC at $ip"
    } else {
        Write-Host "✗ Cannot reach DC at $ip"
    }
}

# Attempt domain join
Write-Host "`nAttempting to join domain $domain..."
try {
    Add-Computer -DomainName $domain -Credential $credential -Verbose -Force
    Write-Host "✓ Domain join successful! Computer will restart..."
    Restart-Computer -Force
} catch {
    Write-Host "✗ Domain join failed: $_"
    Write-Host "`nTroubleshooting steps:"
    Write-Host "1. Verify Admin password is correct"
    Write-Host "2. Check security group allows traffic to/from AD (ports 53, 88, 389, 636, etc.)"
    Write-Host "3. Verify DNS servers are set to AD DNS IPs (10.200.1.245, 10.200.2.11)"
    Write-Host "4. Check VPC DHCP options set includes AD domain name"
    exit 1
}
