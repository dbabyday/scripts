Add-PSSnapin "VMware.VimAutomation.Core"
if ( $mac -eq $null ) {
	$mac = Get-Credential
}

Clear-Host

$pre  = "IF @@SERVERNAME != 'CO-DB-042'`r`n"
$pre += "BEGIN`r`n"
$pre += "    RAISERROR('Wrong server - setting NOEXEC ON. Connect to CO-DB-042.',16,1);`r`n"
$pre += "    SET NOEXEC ON;`r`n"
$pre += "END`r`n"
$pre += "`r`n"
$pre += "USE CentralAdmin;`r`n"
$pre += "`r`n"
$pre += "--/*`r`n"
$pre += "IF (OBJECT_ID('james.VMDiskMap_20170504','U') IS NOT NULL) DROP TABLE james.VMDiskMap_20170504;`r`n"
$pre += "CREATE TABLE CentralAdmin.james.VMDiskMap_20170504`r`n"
$pre += "(`r`n"
$pre += "    [ID]           INT IDENTITY(1,1) PRIMARY KEY,`r`n"
$pre += "    [Server]       NVARCHAR(128),`r`n"
$pre += "    [Drive]        NVARCHAR(128),`r`n"
$pre += "    [VM_SCSI_Id]   NVARCHAR(128),`r`n"
$pre += "    [Datastore]    NVARCHAR(128),`r`n"
$pre += "    [VM_Format]    NVARCHAR(128),`r`n"
$pre += "    [EntryDate]    DATETIME2(0)`r`n"
$pre += ");`r`n"
$pre += "--*/`r`n"

$pre

$groups = 'prod','dev'

