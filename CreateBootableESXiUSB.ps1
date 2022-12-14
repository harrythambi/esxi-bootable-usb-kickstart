<#
    .SYNOPSIS
    Using a PowerShell script to create an ESXi bootable USB drive and kickstart config to automate installation.

    .DESCRIPTION
    Using a PowerShell script to create an ESXi bootable USB drive and kickstart config to automate installation.

    .NOTES
    Version:        1.0
    Author:         Harry Thambi
    Creation Date:  08/11/2022
    Purpose/Change: Initial script development

    .LINK
    Blog: https://harrythambi.com
    Twitter: https://twitter.com/harrythambi
    GitHub: https://github.com/harrythambi/
    Repo: https://github.com/harrythambi/esxi-bootable-usb-kickstart

    .EXAMPLE
    # The following Example uses a ` Backtick to split a single command to multiple lines, easier to manage and read. Do not get confuse with apostrophe '

    .\CreateBootableESXiUSB.ps1 -isopath "C:\Users\HarryThambinayagam\Downloads\VMware-VMvisor-Installer-7.0U3g-20328353.x86_64.iso" `
    -diskNum 1 `
    -ip 10.20.0.4 `
    -netmask 255.255.255.0 `
    -gateway 10.20.0.1 `
    -nameserver 10.20.0.10 `
    -vlan 20 `
    -hostname mp-esxi01.harrythambi.cloud `
    -rootpw "VMware1!VMware1!"
#>

param(
    [Parameter(Mandatory)][string]$isoPath,
    [Parameter()][string]$diskNum,
    [Parameter()][string]$ip,
    [Parameter()][string]$netmask, 
    [Parameter()][string]$gateway,
    [Parameter()][string]$hostname,
    [Parameter()][string]$nameserver,
    [Parameter()][string]$vlan,
    [Parameter()][string]$rootpw
)
Write-Output ""

$welcome = @"
=====================================================================================================

HH   HH   AAA   RRRRRR  RRRRRR  YY   YY
HH   HH  AAAAA  RR   RR RR   RR YY   YY
HHHHHHH AA   AA RRRRRR  RRRRRR   YYYYY 
HH   HH AAAAAAA RR  RR  RR  RR    YYY  
HH   HH AA   AA RR   RR RR   RR   YYY  
                                        
TTTTTTT HH   HH   AAA   MM    MM BBBBB   IIIII        CCCCC   OOOOO  MM    MM 
  TTT   HH   HH  AAAAA  MMM  MMM BB   B   III        CC    C OO   OO MMM  MMM 
  TTT   HHHHHHH AA   AA MM MM MM BBBBBB   III        CC      OO   OO MM MM MM 
  TTT   HH   HH AAAAAAA MM    MM BB   BB  III   ...  CC    C OO   OO MM    MM 
  TTT   HH   HH AA   AA MM    MM BBBBBB  IIIII  ...   CCCCC   OOOO0  MM    MM 

=====================================================================================================

EEEEEEE  SSSSS  XX    XX IIIII       BBBBB    OOOOO   OOOOO  TTTTTTT   AAA   BBBBB   LL      EEEEEEE 
EE      SS       XX  XX   III        BB   B  OO   OO OO   OO   TTT    AAAAA  BB   B  LL      EE      
EEEEE    SSSSS    XXXX    III        BBBBBB  OO   OO OO   OO   TTT   AA   AA BBBBBB  LL      EEEEE   
EE           SS  XX  XX   III        BB   BB OO   OO OO   OO   TTT   AAAAAAA BB   BB LL      EE      
EEEEEEE  SSSSS  XX    XX IIIII       BBBBBB   OOOO0   OOOO0    TTT   AA   AA BBBBBB  LLLLLLL EEEEEEE 
                                                                                                
KK  KK IIIII  CCCCC  KK  KK  SSSSS  TTTTTTT   AAA   RRRRRR  TTTTTTT       UU   UU  SSSSS  BBBBB   
KK KK   III  CC    C KK KK  SS        TTT    AAAAA  RR   RR   TTT         UU   UU SS      BB   B  
KKKK    III  CC      KKKK    SSSSS    TTT   AA   AA RRRRRR    TTT         UU   UU  SSSSS  BBBBBB  
KK KK   III  CC    C KK KK       SS   TTT   AAAAAAA RR  RR    TTT         UU   UU      SS BB   BB 
KK  KK IIIII  CCCCC  KK  KK  SSSSS    TTT   AA   AA RR   RR   TTT          UUUUU   SSSSS  BBBBBB  
                                                                                            
SSSSS   CCCCC  RRRRRR  IIIII PPPPPP  TTTTTTT 
SS      CC     RR   RR  III  PP   PP   TTT   
SSSSS  CC      RRRRRR   III  PPPPPP    TTT   
   SS  CC      RR  RR   III  PP        TTT   
