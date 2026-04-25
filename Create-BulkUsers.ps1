Import-Module ActiveDirectory

$csvPath = "C:\Users.csv"

if (!(Test-Path $csvPath)) {
    Write-Host "ERROR: File Missing$csvPath" -ForegroundColor Red
    exit
}

$users = Import-Csv $csvPath

$totalUsers = $users.Count
$currentUser = 0

Write-Host "=== Bulk User Creation Script ===" -ForegroundColor Cyan
Write-Host "Total users Created:$totalUsers" -ForegroundColor Yellow
Write-Host ""

foreach ($user in $users) {
    $currentUser++

    try {
        New-ADUser `
            -Name "$($user.FirstName)$($user.LastName)" `
            -SamAccountName $user.Username `
            -UserPrincipalName "$($user.Username)@company.local" `
            -GivenName $user.FirstName `
            -Surname $user.LastName `
            -DisplayName "$($user.FirstName)$($user.LastName)" `
            -Department $user.Department `
            -Path "OU=Users,OU=$($user.Department),OU=Corp,DC=company,DC=local" `
            -AccountPassword (ConvertTo-SecureString "Welcome@2026" -AsPlainText -Force) `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -Description "Created by bulk import script"

        Write-Host "[$currentUser/$totalUsers] ✓ Created:$($user.Username) ($($user.Department))" -ForegroundColor Green

    } catch {
        Write-Host "[$currentUser/$totalUsers] ✗ Failed:$($user.Username) -$($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "===Result===" -ForegroundColor Cyan
Write-Host "Success! Total User created $totalUsers Users" -ForegroundColor Green
Write-Host "Password: Welcome@2026" -ForegroundColor Yellow
Write-Host "Users Must Change Password at Next login" -ForegroundColor Yellow