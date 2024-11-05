/*
Microsoft Website for Media Type and Bus Type Definitions, we will have to construct a case statement so that we can return the number values as digestible strings. See example below
https://docs.microsoft.com/en-us/previous-versions/windows/desktop/stormgmt/msft-physicaldisk?redirectedfrom=MSDN

Required classes that need to be enabled in SCCM for this report to work properly
Get-WmiObject -Namespace "Root\Microsoft\Windows\Storage" -Class "MSFT_Disk"
Get-WmiObject -Namespace "Root\Microsoft\Windows\Storage" -Class "MSFT_Partition"
Get-WmiObject -Namespace "Root\Microsoft\Windows\Storage" -Class "MSFT_PhysicalDisk"
Get-WmiObject -Namespace "Root\Microsoft\Windows\Storage" -Class "MSFT_Volume"
*/

Declare @OperatingSystemFilter VARCHAR(Max) = '%NT%Workstation%';
Declare @IsClientInstalled INT = 1;
Declare @IsClientActive INT = 1;

Select Distinct
	
	dbo.v_R_System.ResourceID As "ResourceID",

	IsNull(Upper(dbo.v_R_System.Netbios_Name0), 'N/A') As "ComputerName",

	LTrim(RTrim(dbo.v_GS_MSFT_DISK.SerialNumber0)) As "Disk_SerialNumber",

	LTrim(RTrim(dbo.v_GS_MSFT_DISK.FriendlyName0)) As "Disk_FriendlyName",

	dbo.v_GS_MSFT_DISK.Number0 As "Disk_Number",
	
	dbo.v_GS_MSFT_DISK.NumberOfPartitions0 As "Disk_PartitionCount",

	Case dbo.v_GS_MSFT_PHYSICALDISK.MediaType0
			When '0' Then 'Unknown'  
			When '3' Then 'HDD'  
			When '4' Then 'SSD'
			When '5' Then 'SCM'
	End As "Disk_MediaType",

	Case dbo.v_GS_MSFT_PHYSICALDISK.BusType0
			When '0' Then 'Unknown'  
			When '1' Then 'SCSI'  
			When '2' Then 'ATAPI'
			When '3' Then 'ATA'
			When '4' Then '1394'
			When '5' Then 'SSA'
			When '6' Then 'Fibre Channel'
			When '7' Then 'USB'
			When '8' Then 'RAID'
			When '9' Then 'iSCSI'
			When '10' Then 'SAS'
			When '11' Then 'SATA'
			When '12' Then 'SD'
			When '13' Then 'MMC'
			When '14' Then 'MAX'
			When '15' Then 'File Backed Virtual'
			When '16' Then 'Storage Spaces'
			When '17' Then 'NVMe'
			When '18' Then 'Microsoft Reserved'
	End As "Disk_BusType",

	Round((dbo.v_GS_MSFT_DISK.Size0 / 1024.0 / 1024.0 / 1024.0), 2) As "Disk_SizeInGB",

	dbo.v_GS_MSFT_PARTITION.PartitionNumber0 As "Partition_Number",

	dbo.v_GS_MSFT_PARTITION.IsSystem0 As "Partition_IsSystem",

	dbo.v_GS_MSFT_PARTITION.IsActive0 As "Partition_IsActive",

	dbo.v_GS_MSFT_PARTITION.IsBoot0 As "Partition_IsBoot",

	dbo.v_GS_MSFT_PARTITION.IsHidden0 As "Partition_IsHidden",

	dbo.v_GS_MSFT_VOLUME.FileSystemLabel0 As "Volume_FileSystemLabel",

	dbo.v_GS_LOGICAL_DISK.DeviceID0 As "Volume_DriveLetter",

	dbo.v_GS_MSFT_VOLUME.FileSystem0 As "Volume_FileSystem",

	Round((dbo.v_GS_MSFT_VOLUME.Size0 / 1024.0 / 1024.0 / 1024.0), 2) As "Volume_SizeInGB",

	Round((dbo.v_GS_MSFT_VOLUME.SizeRemaining0 / 1024.0 / 1024.0 / 1024.0), 2) As "Volume_SizeRemainingInGB",

	dbo.v_GS_MSFT_VOLUME.HealthStatus0 As "Volume_HealthStatus",

	dbo.v_GS_MSFT_VOLUME.OperationalStatus0 As "Volume_OperationalStatus"

