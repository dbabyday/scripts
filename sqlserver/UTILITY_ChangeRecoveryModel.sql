

-- user input
DECLARE @recoveryWanted AS VARCHAR(6)   = 'MODEL';  -- MODEL  FULL  SIMPLE


-- other variables
DECLARE @unwantedRecoveryModel AS INT = 0,
        @sql                   AS VARCHAR(MAX) = '';

IF @recoveryWanted = 'MODEL'
BEGIN
    SELECT @recoveryWanted = recovery_model_desc
    FROM   sys.databases
    WHERE  name = 'model';
END;

SET @unwantedRecoveryModel = CASE WHEN @recoveryWanted = 'FULL'   THEN 3
                                  WHEN @recoveryWanted = 'SIMPLE' THEN 1
                                  ELSE 0
                             END;

SELECT @sql = @sql + 'ALTER DATABASE [' + [name] + '] SET RECOVERY ' + @recoveryWanted + ';' + CHAR(13)+CHAR(10)
FROM sys.databases
WHERE [recovery_model] = @unwantedRecoveryModel AND [name] NOT IN ('master','msdb','tempdb')
ORDER BY [name];

SELECT @sql AS [SET RECOVERY MODEL];

SELECT   [name],
         [recovery_model_desc],
         [state_desc],
         CASE 
             WHEN [database_id] > 4 THEN 'user'
             ELSE 'system'
         END AS [database_type]
FROM     [sys].[databases]
ORDER BY [database_type],
         [state_desc],
         [recovery_model_desc] DESC,
         [name];



