/*********************************************************************************************************************
* 
* FILES_MoveCommands.sql
* 
* Author: James Lutsey
* Date:   2018-05-09
* 
* Purpose: Generates the SQL and PowerShell commands to move database files
* 
* Notes: Default is to create commands for all user databases and all files. You can limit it to select databases and
*        and files by entering their names in the "INSERT INTO @Databases" and/or "INSERT INTO @Files" WHERE clauses.
* 
*        Set the destination directories @DataDestination & @LogDestination
* 
* Date        Name                  Description of change
* ----------  --------------------  ---------------------------------------------------------------------------------
* 2018-05-14  James Lutsey          Added ability to filter by files; works for tempdb files
* 
*********************************************************************************************************************/




SET NOCOUNT ON;

DECLARE @Commands  AS TABLE ( id INT IDENTITY(1,1) NOT NULL, line NVARCHAR(MAX) NOT NULL );
DECLARE @Databases AS TABLE ( name NVARCHAR(128) NOT NULL );
DECLARE @Files     AS TABLE ( dbName NVARCHAR(128) NOT NULL, name NVARCHAR(128) NOT NULL );



--------------------------------------------------------
--// USER INPUT                                     //--
--------------------------------------------------------

DECLARE @DataDestination   AS NVARCHAR(260) = N'F:\Databases\',
        @LogDestination    AS NVARCHAR(260) = N'G:\Logs\',
        @TempdbDestination AS NVARCHAR(260) = N'T:\TempDB\',
        @server            AS NVARCHAR(128);

INSERT INTO @Databases (name)
SELECT name
FROM   sys.databases
WHERE  name NOT IN (N'master',N'model',N'msdb')
       --AND name IN (N'', N'', N'', N'')  -- select name from sys.databases order by name;
       
INSERT INTO @Files (dbName, name)
SELECT DB_NAME(database_id),
       name
FROM   sys.master_files
WHERE  DB_NAME(database_id) NOT IN (N'master',N'model',N'msdb')
       --AND name IN (N'', N'', N'', N'')  -- select DB_NAME(database_id), name from sys.master_files order by DB_NAME(database_id), name;



--------------------------------------------------------
--// PREP                                           //--
--------------------------------------------------------

-- verify destination format
IF RIGHT(@DataDestination,1) <> N'\'   SET @DataDestination += N'\';
IF RIGHT(@LogDestination,1) <> N'\'    SET @LogDestination += N'\';
IF RIGHT(@TempdbDestination,1) <> N'\' SET @TempdbDestination += N'\';