From
	dbo.v_R_System
Left Join
	dbo.v_GS_MSFT_DISK On (dbo.v_GS_MSFT_DISK.ResourceID = dbo.v_R_System.ResourceID)
Left Join
	dbo.v_GS_MSFT_PHYSICALDISK On (dbo.v_GS_MSFT_PHYSICALDISK.ResourceID = dbo.v_R_System.ResourceID) And (dbo.v_GS_MSFT_PHYSICALDISK.DeviceId0 = dbo.v_GS_MSFT_DISK.Number0)
Left Join
	dbo.v_GS_MSFT_PARTITION On (dbo.v_GS_MSFT_PARTITION.ResourceID = dbo.v_R_System.ResourceID) And (dbo.v_GS_MSFT_PARTITION.DiskNumber0 = dbo.v_GS_MSFT_DISK.Number0)
Left Join
	dbo.v_GS_MSFT_VOLUME On (dbo.v_GS_MSFT_VOLUME.ResourceID = dbo.v_R_System.ResourceID) And (dbo.v_GS_MSFT_VOLUME.Path0 = Concat('\\?\Volume', dbo.v_GS_MSFT_PARTITION.Guid0, '\'))
Left Join
	dbo.v_GS_LOGICAL_DISK On (dbo.v_GS_LOGICAL_DISK.ResourceID = dbo.v_R_System.ResourceID) And (dbo.v_GS_LOGICAL_DISK.VolumeName0 = dbo.v_GS_MSFT_VOLUME.FileSystemLabel0)
Where
	(dbo.v_GS_MSFT_PHYSICALDISK.BusType0 Not Like '%USB%')
		And
	(dbo.v_R_System.Client0 = @IsClientInstalled)
		And
	(dbo.v_R_System.Active0 = @IsClientActive)
					And
	(dbo.v_R_System.Operating_System_Name_and0 Like @OperatingSystemFilter)
Group By
	dbo.v_R_System.ResourceID,
	dbo.v_R_System.Netbios_Name0,
	dbo.v_GS_MSFT_DISK.SerialNumber0,
	dbo.v_GS_MSFT_DISK.FriendlyName0,
	dbo.v_GS_MSFT_DISK.Number0,
	dbo.v_GS_MSFT_DISK.NumberOfPartitions0,
	dbo.v_GS_MSFT_PHYSICALDISK.MediaType0,
	dbo.v_GS_MSFT_PHYSICALDISK.BusType0,
	dbo.v_GS_MSFT_DISK.Size0,
	dbo.v_GS_MSFT_PARTITION.PartitionNumber0,
	dbo.v_GS_MSFT_PARTITION.IsSystem0,
	dbo.v_GS_MSFT_PARTITION.IsActive0,
	dbo.v_GS_MSFT_PARTITION.IsBoot0,
	dbo.v_GS_MSFT_PARTITION.IsHidden0,
	dbo.v_GS_MSFT_VOLUME.FileSystemLabel0,
	dbo.v_GS_LOGICAL_DISK.DeviceID0,
	dbo.v_GS_MSFT_VOLUME.FileSystem0,
	dbo.v_GS_MSFT_VOLUME.Size0,
	dbo.v_GS_MSFT_VOLUME.SizeRemaining0,
	dbo.v_GS_MSFT_VOLUME.HealthStatus0,
	dbo.v_GS_MSFT_VOLUME.OperationalStatus0,
	dbo.v_R_System.Client0,
	dbo.v_R_System.Active0,
	dbo.v_R_System.Operating_System_Name_and0
Order By
	ComputerName