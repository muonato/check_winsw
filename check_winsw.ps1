# muonato/check_winsw.sh @ GitHub (27-DEC-2024)
#
# Reports installed software by reading 'DisplayName' and 'DisplayVersion'
# keys under the hive 'HKEY_LOCAL_MACHINE\SOFTWARE\' in Windows registry
#
# Usage:
#       PS> check_winsw.ps1 "[LF][,<application registry hive>] ..."
#
# Parameters:
#       1: String with application names separated by comma
#
#       (OPTIONAL) First value formats output with 'LF' for line feed
#
# Examples:
#       Check all installed software, default CSV output
#       PS> check_winsw.ps1
#
#       Check two applications, line feed output
#       PS> check_winsw.ps1 "LF,Microsoft Edge,VLC media player"
#
#       Check all installed, line feed output
#       PS> check_winsw.ps1 "LF"

function Get-WinSW([string]$regpath,[string]$separator) {
    # Returns keys 'DisplayName' and 'DisplayVersion'
    # under the Windows registry path input string

    $winsw = (Get-ItemProperty $regpath | Select-Object DisplayName, DisplayVersion | ForEach-Object {"{0} Version: {1}" -f $_.DisplayName, $_.DisplayVersion}) -join $separator
    "$winsw$separator"
}

$info = ""
$sepc = ", "
$arry = @()

# Expect single argument string 
# for NSClient++ compatibility
if ($args.count -eq 1) {
    $arry = $args[0].Split(",")
}

# First param in argument string
# formats output when 'LF' given
if ($arry[0] -eq "LF") {
    $apps = $arry | Where-Object { $_ –ne "LF" }
    $sepc = "`r`n"
} else {
    $apps = $arry
}

# Default to all children
# when no input arguments
if ($apps.count -eq 0) {
    $apps = @("*")
}

foreach ($name in $apps) {
    $hive = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$name"
    if (Get-ItemProperty -Path $hive -ErrorAction SilentlyContinue) {
        $info += Get-WinSW $hive $sepc
    }
    $hive = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$name"
    if (Get-ItemProperty -Path $hive -ErrorAction SilentlyContinue) {
        $info += Get-WinSW $hive $sepc
    }
}
Write-Host $info
exit 0