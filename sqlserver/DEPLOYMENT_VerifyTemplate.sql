declare @timeCheck datetime2(0) = N'';
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
declare @myMsgCode    nvarchar(10)  = N''
      , @myDB         nvarchar(128) = N''
      , @myFK         nvarchar(128) = N''
      , @mySchema     nvarchar(128) = N''
      , @myTable      nvarchar(128) = N''
      , @myColumn     nvarchar(128) = N''
      , @myRefSchema  nvarchar(128) = N''
      , @myRefTable   nvarchar(128) = N''
      , @myRefColumn  nvarchar(128) = N''
      , @myDfCnst     nvarchar(128) = N''
      , @myObj        nvarchar(128) = N''
      , @myUser       nvarchar(128) = N''
      , @myPriv       nvarchar(128) = N''
      , @msgGood      nvarchar(max) = N''
      , @msgError     nvarchar(max) = N''
      , @sql          nvarchar(max) = N''
      , @myValue      int           = 0
      , @fqFK         nvarchar(257) = N''
      , @fqTable      nvarchar(257) = N''
      , @fqRefTable   nvarchar(257) = N''
      , @fqDfCnst     nvarchar(128) = N''
      , @fqObj        nvarchar(128) = N'';



if OBJECT_ID(N'tempdb..#DeploymentVerificationCheck',N'U') is not null
    drop table #DeploymentVerificationCheck;
create table #DeploymentVerificationCheck ( myValue int );




-- table exists
set @myMsgCode = N'';
set @mySchema  = N'';
set @myTable   = N'';
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
set @fqTable  = @mySchema + N'.' + @myTable;
set @msgGood  = @myMsgCode + N': Table ' + @fqTable + N' exists';
set @msgError = N'ERROR ' + REPLACE(@msgGood,N' exists',N' does not exist');
if exists(select 1 from sys.tables where object_id=OBJECT_ID(@fqTable,N'U'))
    raiserror(@msgGood,0,1) with nowait;
else
    raiserror(@msgError,16,1) with nowait;



-- default constraint exists
set @myMsgCode = N'';
set @mySchema  = N'';
set @myTable   = N'';
set @myDfCnst  = N'';
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
set @fqDfCnst = @mySchema + N'.' + @myDfCnst;
set @fqTable  = @mySchema + N'.' + @myTable;
set @msgGood  = @myMsgCode + N': Default constraint ' + @fqDfCnst + N' exists on ' + @fqTable;
set @msgError = N'ERROR ' + REPLACE(@msgGood,N' exists',N' does not exist');
if exists(select 1 from sys.default_constraints where object_id=OBJECT_ID(@fqDfCnst,N'D') and parent_object_id=OBJECT_ID(@fqTable,N'U'))
    raiserror(@msgGood,0,1) with nowait;
else
    raiserror(@msgError,16,1) with nowait;



-- foreign key exists
set @myMsgCode   = N'';
set @myFK        = N'';
set @mySchema    = N'';
set @myTable     = N'';
set @myColumn    = N'';
set @myRefSchema = N'';
set @myRefTable  = N'';
set @myRefColumn = N'';
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
set @fqFK       = @mySchema + N'.' + @myFK;
set @fqTable    = @mySchema + N'.' + @myTable;
set @fqRefTable = @myRefSchema + N'.' + @myRefTable;
set @msgGood    = @myMsgCode + N': Foreign key ' + @myFK + N' exists on ' + @mySchema + N'.' + @myTable + N'.' + @myColumn + N' referencing ' + @myRefSchema + N'.' + @myRefTable + N'.' + @myRefColumn;
set @msgError   = N'ERROR ' + REPLACE(@msgGood,N' exists',N' does not exist');
if exists(select 1 from sys.foreign_keys as f join sys.foreign_key_columns as fc on f.object_id = fc.constraint_object_id where f.object_id=OBJECT_ID(@fqFK,N'F') and f.parent_object_id=OBJECT_ID(@fqTable,N'U') and COL_NAME(fc.parent_object_id, fc.parent_column_id)=@myColumn and f.referenced_object_id=OBJECT_ID(@fqRefTable,N'U') and COL_NAME(fc.referenced_object_id, fc.referenced_column_id)=@myRefColumn)
    raiserror(@msgGood,0,1) with nowait;
else
    raiserror(@msgError,16,1) with nowait;



-- column exists
set @myMsgCode   = N'';
set @mySchema    = N'';
set @myTable     = N'';
set @myColumn    = N'';
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
set @fqTable    = @mySchema + N'.' + @myTable;
set @msgGood    = @myMsgCode + N': Column ' + @myColumn + N' exists on ' + @fqTable;
set @msgError   = N'ERROR ' + REPLACE(@msgGood,N' exists',N' does not exist');
if exists(select 1 from sys.columns where object_id=OBJECT_ID(@fqTable,N'U') and name=@myColumn)
    raiserror(@msgGood,0,1) with nowait;
