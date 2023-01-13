/**********************************************************************************************************
*
*  Delete Ola Hallengren's Maintenance Jobs and Stored Procs
*
**********************************************************************************************************/

USE [msdb]
GO

DECLARE 
	@jobId_CommandLogCleanup	VARCHAR(50),
	@jobId_SystemFullBU			VARCHAR(50),
	@jobId_UserDiffBU			VARCHAR(50),
	@jobId_UserFullBU			VARCHAR(50),
	@jobId_UserLogBU			VARCHAR(50),
	@jobId_SystemIntegrity		VARCHAR(50),
	@jobId_UserIntegrity		VARCHAR(50),
	@jobId_UserIndexOp			VARCHAR(50),
	@jobId_OutputFileCleanup	VARCHAR(50),
	@jobId_DeleteBackupHistory	VARCHAR(50),
	@jobId_PurgeJobHistory		VARCHAR(50);


SELECT @jobId_CommandLogCleanup		= job_id FROM dbo.sysjobs WHERE name = 'CommandLog Cleanup';
SELECT @jobId_SystemFullBU			= job_id FROM dbo.sysjobs WHERE name = 'DatabaseBackup - SYSTEM_DATABASES - FULL';
SELECT @jobId_UserDiffBU			= job_id FROM dbo.sysjobs WHERE name = 'DatabaseBackup - USER_DATABASES - DIFF';
SELECT @jobId_UserFullBU			= job_id FROM dbo.sysjobs WHERE name = 'DatabaseBackup - USER_DATABASES - FULL';
SELECT @jobId_UserLogBU				= job_id FROM dbo.sysjobs WHERE name = 'DatabaseBackup - USER_DATABASES - LOG';
SELECT @jobId_SystemIntegrity		= job_id FROM dbo.sysjobs WHERE name = 'DatabaseIntegrityCheck - SYSTEM_DATABASES';
SELECT @jobId_UserIntegrity			= job_id FROM dbo.sysjobs WHERE name = 'DatabaseIntegrityCheck - USER_DATABASES';
SELECT @jobId_UserIndexOp			= job_id FROM dbo.sysjobs WHERE name = 'IndexOptimize - USER_DATABASES';
SELECT @jobId_OutputFileCleanup		= job_id FROM dbo.sysjobs WHERE name = 'Output File Cleanup';
SELECT @jobId_DeleteBackupHistory	= job_id FROM dbo.sysjobs WHERE name = 'sp_delete_backuphistory';
SELECT @jobId_PurgeJobHistory		= job_id FROM dbo.sysjobs WHERE name = 'sp_purge_jobhistory';

EXEC msdb.dbo.sp_delete_job @job_id=@jobId_CommandLogCleanup, @delete_unused_schedule=1;
EXEC msdb.dbo.sp_delete_job @job_id=@jobId_SystemFullBU, @delete_unused_schedule=1;
EXEC msdb.dbo.sp_delete_job @job_id=@jobId_UserDiffBU, @delete_unused_schedule=1;
EXEC msdb.dbo.sp_delete_job @job_id=@jobId_UserFullBU, @delete_unused_schedule=1;
EXEC msdb.dbo.sp_delete_job @job_id=@jobId_UserLogBU, @delete_unused_schedule=1;
EXEC msdb.dbo.sp_delete_job @job_id=@jobId_SystemIntegrity, @delete_unused_schedule=1;
EXEC msdb.dbo.sp_delete_job @job_id=@jobId_UserIntegrity, @delete_unused_schedule=1;
EXEC msdb.dbo.sp_delete_job @job_id=@jobId_UserIndexOp, @delete_unused_schedule=1;
EXEC msdb.dbo.sp_delete_job @job_id=@jobId_OutputFileCleanup, @delete_unused_schedule=1;
EXEC msdb.dbo.sp_delete_job @job_id=@jobId_DeleteBackupHistory, @delete_unused_schedule=1;
EXEC msdb.dbo.sp_delete_job @job_id=@jobId_PurgeJobHistory, @delete_unused_schedule=1;

USE [DbaTools];
GO

DROP PROCEDURE [dbo].[CommandExecute];
GO
DROP PROCEDURE [dbo].[DatabaseBackup];
GO
DROP PROCEDURE [dbo].[DatabaseIntegrityCheck];
GO
DROP PROCEDURE [dbo].[IndexOptimize];
GO

DROP TABLE [CommandLog];
GO

EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'DbaTools'
GO
USE [master]
GO
DROP DATABASE [DbaTools]
GO
