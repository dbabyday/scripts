/*********************************************************************************************************************
* 
* SERVER_ServiceNowRequests.sql
* 
* Author: James Lutsey
* Date:   2018-08-14
* 
* Purpose: Create the strings needed to be entered for the following ServiceNow requests for a new SQL Server:
*              - CNAME
*              - Managed Service Accounts
*              - SSL Certificate
* 
* Date        Name                  Description of change
* ----------  --------------------  ---------------------------------------------------------------------------------
* 
* 
*********************************************************************************************************************/

SET NOCOUNT ON;


------------------------------------
--// USER INPUT                 //--
------------------------------------

DECLARE @fqdn        AS NVARCHAR(128) = N''
      , @ipAddress   AS NVARCHAR(25)  = N''
      , @environment AS NVARCHAR(5)   = N'' -- PROD, QA, TEST, TRAIN, DEV
      , @appName     AS NVARCHAR(128) = N'' -- used for the cname
      , @region      AS NVARCHAR(10)  = N'' -- AMER, APAC, EMEA, XIA, GUAD, ...

      -- additional services: change to "1" if installing
      , @ssis AS BIT = 0
      , @ssas AS BIT = 0
      , @ssrs AS BIT = 0;



------------------------------------
--// SET UP                     //--
------------------------------------

-- other variables
DECLARE @comments    AS NVARCHAR(300)
      , @cname       AS NVARCHAR(128)
      , @elevPriv    AS NVARCHAR(300)
      , @msg         AS NVARCHAR(MAX)
      , @primaryHost AS NVARCHAR(128);

DECLARE @Results TABLE
(
      id    INT           NOT NULL IDENTITY(1,1)
    , field NVARCHAR(50)  NOT NULL
    , value NVARCHAR(300) NOT NULL
);

-- validate
IF @fqdn = N''
BEGIN
    SET @msg = N'You must enter the fully qualified domain name for the server (@fqdn)';
    RAISERROR(@msg,16,1) WITH NOWAIT;
    SET NOEXEC ON;
END;
ELSE IF RIGHT(@fqdn,4) <> N'.com'
BEGIN
    SET @msg = N'The fully qualified domain name is not in the correct format (@fqdn)';
    RAISERROR(@msg,16,1) WITH NOWAIT;
    SET NOEXEC ON;
END;

IF @ipAddress = N''
BEGIN
    SET @msg = N'You must enter the IP Address for the server (@ipAddress)';
    RAISERROR(@msg,16,1) WITH NOWAIT;
    SET NOEXEC ON;
END;

IF @environment = N''
BEGIN
    SET @msg = N'You must enter the environment (PROD, QA, TEST, TRAIN, DEV) for the server (@environment)';
    RAISERROR(@msg,16,1) WITH NOWAIT;
    SET NOEXEC ON;
END;

IF @appName = N''
BEGIN
    SET @msg = N'WARNING: You did not eneter an application name (@appName). CNAME information will not be provided without this value.';
    RAISERROR(@msg,16,1) WITH NOWAIT;
END;

-- format the fqdn
SET @fqdn = LOWER(@fqdn);



------------------------------------
--// CNAME                      //--
------------------------------------

IF @appName <> N''
BEGIN
    -- create the cname string
    SET @cname = @appName;
    IF @region <> N'' SET @cname += N'-' + LOWER(@region);
    SET @cname += N'-' + LOWER(@environment) + N'.db.' + RIGHT(@fqdn,LEN(@fqdn) - CHARINDEX(N'.',@fqdn));
    
    -- insert the values into the result table
    INSERT INTO @Results(field,value) VALUES (N'** CNAME (DNS Request) **',N'')
                                           , (N'FQDN',                     @fqdn)
                                           , (N'IP Address',               @ipAddress)
                                           , (N'Addional Comments',        N'Please create an alias [' + @cname + N'] that points to [' + @fqdn + N']')
                                           , (N'',                         N'');
END;



------------------------------------
--// MANAGED SERVICE ACCOUNTS   //--
------------------------------------

-- create the string for elevated permissions
SET @elevPriv = N'Please add the managed service account for SQL Server service to the following groups. This will give permissions to folders used for SQL Server maintenance activities.' + NCHAR(0x000D) + NCHAR(0x000A) +
                NCHAR(0x000D) + NCHAR(0x000A);

IF UPPER(@environment) = N'PROD'
    SET @elevPriv += N'NA\Neenah-US Neen SQL Backups Edit Users in NA' + NCHAR(0x000D) + NCHAR(0x000A) +
                     N'NA\Neenah-US Databackup DEV-SQL-Backups View Users in NA';
ELSE
    SET @elevPriv += N'NA\Neenah-US Databackup DEV-SQL-Backups Edit Users in NA' + NCHAR(0x000D) + NCHAR(0x000A) +
                     N'NA\Neenah-US Neen SQL Backups View Users in NA';

-- create the string for additional comments
SET @comments = N'Please create managed service accounts for the following services on ' + @fqdn + NCHAR(0x000D) + NCHAR(0x000A) +
                NCHAR(0x000D) + NCHAR(0x000A) +
                N'SQL Server service' + NCHAR(0x000D) + NCHAR(0x000A) +
                N'SQL Server Agent service';

IF @ssas = 1
    SET @comments += NCHAR(0x000D) + NCHAR(0x000A) + N'SQL Server Analysis Services (SSAS) service';
IF @ssis = 1
    SET @comments += NCHAR(0x000D) + NCHAR(0x000A) + N'SQL Server Integration Services (SSIS) service';
IF @ssrs = 1
    SET @comments += NCHAR(0x000D) + NCHAR(0x000A) + N'SQL Server Reporting Services (SSRS) service';

-- insert the values into the result table
INSERT INTO @Results(field,value) VALUES (N'** MSAs (Service Account) **',N'')
                                       , (N'Service Account Name',        N'Managed Service Accounts | '+ @fqdn)
                                       , (N'Application Environment',     N'SQL Server - ' + UPPER(@environment))
                                       , (N'Login Password Secured',      N'Login entered in SQL Server Configuration Manager.' + NCHAR(0x000D) + NCHAR(0x000A) + N'Password is not entered.')
                                       , (N'Function Performing',         N'Running the services for SQL Server')
                                       , (N'Elevated Permissions',        @elevPriv)
                                       , (N'Additional Comments',         @comments)
                                       , (N'',                            N'');



------------------------------------
--// SSL CERTIFICATE            //--
------------------------------------

-- create the string for the primary host
SET @primaryHost = UPPER(@fqdn);

-- insert the values into the result table
INSERT INTO @Results(field,value) VALUES (N'** SSL Certificate Request **',N'')
                                       , (N'Common Name',                  @fqdn)
                                       , (N'Primary Host',                 @primaryHost)
                                       , (N'Additional Comments',          N'This certificate will be used by SQL Server on ' + @fqdn);



------------------------------------
--// DISPLAY RESULTS            //--
------------------------------------

SELECT   field
       , value
FROM     @Results
ORDER BY id;



------------------------------------
--// CLEAN UP                   //--
------------------------------------

-- reset
SET NOEXEC OFF;




