
EXECUTE CentralAdmin.dbo.usp_FilesInfo  -- @help = 'Y'
	@WHERE_PercentFree = N'<= 10', -- '', '<= 10', '> 50'
	@WHERE_type_desc   = N'', -- 'LOG' 'ROWS'
	@WHERE_Drive       = N'', -- 'C', 'F', 'G'
	@WHERE_Database    = N'', -- 'myDatabaseName'
	@WHERE_File        = N'', -- 'myFileName'

	-- @WHERE_Custom      = N'WHERE ...',
	
	@ORDERBY           = N'1,2', -- default is 'Database,File'

	@DisplayResults    = N'BOTH'; -- 'BOTH', 'FILES', 'DRIVES'

-- ALTER DATABASE [] MODIFY FILE ( NAME = N'', SIZE = MB, FILEGROWTH = MB );

/*
ORDER BY columns
	 1 - Database
	 2 - File
	 3 - type_desc
	 4 - Size_MB
	 5 - Used_MB
	 6 - Free_MB
	 7 - % Free
	 8 - Autogrowth
	 9 - max_size
	10 - Drive
	11 - DriveCapacity
	12 - DriveUsed
	13 - DriveFree
	14 - % DriveFree
	15 - usp_FileGrowth @where
*/