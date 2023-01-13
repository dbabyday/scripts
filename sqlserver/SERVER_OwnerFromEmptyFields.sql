/*********************************************************************************************************************
* 
* SERVER_OwnerFromEmptyFields.sql
* 
* Author: James Lutsey
* Date:   2018-01-01
* 
* Purpose: Gets the server owner documented in the EmptyFields.txt file
* 
*********************************************************************************************************************/


IF OBJECT_ID(N'tempdb..#TextFile',N'U') IS NOT NULL DROP TABLE #TextFile;
CREATE TABLE #TextFile ( [Line] VARCHAR(200) NOT NULL );
BULK INSERT #TextFile FROM 'C:\SN_Discovery_PlexusDataFile\EmptyFields.txt' WITH ( ROWTERMINATOR = '\n' );

SELECT SERVERPROPERTY('ServerName')                    AS [ServerName], 
       RIGHT([Line],LEN([Line])-CHARINDEX(':',[Line])) AS [OwnedBy]
FROM   #TextFile 
WHERE  LEFT([Line],9) = 'Owned by:';

IF OBJECT_ID(N'tempdb..#TextFile',N'U') IS NOT NULL DROP TABLE #TextFile;
GO
