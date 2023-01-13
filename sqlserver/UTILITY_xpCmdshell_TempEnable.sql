/**************************************************************************************
*
* Author: James Lutsey
* Date: 02/24/2016
* 
* Purpose: Temporarily enable xp_cmdshell  
* 
* Notes:
*     1. Beginning and ending configurations are printed, so that you can confirm
*        the settings are the same. Or if an error occured during the execution, you 
*        can tell what the original configuration was and reset it.
*
**************************************************************************************/

SET NOCOUNT ON;

DECLARE 
	@xpCmdshellConfig_START INT,
	@xpCmdshellConfig_END	INT;


------------------------------------------------------------------------------------------
--// CHECK IF xp_cmdshell IS ENABLED                                                  //--
------------------------------------------------------------------------------------------

SELECT @xpCmdshellConfig_START = CONVERT(INT, ISNULL(value, value_in_use))
FROM  sys.configurations
WHERE  name = 'xp_cmdshell';

IF (@xpCmdshellConfig_START = 0)
BEGIN
	PRINT 'START: xp_cmdshell DISABLED'; 
	SELECT 'DISABLED' AS [xp_cmdshell START];
END
ELSE
BEGIN
	PRINT 'START: xp_cmdshell ENABLED'; 
	SELECT 'ENABLED' AS [xp_cmdshell START];
END

-- if xp_cmdshell is disabled, enable it so you can use it
IF @xpCmdshellConfig_START = 0
BEGIN
	EXEC sp_configure 'show advanced options', 1
	RECONFIGURE
	EXEC sp_configure 'xp_cmdshell', 1
	RECONFIGURE
END


------------------------------------------------------------------------------------------
--// DO YOUR STUFF WITH xp_cmdshell                                                   //--
------------------------------------------------------------------------------------------





------------------------------------------------------------------------------------------
--// IF xp_cmdshell WAS DISABLED, DISABLE IT AGAIN NOW THAT YOU ARE DONE              //--
------------------------------------------------------------------------------------------

IF @xpCmdshellConfig_START = 0
BEGIN
	EXEC sp_configure 'show advanced options', 1
	RECONFIGURE
	EXEC sp_configure 'xp_cmdshell', 0
	RECONFIGURE
END

SELECT @xpCmdshellConfig_END = CONVERT(INT, ISNULL(value, value_in_use))
FROM  sys.configurations
WHERE  name = 'xp_cmdshell';

IF (@xpCmdshellConfig_START = 0)
	PRINT 'END: xp_cmdshell DISABLED'; 
ELSE
	PRINT 'END: xp_cmdshell ENABLED';

SELECT 
	CASE @xpCmdshellConfig_START 
		WHEN 0 THEN 'DISABLED'
		WHEN 1 THEN 'ENABLED'
	END AS [xp_cmdshell START], 
	CASE @xpCmdshellConfig_END 
		WHEN 0 THEN 'DISABLED'
		WHEN 1 THEN 'ENABLED'
	END AS [xp_cmdshell END];

