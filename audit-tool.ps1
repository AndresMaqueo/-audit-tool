# ===========================================
# 📜 MS Graph Audit Toolkit - audit-tool.ps1
# ===========================================

# Conectar a Microsoft Graph con los permisos necesarios
Connect-MgGraph -Scopes User.Read.All, Application.Read.All, Directory.Read.All -NoWelcome

Write-Output "Obteniendo todos los usuarios (incluyendo invitados)..."
$users = Get-MgUser -All | Select-Object Id, DisplayName, UserPrincipalName, AccountEnabled, JobTitle, Mail

Write-Output "Obteniendo roles administrativos asignados a usuarios..."
$adminRoles = Get-MgDirectoryRole -All
$userRoles = @()
foreach ($role in $adminRoles) {
    $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All | Select-Object Id, DisplayName, UserPrincipalName
    foreach ($member in $members) {
        $userRoles += [PSCustomObject]@{
            UserId = $member.Id
            DisplayName = $member.DisplayName
            UserPrincipalName = $member.UserPrincipalName
            RoleName = $role.DisplayName
        }
    }
}

Write-Output "Obteniendo licencias asignadas a usuarios..."
$userLicenses = @()
foreach ($user in $users) {
    $licenses = (Get-MgUserLicenseDetail -UserId $user.Id -ErrorAction SilentlyContinue) | Select-Object SkuId, ServicePlans
    $skuNames = ($licenses | ForEach-Object { $_.SkuId }) -join ", "
    $userLicenses += [PSCustomObject]@{
        UserId = $user.Id
        DisplayName = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        Licenses = $skuNames
    }
}

Write-Output "Obteniendo aplicaciones registradas y sus dueños..."
$apps = Get-MgApplication -All | Select-Object Id, DisplayName, AppId
$appOwnersList = @()
foreach ($app in $apps) {
    $owners = Get-MgApplicationOwner -ApplicationId $app.Id -ErrorAction SilentlyContinue | Select-Object DisplayName, UserPrincipalName
    $ownerNames = if ($owners) { ($owners | ForEach-Object { $_.DisplayName }) -join ", " } else { "Sin dueños" }
    $appOwnersList += [PSCustomObject]@{
        AppId = $app.AppId
        DisplayName = $app.DisplayName
        Owners = $ownerNames
    }
}

# Crear carpeta de salida si no existe
$outputPath = "./reports"
if (-not (Test-Path $outputPath)) { New-Item -ItemType Directory -Path $outputPath | Out-Null }

# Exportar reportes
Write-Output "Exportando reportes..."

$users | ConvertTo-Json -Depth 6 | Out-File -FilePath "$outputPath/UsersReport.json" -Encoding utf8
$users | Export-Csv -Path "$outputPath/UsersReport.csv" -NoTypeInformation -Encoding utf8

$userRoles | ConvertTo-Json -Depth 6 | Out-File -FilePath "$outputPath/UserRolesReport.json" -Encoding utf8
$userRoles | Export-Csv -Path "$outputPath/UserRolesReport.csv" -NoTypeInformation -Encoding utf8

$userLicenses | ConvertTo-Json -Depth 6 | Out-File -FilePath "$outputPath/UserLicensesReport.json" -Encoding utf8
$userLicenses | Export-Csv -Path "$outputPath/UserLicensesReport.csv" -NoTypeInformation -Encoding utf8

$appOwnersList | ConvertTo-Json -Depth 6 | Out-File -FilePath "$outputPath/AppsReport.json" -Encoding utf8
$appOwnersList | Export-Csv -Path "$outputPath/AppsReport.csv" -NoTypeInformation -Encoding utf8

Write-Output "`n✅ Proceso completado. Reportes generados en '$outputPath':"
Write-Output " - UsersReport.csv / UsersReport.json"
Write-Output " - UserRolesReport.csv / UserRolesReport.json"
Write-Output " - UserLicensesReport.csv / UserLicensesReport.json"
Write-Output " - AppsReport.csv / AppsReport.json"

# Resumen en consola
Write-Output "`nResumen:"
Write-Output "Usuarios totales: $($users.Count)"
Write-Output "Roles administrativos encontrados: $($userRoles.Count)"
Write-Output "Usuarios con licencias: $($userLicenses.Count)"
Write-Output "Aplicaciones registradas: $($apps.Count)"
