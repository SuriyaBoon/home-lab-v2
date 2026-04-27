Import-Module ActiveDirectory

$csvPath = "C:\Users.csv"
if (!(Test-Path $csvPath)) {
    Write-Host "ERROR: File Missing $csvPath" -ForegroundColor Red
    exit
}

$users = Import-Csv $csvPath
$totalUsers = $users.Count
$currentUser = 0

Write-Host "=== Bulk User Creation Script ===" -ForegroundColor Cyan
Write-Host "Total users to create: $totalUsers" -ForegroundColor Yellow
Write-Host ""


Write-Host "=== Step 1: Creating Security Groups ===" -ForegroundColor Cyan

$departments = $users | Select-Object -ExpandProperty Department -Unique
foreach ($dept in $departments) {
    try {
        $groupPath = "OU=Groups,OU=$dept,OU=Corp,DC=company,DC=local"
        New-ADGroup -Name $dept `
                    -GroupScope Global `
                    -GroupCategory Security `
                    -Path $groupPath
        Write-Host "  ✓ Created Group: $dept" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠ Group '$dept' may already exist, skipping..." -ForegroundColor Yellow
    }
}

Write-Host ""



Write-Host "=== Step 2: Creating Users ===" -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$failCount = 0

foreach ($user in $users) {
    $currentUser++
    try {
        
        New-ADUser `
            -Name "$($user.FirstName) $($user.LastName)" `
            -SamAccountName $user.Username `
            -UserPrincipalName "$($user.Username)@company.local" `
            -GivenName $user.FirstName `
            -Surname $user.LastName `
            -DisplayName "$($user.FirstName) $($user.LastName)" `
            -Department $user.Department `
            -Path "OU=Users,OU=$($user.Department),OU=Corp,DC=company,DC=local" `
            -AccountPassword (ConvertTo-SecureString "Welcome@2026" -AsPlainText -Force) `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -Description "Created by bulk import script"

        
        $groupDN = "CN=$($user.Department),OU=Groups,OU=$($user.Department),OU=Corp,DC=company,DC=local"
        Add-ADGroupMember -Identity $groupDN -Members $user.Username

        Write-Host "[$currentUser/$totalUsers] ✓ Created: $($user.Username) → Group: $($user.Department)" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "[$currentUser/$totalUsers] ✗ Failed: $($user.Username) - $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "=== Result ===" -ForegroundColor Cyan
Write-Host "✓ Success : $successCount Users" -ForegroundColor Green
Write-Host "✗ Failed  : $failCount Users" -ForegroundColor Red
Write-Host "Password  : Welcome@2026" -ForegroundColor Yellow
Write-Host "Users must change password at next login" -ForegroundColor Yellow