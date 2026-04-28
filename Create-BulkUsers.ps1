New-Item -Path "C:\Scripts" -ItemType Directory -Force

@'
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

$successCount = 0
$failCount = 0

foreach ($user in $users) {
    $currentUser++
    try {
        New-ADUser `
            -Name "$($user.FirstName) $($user.LastName)" `
            -SamAccountName $user.Username `
            -UserPrincipalName "$($user.Username)@corp.local" `
            -GivenName $user.FirstName `
            -Surname $user.LastName `
            -DisplayName "$($user.FirstName) $($user.LastName)" `
            -Department $user.Department `
            -Path "OU=Users,OU=$($user.Department),OU=Corp,DC=corp,DC=local" `
            -AccountPassword (ConvertTo-SecureString "Welcome@2026" -AsPlainText -Force) `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -Description "Created by bulk import script"

        $groupName = "grp-$($user.Department)-All"
        Add-ADGroupMember -Identity $groupName -Members $user.Username

        Write-Host "[$currentUser/$totalUsers] OK Created: $($user.Username) -> $groupName" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "[$currentUser/$totalUsers] FAIL: $($user.Username) - $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "=== Result ===" -ForegroundColor Cyan
Write-Host "Success : $successCount Users" -ForegroundColor Green
Write-Host "Failed  : $failCount Users" -ForegroundColor Red
Write-Host "Password  : Welcome@2026" -ForegroundColor Yellow
Write-Host "Users must change password at next login" -ForegroundColor Yellow
'@ | Out-File -FilePath C:\Scripts\Create-BulkUsers.ps1 -Encoding ASCII
