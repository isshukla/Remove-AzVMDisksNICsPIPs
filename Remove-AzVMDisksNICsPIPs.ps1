
#------------------------------------------------------------------------------   
#     
# THIS MODULE AND ANY ASSOCIATED INFORMATION ARE PROVIDED 'AS IS' WITHOUT   
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT   
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS   
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR    
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.   
#   
#------------------------------------------------------------------------------  


$ResourceGroup = Read-Host "Enter the Resource Group name"

$VMName = Read-Host "Enter the VM name"

$a = Get-Random -Maximum 9999 -Minimum 1

$vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName

#Write Log 
Start-Transcript -Path "$env:temp\DeleteAzVM-$a-$VMName.log" -NoClobber

write-host "
#------------------------------------------------------------------------------   
#     
# THIS MODULE AND ANY ASSOCIATED INFORMATION ARE PROVIDED 'AS IS' WITHOUT   
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT   
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS   
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR    
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.   
#   
#------------------------------------------------------------------------------  
Running this module will cause deletion of resources, which cannot be recovered. Run this module at your own risk.
" -ForegroundColor Red


if(!$VM){Break}

Else{


#NIC
$nicname = @()
$nicname += $vm.NetworkProfile.NetworkInterfaces.id | Split-Path -Leaf
$nicRG = @()
$nicRG += $vm.NetworkProfile.NetworkInterfaces.id | ForEach-Object {$_ -replace ".*/resourceGroups/" -replace "/.*"}

$GetNIC = @()
For ($i=0;$i -lt $nicname.Count; $i++){
$GetNIC += Get-AzNetworkInterface -Name $nicname[$i] -ResourceGroupName $nicRG[$i]
}
$Ipconfname = $getnic.IpConfigurations.id

# PiP Check
$PiPName = @()
$PiPRG = @()
if(!$getnic.IpConfigurations.publicipaddress.id){
Write-Host "No Public IP Found"}
Else{

$PiPName += $getnic.IpConfigurations.publicipaddress.id | Split-Path -Leaf
$PiPRG += $getnic.IpConfigurations.publicipaddress.id | ForEach-Object {$_ -replace ".*/resourceGroups/" -replace "/.*"}

$getpip = @()
for($i=0;$i -lt $PiPName.count; $i++){
$getpip += Get-AzPublicIpAddress -Name $PiPName[$i] -ResourceGroupName $PiPRG[$i]
}}


#Disks:
$OSDisk = $vm.StorageProfile.OsDisk.Name
$dataDisk = $vm.StorageProfile.DataDisks.name

#Disks RG
$OSDiskRG = $vm.StorageProfile.OsDisk.ManagedDisk.Id | ForEach-Object {$_ -replace ".*/resourceGroups/" -replace "/.*"}
$dataDiskRG = $vm.StorageProfile.DataDisks.ManagedDisk.Id | ForEach-Object {$_ -replace ".*/resourceGroups/" -replace "/.*"}
 
#Disk Details
$disk = @()
$disk += $OSDisk

if(!$dataDisk){$null
}
Else{
$disk += $dataDisk
}


$diskRG = @()
$diskRG +=  $OSDiskRG

if(!$dataDiskRG)
{$null}
Else{$diskRG +=$dataDiskRG}

$diskIDs = @()
$diskIDs += $($vm.StorageProfile.OsDisk.ManagedDisk.Id),$($vm.StorageProfile.DataDisks.ManagedDisk.Id)

$getdisk = @()
For($i=0;$i -lt $disk.count; $i++){
$getdisk += Get-AzDisk -ResourceGroupName $diskRG[$i] -DiskName $disk[$i]
}


#Write-Host "Following Items will be deleted press Y to confirm" -ForegroundColor Red

Write-Host "VM" -ForegroundColor Green 
$vm.Id
"`n"

Write-Host "NICs" -ForegroundColor Green
$($vm.NetworkProfile.NetworkInterfaces.id)
"`n"

Write-Host "Disks" -ForegroundColor Green
$disk
"`n"

Write-Host "IPConfigs" -ForegroundColor Green
$($getnic.IpConfigurations.id)
$GetNIC.ipconfigurations.privateipaddress
"`n"

Write-Host "Public IPs" -ForegroundColor Green
if(!$getnic.IpConfigurations.publicipaddress.id){
Write-Host "No Public IP Found"}
Else{
$($getnic.IpConfigurations.publicipaddress.id)
$getpip.IPaddress
"`n"
}


Write-Host "Resources listed above will be deteled, and cannot be recovered. Enter Y to proceed, press any other key to stop" -ForegroundColor Red
$conf = Read-Host "Enter Y to proceed, press any other key to stop" 
if ($conf -ne 'y'){Break}

Else{

#Delay
Write-Host "You have selected $conf."
$delay = (Get-Date).AddSeconds(10)
while($delay -gt $(get-date)){
$sec = $delay - $(Get-Date)
Write-Host "Deleting the resources in $($sec.Seconds) Seconds..."
Start-Sleep -Seconds 1
#Write-Progress -Activity "Deleting resources in" -SecondsRemaining $sec.Seconds
}

#Removing VM
#Remove-AzVM -Name $VMName -ResourceGroupName $ResourceGroup -Force

#Removing Disks
For($i=0;$i -lt $disk.count; $i++){
Remove-AzDisk -ResourceGroupName $diskRG[$i] -DiskName $disk[$i] -Force
}

#Remove NIC
For ($i=0;$i -lt $nicname.Count; $i++){
Remove-AzNetworkInterface -Name $nicname[$i] -ResourceGroupName $nicRG[$i] -Force
}

#Remove IPConfig

#Remove PIP
for($i=0;$i -lt $PiPName.count; $i++){
Remove-AzPublicIpAddress -Name $PiPName[$i] -ResourceGroupName $PiPRG[$i] -Force
}


}

}



Stop-Transcript

Start-Process $env:temp

