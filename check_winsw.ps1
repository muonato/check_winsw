# muonato/check_winsw.ps1 @ GitHub (29-DEC-2024)
#
# Reports software version by matching name in argument string to
# Windows registry key under the hive 'HKEY_LOCAL_MACHINE\SOFTWARE\'
#
# Usage:
#       PS> check_winsw.ps1 "[LF][,<application>] ..."
#
# Parameters:
#       1: String with application names separated by comma
#
#       (OPTIONAL) First value in parameter string
#       formats output with 'LF' for line feed
#
# Examples:
#       Check OS version only
#       PS> check_winsw.ps1
#
#       Opsview / Nagios host monitoring syntax
#       check_nrpe -H $HOSTADDRESS$ -c check_winsw -a "Microsoft"
#
#       Check two applications, line feed output
#       PS> check_winsw.ps1 "LF,SQL,VLC"

function Get-WinSW([string]$regpath,[string]$software,[string]$format,[string]$product="DisplayName",[string]$version="DisplayVersion") {
    # Returns matching product and version keys in defined registry path
    
    $winsw = ""
    Get-ItemProperty $regpath -ErrorAction SilentlyContinue | Select-Object $product, $version | ForEach-Object {
        $match = "$_.$product" | Select-String $software

        if (-not ([string]::IsNullOrEmpty($match))) {
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
    $apps = $arry | Where-Object { $_ –ne "LF" }
    $fmtc = "`r`n"
} else {
    $apps = $arry
}

# Loop registry hives defined in the CSV argument string ('*' = all)
foreach ($name in $apps) {
    $hive = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $info = -join ($info,(Get-WinSW -regpath $hive -software $name -format "{0} ({1}) [Win32]$fmtc"))

    $hive = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $info = -join ($info,(Get-WinSW -regpath $hive -software $name -format "{0} ({1})$fmtc"))
}
# Windows version information to report as last value
$hive = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
$info = -join ($info,(Get-WinSW -regpath $hive -software "Windows" -format "{0} (Build {1})" -product "ProductName" -version "CurrentBuild"))

Write-Host $info
exit 0