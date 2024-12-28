# muonato/check_winsw.ps1 @ GitHub (28-DEC-2024)
#
# Reports installed software by reading 'DisplayName' and 'DisplayVersion'
# keys under the hive 'HKEY_LOCAL_MACHINE\SOFTWARE\' in Windows registry
#
# Usage:
#       PS> check_winsw.ps1 "[LF][,<application registry key>] ..."
#
# Parameters:
#       1: String with application names separated by comma
#
#       (OPTIONAL) First value in parameter string
#       formats output with 'LF' for line feed
#
# Examples:
#       Check all installed software, default CSV output
#       PS> check_winsw.ps1 "*"
#
#       Opsview / Nagios host monitoring syntax
#       check_nrpe -H $HOSTADDRESS$ -c check_winsw -a "*"
#
#       Check two applications, line feed output
#       PS> check_winsw.ps1 "LF,Microsoft Edge,VLC media player"

function Get-WinSW([string]$regpath,[string]$format,[string]$product="DisplayName",[string]$version="DisplayVersion") {
    # Returns product and version keys in defined registry path
    $winsw = ""
    Get-ItemProperty $regpath -ErrorAction SilentlyContinue | Select-Object $product, $version | ForEach-Object {
        if (-not ([string]::IsNullOrEmpty($_.$product))) {
            $winsw = -join ($winsw, $format -f $_.$product, $_.$version)
        }
    }
    $winsw
}
$info = ""
$fmtc = ", "
$arry = @()

# Single argument string to support 
# NSClient++ monitoring configuration
if ($args.count -eq 1) {
    $arry = $args[0].Split(",")
}
# First param in CSV argument string to 
# format output with 'LF' for line feed
if ($arry[0] -eq "LF") {
    $apps = $arry | Where-Object { $_ -ne "LF" }
    $fmtc = "`r`n"
} else {
    $apps = $arry
}
# Loop registry hives defined in the CSV argument string by application name ('*' = all)
foreach ($name in $apps) {
    $hive = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$name"
    $info = -join ($info,(Get-WinSW -regpath $hive -format "{0} ({1}) [Win32]$fmtc"))

    $hive = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$name"
    $info = -join ($info,(Get-WinSW -regpath $hive -format "{0} ({1})$fmtc"))
}
# Windows version information to report as last value
$hive = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$info = -join ($info,(Get-WinSW -regpath $hive -format "{0} ({1})" -product "ProductName" -version "DisplayVersion"))

Write-Host $info
exit 0
