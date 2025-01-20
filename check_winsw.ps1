# muonato/check_winsw.ps1 @ GitHub (20-JAN-2025)
#
# Reports software by matching keywords in argument string to
# registry key under the hive 'HKEY_LOCAL_MACHINE\SOFTWARE\'
#
# Usage:
#       PS> check_winsw.ps1 "[LF][,<keyword>] ... [,<keyword>]"
#
# Parameters:
#       1: String of keywords separated by comma
#
#       (OPTIONAL) First value in parameter string
#       formats output with 'LF' for line feed
#
# Examples:
#       Check all installed
#       PS> check_winsw.ps1 "LF"
#
#       Opsview / Nagios host monitoring syntax
#       check_nrpe -H $HOSTADDRESS$ -c check_winsw -a "SQL,NSClient"
#
#       Check matching keywords, line feed output
#       PS> check_winsw.ps1 "LF,SQL,SSMS,VMware"
#
# Platform:
#       NSClient++ (0.5.2.41 2018-04-26) for Nagios/Opsview
#       Powershell 7.4.3
#
function Get-RegSW([string]$regpath,[string]$format,[string]$product="DisplayName",[string]$version="DisplayVersion") {
    # Returns an array of strings each formatted from two distinct key-value pairs in given registry hive
    
    $keys = @()
    Get-ItemProperty $regpath -ErrorAction SilentlyContinue | Select-Object $product, $version | ForEach-Object {
        if (-not [string]::IsNullOrEmpty($_.$product)) {
            $keys += $format -f $_.$product, $_.$version
        }
    }
    $keys
}
# List apps
$apps = @()

# Find match
$find = @()

# Arguments str to array
if ($args.count -eq 1) {
    $keyw = $args[0].Split(",")
} else {
    $keyw = @()
}

# First argument to define value
# separator as comma or line feed
if ($keyw[0] -eq "LF") {
    $keyw = $keyw | Where-Object { $_ –ne "LF" }
    $fmtc = "`r`n"
} else {
    $fmtc = ", "
}

# Script version information to results string
$info = "Opsview check_softw (20-JAN-2025)" + $fmtc

# Append OS version information to results string
$hive = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$info += (Get-RegSW -regpath $hive -format "{0} (Build {1})" -product "ProductName" -version "CurrentBuild") + $fmtc

# Software registry values of installed applications to array
$hive = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$apps += Get-RegSW -regpath $hive -format "{0} ({1}) [Win32]"

$hive = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$apps += Get-RegSW -regpath $hive -format "{0} ({1})"

# Find keywords in apps array
# and append to results array
if (-not $keyw) {
    $info += $apps -join $fmtc | Out-String
} else {
    foreach ($word in $keyw) {
        $apps | ForEach-Object {
            if ($_.Contains($word)) {
                $find += $_
            }
        }
    }
    # Convert search results array to string
    $info += $find -join $fmtc | Out-String
}
Write-Host $info

exit 0