-- store the servername, and remove the instance name if this is a named instance
SET @server = @@SERVERNAME;
IF CHARINDEX(N'\',@server) > 0
    SET @server = LEFT(@server,CHARINDEX(N'\',@server)-1);



--------------------------------------------------------
--// CREATE THE COMMANDS                            //--
--------------------------------------------------------

-- noexec safety
INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);
INSERT INTO @Commands (line) SELECT N'/*********************************************************************************************************************/';
INSERT INTO @Commands (line) SELECT N'    RAISERROR(N''Caught you! You don''''t really want to run this whole script...setting NOEXEC ON'',16,1) WITH NOWAIT;';
INSERT INTO @Commands (line) SELECT N'    SET NOEXEC ON; -- SET NOEXEC OFF;';
INSERT INTO @Commands (line) SELECT N'/*********************************************************************************************************************/';
INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);
INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);
INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);


-- server check
INSERT INTO @Commands (line) SELECT N'IF @@SERVERNAME <> N''' + @@SERVERNAME + N'''';
INSERT INTO @Commands (line) SELECT N'BEGIN';
INSERT INTO @Commands (line) SELECT N'    RAISERROR(N''wrong server - setting NOEXEC ON'',16,1) WITH NOWAIT;';
INSERT INTO @Commands (line) SELECT N'    SET NOEXEC ON;';
INSERT INTO @Commands (line) SELECT N'END;';
INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);
INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);
INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);


-- set databases offline
INSERT INTO @Commands (line) VALUES (N'-- set databases offline');

INSERT INTO @Commands (line) 
SELECT   DISTINCT N'ALTER DATABASE [' + a.name + N'] SET OFFLINE WITH ROLLBACK IMMEDIATE;'
FROM     sys.databases AS a
JOIN     @Databases    AS b ON b.name = a.name
JOIN     @Files        AS f ON f.dbName = a.name
WHERE    a.name <> N'tempdb'
ORDER BY 1;

INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);


-- move the physical files
INSERT INTO @Commands (line) VALUES (N'-- powershell commands to move the physical files');
INSERT INTO @Commands (line) VALUES (N'/*');

INSERT INTO @Commands (line) 
SELECT   CASE m.type
                WHEN 0 THEN N'robocopy ''' + left(m.physical_name,len(m.physical_name)-charindex(N'\',reverse(m.physical_name))) + N''' ''' + LEFT(@DataDestination,LEN(@DataDestination)-1) + N''' ''' + right(m.physical_name,charindex(N'\',reverse(m.physical_name))-1) + N''' /mov' COLLATE DATABASE_DEFAULT
                WHEN 1 THEN N'robocopy ''' + left(m.physical_name,len(m.physical_name)-charindex(N'\',reverse(m.physical_name))) + N''' ''' + LEFT(@LogDestination,LEN(@LogDestination)-1) + N''' ''' + right(m.physical_name,charindex(N'\',reverse(m.physical_name))-1) + N''' /mov' COLLATE DATABASE_DEFAULT
                --WHEN 0 THEN N'Move-Item -Path ''\\' + @server + N'\' + REPLACE(m.physical_name,N':',N'$') + N''' -Destination ''\\' + @server + N'\' + REPLACE(@DataDestination,N':',N'$') + RIGHT(m.physical_name,CHARINDEX(N'\',REVERSE(m.physical_name))-1) + N'''' COLLATE DATABASE_DEFAULT
                --WHEN 1 THEN N'Move-Item -Path ''\\' + @server + N'\' + REPLACE(m.physical_name,N':',N'$') + N''' -Destination ''\\' + @server + N'\' + REPLACE(@LogDestination,N':',N'$')  + RIGHT(m.physical_name,CHARINDEX(N'\',REVERSE(m.physical_name))-1) + N'''' COLLATE DATABASE_DEFAULT
                ELSE N'** UNACOUNTED FOR TYPE: [' + DB_NAME(m.database_id) + N'].[' + m.name + N'] ' + m.type_desc COLLATE DATABASE_DEFAULT
            END
FROM     sys.master_files AS m
JOIN     @Databases       AS d ON d.name = DB_NAME(m.database_id)
JOIN     @Files           AS f ON f.name = m.name
WHERE    d.name <> N'tempdb'
ORDER BY 1;

INSERT INTO @Commands (line) VALUES (N'*/');
INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);


-- move the logical files
INSERT INTO @Commands (line) VALUES (N'-- move the logical files');

INSERT INTO @Commands (line) 
SELECT   CASE 
             WHEN d.name <> N'tempdb' AND m.type = 0 THEN N'ALTER DATABASE [' + DB_NAME(m.database_id) + N'] MODIFY FILE ( NAME = N''' + m.name + N''', FILENAME = N''' + @DataDestination + N'' + RIGHT(m.physical_name,CHARINDEX(N'\',REVERSE(m.physical_name))-1) + N''' );' COLLATE DATABASE_DEFAULT
             WHEN d.name <> N'tempdb' AND m.type = 1 THEN N'ALTER DATABASE [' + DB_NAME(m.database_id) + N'] MODIFY FILE ( NAME = N''' + m.name + N''', FILENAME = N''' + @LogDestination  + N'' + RIGHT(m.physical_name,CHARINDEX(N'\',REVERSE(m.physical_name))-1) + N''' );' COLLATE DATABASE_DEFAULT
             WHEN d.name =  N'tempdb'                THEN N'ALTER DATABASE [' + DB_NAME(m.database_id) + N'] MODIFY FILE ( NAME = N''' + m.name + N''', FILENAME = N''' + @TempdbDestination + N'' + RIGHT(m.physical_name,CHARINDEX(N'\',REVERSE(m.physical_name))-1) + N''' );' COLLATE DATABASE_DEFAULT
             ELSE N'** UNACOUNTED FOR TYPE: [' + DB_NAME(m.database_id) + N'].[' + m.name + N'] ' + m.type_desc COLLATE DATABASE_DEFAULT
         END
FROM     sys.master_files AS m
JOIN     @Databases       AS d ON d.name = DB_NAME(m.database_id)
JOIN     @Files           AS f ON f.name = m.name
ORDER BY 1;

INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);


-- set databases online
INSERT INTO @Commands (line) VALUES (N'-- set databases online');

INSERT INTO @Commands (line) 
SELECT   DISTINCT N'ALTER DATABASE [' + a.name + N'] SET ONLINE;'
FROM     sys.databases AS a
JOIN     @Databases    AS b ON b.name = a.name
JOIN     @Files        AS f ON f.dbName = a.name
WHERE    a.name <> N'tempdb'
ORDER BY 1;

INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);

-- if tempdb files are moved, restart sql server and delete old files
IF EXISTS(SELECT 1 FROM @Databases WHERE name = N'tempdb')
   AND EXISTS(SELECT 1 FROM @Files WHERE dbName = N'tempdb')
BEGIN
    INSERT INTO @Commands (line) VALUES (N'-- ** RESTART SQL SERVER TO COMPLETE THE TEMPDB FILE MOVE **');
    INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);

    INSERT INTO @Commands (line) VALUES (N'-- powershell commands to delete the old tempdb files');
    INSERT INTO @Commands (line) VALUES (N'/*');

    INSERT INTO @Commands (line) 
    SELECT   N'Remove-Item -Path ''\\' + @server + N'\' + REPLACE(m.physical_name,N':',N'$') + N'''' COLLATE DATABASE_DEFAULT
    FROM     sys.master_files AS m
    JOIN     @Databases       AS d ON d.name = DB_NAME(m.database_id)
    JOIN     @Files           AS f ON f.name = m.name
    WHERE    d.name = N'tempdb'
    ORDER BY 1;

    INSERT INTO @Commands (line) VALUES (N'*/');
    INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);
END;


-- reset noexec
INSERT INTO @Commands (line) SELECT N'-- reset noexec';
INSERT INTO @Commands (line) SELECT N'SET NOEXEC OFF;';
INSERT INTO @Commands (line) SELECT NCHAR(0x000D) + NCHAR(0x000A);



--------------------------------------------------------
--// DISPLAY THE COMMANDS                           //--
--------------------------------------------------------

SELECT   line
FROM     @Commands
ORDER BY id;



