Connect-AzAccount
# Variables
$rgname = "your-resource-group"
$waname = "your-webapp-name"
$jsonPath = ".\accessrules.json"

# Load JSON file
$rules = Get-Content $jsonPath -Raw | ConvertFrom-Json

# Get existing SCM restriction rules
$existingConfig = Get-AzWebAppAccessRestrictionConfig `
    -ResourceGroupName $rgname `
    -WebAppName $waname

# Find highest existing priority
$existingPriorities = $existingConfig.ScmIpSecurityRestrictions.Priority

if ($existingPriorities.Count -gt 0) {
    $priority = ($existingPriorities | Measure-Object -Maximum).Maximum + 1
}
else {
    $priority = 100
}

foreach ($rule in $rules) {

    # Check if rule already exists
    $ruleExists = $existingConfig.ScmIpSecurityRestrictions |
        Where-Object { $_.Name -eq $rule.Name }

    if ($ruleExists) {
        Write-Host "Rule already exists: $($rule.Name)" -ForegroundColor Yellow
        continue
    }

    # Add rule
    Add-AzWebAppAccessRestrictionRule `
        -ResourceGroupName $rgname `
        -WebAppName $waname `
        -Name $rule.Name `
        -IpAddress $rule.IpAddress `
        -TargetScmSite `
        -Priority $priority `
        -Action Allow

    Write-Host "Added Rule: $($rule.Name) | Priority: $priority" -ForegroundColor Green

    $priority++
}

Write-Host "Completed adding access restriction rules." -ForegroundColor Cyan