foreach ($group in $groups) {
	"/*"

	if ( $group -eq 'prod') {
		$Servers = Get-Content -Path 'C:\Projects\IO Latency\VMDiskMap_Servers_Prod.txt'
		Connect-VIServer -Server vcenter.na.plexus.com -Credential $mac
	}
	elseif ( $group -eq 'dev') {
		$Servers = Get-Content -Path 'C:\Projects\IO Latency\VMDiskMap_Servers_Dev.txt'
		Connect-VIServer -Server dcc-vc-comp-001.na.plexus.com -Credential $mac
	}

	"*/`r`n"

	foreach ($Server in $Servers) {
		if($cred -eq $null ){
		$global:cred = $mac 
		} 
		### Get VM 
		$vm = Get-VM $Server | where {($_.Guest.GuestFamily -eq 'windowsGuest') -and ($_.PowerState -eq 'PoweredOn') }

		### Hashtable for WMI queries
		$WMIHast = @{
					ComputerName = $Server
					ErrorAction = 'Stop'
					Credential = $cred
					}
		### Create array to hold VM disk properites			
		$VMDisks =@()	
		### Loop through SCSI controllers on VM, and get info from each attached disk
		foreach ($SCSIController in ($vm.ExtensionData.Config.Hardware.Device | where {$_.DeviceInfo.Label -match "SCSI Controller"})) {
			foreach ($VirtualDiskDevice in ($vm.ExtensionData.Config.Hardware.Device | where {$_.ControllerKey -eq $SCSIController.Key})){
				### Create something to hold data for each pass
				$VirtualDisk = "" | Select VM_SCSIController, VM_Uuid, VM_SCSI_Id, VM_DiskName, VM_DiskFile, VM_DiskSizeGB, VM_BusNum, VM_UnitNum, VM_RDMMode, VM_Format 
				### Add data for each disk
				$VirtualDisk.VM_SCSIController = $SCSIController.DeviceInfo.Label
				$VirtualDisk.VM_DiskName = $VirtualDiskDevice.DeviceInfo.Label
				$VirtualDisk.VM_BusNum = $SCSIController.BusNumber
				$VirtualDisk.VM_UnitNum = $VirtualDiskDevice.UnitNumber
				$VirtualDisk.VM_SCSI_Id = "$($SCSIController.BusNumber) : $($VirtualDiskDevice.UnitNumber)"
				$VirtualDisk.VM_DiskFile = $VirtualDiskDevice.Backing.FileName
				$VirtualDisk.VM_DiskSizeGB = $VirtualDiskDevice.CapacityInKB * 1KB / 1GB
				$VirtualDisk.VM_RDMMode = $VirtualDiskDevice.Backing.CompatibilityMode
				IF($VirtualDiskDevice.Backing.ThinProvisioned){$VirtualDisk.VM_Format = 'Thin'}elseif($VirtualDiskDevice.Backing.EagerlyScrub){$VirtualDisk.VM_Format = 'Eager'}else{$VirtualDisk.VM_Format = 'Lazy'}
				IF($VirtualDiskDevice.Backing.Uuid){$VirtualDisk.VM_Uuid = $VirtualDiskDevice.Backing.Uuid.replace("-","") }
				### Dump data from this pass to $VMDisks array	
				$VMDisks = $VMDisks +  $VirtualDisk
			}
		}
		### Gather data from Guest OS via WMI

		# WMI data
		$wmi_diskdrives = Get-WmiObject @WMIHast -Class Win32_DiskDrive
		$wmi_mountpoints = Get-WmiObject @WMIHast -Class Win32_Volume -Filter "DriveType=3 AND DriveLetter IS NULL"
		### Create array to hold disk/partition info		
		$DiskElements = @()
		$warn = @()
		### Loop through each virtual disk		
		foreach ($vmdisk in $VMDisks)
		{				
			### Loop through Win32_DiskDrive (Win 2003 matching uses SCSIPort - 2, 2008 and above use more accurate disk serial number/VM UUID)	
			foreach ($diskdrive in ( $wmi_diskdrives | where-object {if($_.SerialNumber){$_.SerialNumber -eq $vmdisk.VM_Uuid}else{($_.SCSIPort - 2 -eq $vmdisk.VM_BusNum) -and ($_.SCSITargetId -eq $vmdisk.VM_UnitNum)}}))
			{
				$partitionquery = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($diskdrive.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"
				$partitions = Get-WmiObject @WMIHast -Query $partitionquery
				foreach ($partition in ( $partitions | where-object {$_.DiskIndex -eq $diskdrive.Index} ))
				{
					$diskprops = "" | SELECT 'VM_SCSIController', 'VM_DiskName', 'VM_DiskFile','VM_SCSI_Id','VM_RDMMode','VM_Format','VolumeName','Drive','DiskSize' ,'Offset','Aligned'
					$diskprops.VM_SCSIController = $vmdisk.VM_SCSIController
					$diskprops.VM_DiskName = $vmdisk.VM_DiskName
					$diskprops.VM_DiskFile = $vmdisk.VM_DiskFile
					$diskprops.VM_SCSI_Id = $vmdisk.VM_SCSI_Id	
					$diskprops.VM_RDMMode = $vmdisk.VM_RDMMode
					$diskprops.VM_Format = $vmdisk.VM_Format

					$diskprops.DiskSize = $partition.Size | ConvertTo-KMG
					$diskprops.Offset = $partition.StartingOffset
					$diskprops.Aligned = 'YES'
					if( $diskprops.Offset % 1024 -ne 0)
					{
						$diskprops.Aligned = 'MISALIGNED'
					}
					$logicaldiskquery = "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($partition.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"
					$logicaldisks =Get-WmiObject @WMIHast -Query $logicaldiskquery
					if ($logicaldisks)
					{
						foreach ($logicaldisk in $logicaldisks)
						{
							$diskprops.VolumeName = $logicaldisk.VolumeName
							$diskprops.Drive = $logicaldisk.Name
						}
					}
					else
					{
						#$diskprops.DiskSize #####$mp.Capacity | ConvertTo-KMG
						foreach( $mp in ($wmi_mountpoints | where {($_.Capacity | ConvertTo-KMG) -eq ($diskprops.DiskSize )}))
						{
							$multiples = "" | Select 'SCSIID','MountPoint'
							if(($wmi_mountpoints | where {($_.Capacity | ConvertTo-KMG) -eq ($diskprops.DiskSize )}).Count -gt 1)
							{
								$multiples.SCSIID = $diskprops.VM_SCSI_Id
								$multiples.MountPoint = $mp.Name
								$diskprops.Drive = "WARNING - see below"
								$warn += $multiples
							}
							else
							{
								$diskprops.Drive += $mp.Name
							}
						}
					}
					$DiskElements += $diskprops
					
				}
			}
		}

		$i = 0
		$sql = "INSERT INTO CentralAdmin.james.VMDiskMap_20170504 ([Server],[VM_SCSI_Id],[Datastore],[VM_Format],[Drive],[EntryDate]) VALUES"
		foreach ($disk in $DiskElements) {
			$i++

			$vmScsiId  = $disk.VM_SCSI_Id
			$datastore = $disk.VM_DiskFile
			$vmFormat  = $disk.VM_Format
			$drive     = $disk.Drive
			$entryDate = (Get-Date -format s)

			$sql += "`r`n('$Server','$vmScsiId','$datastore','$vmFormat','$drive','$entryDate')"
			if ( $i -lt ($DiskElements.Count) ) {
				$sql += ","
			}
			else {
				$sql += ";`r`n"
			}
		}

		$sql

		#$DiskElements # | ft VM_SCSIController, VM_DiskName, VM_SCSI_Id,VM_RDMMode,VM_DiskFile,VM_Format, VolumeName,DiskSize,Offset,Aligned,Drive -autosize
		if($warn)
		{
			write-warning "Cannot determine disk to partition mapping for the following disks, possible matches listed"
			$warn | ft
		}



	}
}


Write-Host "SELECT * FROM CentralAdmin.james.VMDiskMap_20170504;"