else
    raiserror(@msgError,16,1) with nowait;



-- stored procedure
set @myMsgCode = N'';
set @mySchema  = N'';
set @myObj     = N'';
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
set @fqObj     = @mySchema + N'.' + @myObj;
set @msgGood   = @myMsgCode + N': Procedure ' + @fqObj + N' exists, and has been modified';
set @msgError  = N'ERROR ' + REPLACE(@msgGood,N'and has been modified',N'but has not been modified after the specified time');
if exists(select 1 from sys.procedures where object_id=OBJECT_ID(@fqObj,N'P') and modify_date>=@timeCheck)
    raiserror(@msgGood,0,1) with nowait;
else if OBJECT_ID(@fqObj,N'P') is not null
    raiserror(@msgError,16,1) with nowait;
else
begin
    set @msgError  = REPLACE(@msgError,N'exists, but has not been modified after the specified time',N'does not exist');
    raiserror(@msgError,16,1) with nowait;
end;



-- stored procedure for specified database
set @myMsgCode = N'';
set @myDB      = N'';
set @mySchema  = N'';
set @myObj     = N'';
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
set @fqObj     = @mySchema + N'.' + @myObj;
set @msgGood   = @myMsgCode + N': Procedure ' + @myDB + N'.' + @fqObj + N' exists, and has been modified';
set @msgError  = N'ERROR ' + REPLACE(@msgGood,N'and has been modified',N'but has not been modified after the specified time');
set @sql       = N'if exists(select 1 from ' + @myDB + N'.sys.procedures where object_id=OBJECT_ID(N''' + @myDB + N'.' + @fqObj + N''',N''P'') and modify_date>=N''' + CONVERT(NCHAR(19),@timeCheck,120) + N''')
    insert into #DeploymentVerificationCheck (myValue) values (0);
else if OBJECT_ID(N''' + @myDB + N'.' + @fqObj + N''',N''P'') is not null
    insert into #DeploymentVerificationCheck (myValue) values (1);
else
    insert into #DeploymentVerificationCheck (myValue) values (2);';
truncate table #DeploymentVerificationCheck;
execute sys.sp_executesql @stmt=@sql;
if exists(select 1 from #DeploymentVerificationCheck) select top(1) @myValue=myValue from #DeploymentVerificationCheck;
    else set @myValue=-1;
if @myValue=0          raiserror(@msgGood,0,1) with nowait;
    else if @myValue=1 raiserror(@msgError,16,1) with nowait;
    else if @myValue=2 begin set @msgError = REPLACE(@msgError,N'exists, but has not been modified after the specified time',N'does not exist'); raiserror(@msgError,16,1) with nowait; end;
    else               begin set @msgError = N'ERROR ' + @myMsgCode + N': Bad value'; raiserror(@msgError,16,1) with nowait; end;



-- privilege for specified database
set @myMsgCode = N'';
set @myDB      = N'';
set @mySchema  = N'';
set @myObj     = N'';
set @myUser    = N'';
set @myPriv    = N'';
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
set @fqObj     = @mySchema + N'.' + @myObj;
set @msgGood   = @myMsgCode + N': User ' + @myUser + N' has ' + @myPriv + N' granted on ' + @myDB + N'.' + @fqObj;
set @msgError  = N'ERROR ' + REPLACE(@msgGood,N' has ',N' does not have ');
set @sql       = N'if exists(select b.name,a.* from ' + @myDB + N'.sys.database_permissions a join ' + @myDB + N'.sys.database_principals b on b.principal_id=a.grantee_principal_id where b.name=N''' + @myUser + N''' and a.major_id=OBJECT_ID(N''' + @myDB + N'.' + @mySchema + N'.' + @myObj + N''',N''P'') and a.permission_name=N''' + @myPriv + N''')
    insert into #DeploymentVerificationCheck (myValue) values (0);
else
    insert into #DeploymentVerificationCheck (myValue) values (1);';
truncate table #DeploymentVerificationCheck;
execute sys.sp_executesql @stmt=@sql;
if exists(select 1 from #DeploymentVerificationCheck) select top(1) @myValue=myValue from #DeploymentVerificationCheck;
else set @myValue=-1;
if @myValue=0      raiserror(@msgGood,0,1) with nowait;
else if @myValue=1 raiserror(@msgError,16,1) with nowait;
else               begin set @msgError = N'ERROR ' + @myMsgCode + N': Bad value'; raiserror(@msgError,16,1) with nowait; end;