SSSSS   CCCCC  RR   RR IIIII PP        TTT   

=====================================================================================================           
"@

Write-Output $welcome
Write-Output ""

$usbDisks = Get-Disk | Where BusType -eq 'USB' | Select 'Number','FriendlyName', 'size'
Write-Host "INFO:     Listing connected USB Flash Drives"
Write-Host " "
Foreach ($disk in $usbDisks) {
    Write-Host "Disk Number: " $disk.Number
    Write-Host "Disk Name: " $disk.FriendlyName
    $size = ($disk.size)/1GB
    Write-Host "Disk Size: " $size "GB"
    Write-Host " "
}

if (-not $diskNum) {
    $diskNum = Read-Host "Select the Disk Number of the USB Disk to use"
}

Write-Host -ForegroundColor Yellow "QUERY:     Usb Disk Number " $diskNum " was selected, are you sure to continue?"
$confirmContinue = Read-Host "Y/N"
# $confirmContinue = Read-Host "Usb Disk Number " $diskNum " was selected, are you sure to continue? Y/N"

if ($confirmContinue -eq "Y") {
    Write-Output "INFO:     Formatting and creating new parition on selected USB drive"
    Clear-Disk -Number $diskNum -RemoveData -Confirm:$false -PassThru | Out-Null
    $nextAvailDriveLetter = get-wmiobject win32_logicaldisk | select -expand DeviceID -Last 1 | % { [char]([int][char]$_[0]  + 1) + $_[1] }
    New-Partition -DiskNumber $diskNum -UseMaximumSize -DriveLetter $nextAvailDriveLetter.split(":")[0] | Format-Volume -FileSystem FAT32 -AllocationUnitSize 8192 -NewFileSystemLabel ESXI-BOOT | Out-Null
} else {
    Write-Host -ForegroundColor Red "ERROR:     SCRIPT TERMINATED BY USER"
    break
}

$fileStatus = Test-Path -Path $isoPath -PathType Leaf

if (-not $fileStatus) {  
    Write-Host -ForegroundColor Red "ERROR:     ESXI ISO FILE DOES NOT EXIST."
    break
}
Write-Output "INFO:     ESXi iso file exists"
Write-Output "INFO:     Mounting ESXi iso"
Mount-DiskImage -ImagePath (get-item $isoPath).FullName | Out-Null
$isoMountDrive = $(Get-CimInstance Win32_LogicalDisk | ?{ $_.DriveType -eq 5} | Where VolumeName -match "ESXI").DeviceID

Write-Output "INFO:     Copying contents of ESXi iso to USB"  
(xcopy $isoMountDrive"\" $nextAvailDriveLetter"\" /e) | Out-Null

Write-Output "INFO:     Ejecting ESXi iso image"
$driveEject = New-Object -comObject Shell.Application
$driveEject.Namespace(17).ParseName($isoMountDrive).InvokeVerb("Eject")

# Modify BOOT.CFG
Write-Output "INFO:     Modifying BOOT.CFG in ESXi-BOOT USB"
$kernelOldText = "kernelopt=runweasel cdromBoot"
$kernelNewText = "kernelopt=ks=usb:/KS.CFG"
((Get-Content -Path $nextAvailDriveLetter"\BOOT.CFG" -Raw) -replace $kernelOldText,$kernelNewText) | Set-Content -Path $nextAvailDriveLetter"\BOOT.CFG"
((Get-Content -Path $nextAvailDriveLetter"\EFI\BOOT\BOOT.CFG" -Raw) -replace $kernelOldText,$kernelNewText) | Set-Content -Path $nextAvailDriveLetter"\EFI\BOOT\BOOT.CFG"

# Create Kickstart from Template
Write-Output "INFO:     Creating KS.CFG on ESXi-BOOT USB"
$ksTemplate = @"
vmaccepteula
install --firstdisk=usb --overwritevmfs --novmfsondisk
reboot

network --bootproto=static --ip=$($ip) --netmask=$($netmask) --gateway=$($gateway) --hostname=$($hostname) --nameserver=$($nameserver) --addvmportgroup=0 $(if($vlan){"--vlanid=$($vlan)"})
rootpw $($rootpw)

%firstboot --interpreter=busybox

# enable & start SSH
vim-cmd hostsvc/enable_ssh
vim-cmd hostsvc/start_ssh

# enable & start ESXi Shell
vim-cmd hostsvc/enable_esx_shell
vim-cmd hostsvc/start_esx_shell

# Suppress ESXi Shell warning
esxcli system settings advanced set -o /UserVars/SuppressShellWarning -i 1
"@

$ksTemplate | Set-Content -Path $nextAvailDriveLetter"\KS.CFG"

Write-Host -ForegroundColor Green "SUCCESS:     ESXi USB Creation complete with Kickstart"
