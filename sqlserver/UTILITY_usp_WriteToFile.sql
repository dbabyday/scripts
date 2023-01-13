USE [CentralAdmin];
GO

IF OBJECT_ID('[dbo].[usp_WriteToFile]','P') IS NULL
	EXECUTE('CREATE PROCEDURE [dbo].[usp_WriteToFile] AS ;')
GO

ALTER PROCEDURE [dbo].[usp_WriteToFile]
    @File VARCHAR(206),
    @Text VARCHAR(MAX)
AS

DECLARE @OLE    INT;
DECLARE @FileID INT;

EXECUTE sp_OACreate 'Scripting.FileSystemObject', @OLE OUT;

EXECUTE sp_OAMethod @OLE, 'OpenTextFile', @FileID OUT, @File, 8, 1;

EXECUTE sp_OAMethod @FileID, 'WriteLine', Null, @Text;

EXECUTE sp_OADestroy @FileID;
EXECUTE sp_OADestroy @OLE;

GO