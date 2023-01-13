/*****************************************************************************************************************************
* 
* UTILITY_RepeatedExecution.sql
* 
* Author: James Lutsey
* Date: 01/12/2016
* 
* Purpose: Repeat a command execution, or any process, for a list of items. The example sets all
*          user databases online.
* 
* Notes:
*     1. Set the list with the select statement (line 32)
*     2. View the list by uncommenting line 34 and running script to that point
*     3. Set the command you want to repeate (line 44)
*     4. The default is to print the commands. To execute, when possible, uncomment the EXEC sp_executesql (line 47)
* 
*****************************************************************************************************************************/

DECLARE 
    @SelectedId   INT,
    @MaxId        INT,
    @Item         NVARCHAR(128),
    @Command      NVARCHAR(MAX);

DECLARE @tb_list TABLE
(
    [ID]   INT IDENTITY(1,1) PRIMARY KEY,
    [Item] VARCHAR(128)
);

INSERT INTO @tb_list ([Item])
SELECT name FROM master.sys.databases WHERE name NOT IN ('master', 'model', 'msdb', 'tempdb', 'distribution') ORDER BY name;

--SELECT * FROM @tb_list;

SET @SelectedId = 1;
SELECT @MaxId = MAX(ID) FROM @tb_list;

WHILE (@SelectedId <= @MaxId)
BEGIN

    SELECT @Item = [Item] FROM @tb_list WHERE [ID] = @SelectedId;
	
    SET @Command = N'ALTER DATABASE [' + @Item + '] SET ONLINE;' + CHAR(13)+CHAR(10) + 'GO';

    PRINT @Command;
    --EXEC sp_executesql @stmt = @Command;
    
    SET @SelectedId = @SelectedId + 1;

END
