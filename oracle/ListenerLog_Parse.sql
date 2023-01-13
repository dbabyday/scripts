--/*
declare @msg as nvarchar(max);

-- create the table to hold the text file lines
if object_id(N'tempdb..#textfile',N'U') is not null drop table #textfile;
create table #textfile ( line varchar(max) not null );

if object_id(N'tempdb..#parsed',N'U') is not null drop table #parsed;
create table #parsed ( [ENTRY_TIME] datetime2(0), [HOST] varchar(100), [IP_ADDRESS] varchar(20), [USER] varchar(100), [PROGRAM] varchar(1000));

set @msg = convert(nchar(19),getdate(),120) + N' - starting bulk insert'; raiserror(@msg,0,1) with nowait;

-- insert the lines from the text file
bulk insert #textfile from '\\neen-dsk-011\it$\database\users\James\JamesDownloads\jdepy01_rw.log.bak' with ( rowterminator = '\n' );

set @msg = convert(nchar(19),getdate(),120) + N' - parsing'; raiserror(@msg,0,1) with nowait;

-- let's see what we got
INSERT INTO #parsed ([ENTRY_TIME],[HOST],[IP_ADDRESS],[USER],[PROGRAM])
select   case when substring(line,3,1) = '-' then left(line,20)
              else '1900-01-01 00:00:00'
         end as [ENTRY_TIME]
       , case when charindex('(HOST=',line) <> 0 then substring(line,charindex('(HOST=',line) + 6,charindex(')',line,charindex('(HOST=',line) + 6) - charindex('(HOST=',line) - 6)
              else ''
         end as [HOST]
       , case when charindex('(HOST=',line) <> 0
                   and charindex('(HOST=',line,charindex('(HOST=',line) + 6) <> 0 
                   and substring(line,charindex('(HOST=',line) + 6,charindex(')',line,charindex('(HOST=',line) + 6) - charindex('(HOST=',line) - 6) <> substring(line,charindex('(HOST=',line,charindex('(HOST=',line) + 6) + 6,charindex(')',line,charindex('(HOST=',line,charindex('(HOST=',line) + 6) + 6) - charindex('(HOST=',line,charindex('(HOST=',line) + 6) - 6)
                   then substring(line,charindex('(HOST=',line,charindex('(HOST=',line) + 6) + 6,charindex(')',line,charindex('(HOST=',line,charindex('(HOST=',line) + 6) + 6) - charindex('(HOST=',line,charindex('(HOST=',line) + 6) - 6)
              else ''
         end as [IP_Address]
       , case when charindex('(USER=',line) <> 0 then substring(line,charindex('(USER=',line) + 6,charindex(')',line,charindex('(USER=',line) + 6) - charindex('(USER=',line) - 6)
              else ''
         end as [USER]
       , case when charindex('(PROGRAM=',line) <> 0 then substring(line,charindex('(PROGRAM=',line) + 9,charindex(')',line,charindex('(PROGRAM=',line) + 9) - charindex('(PROGRAM=',line) - 9)
              else ''
         end as [PROGRAM]
from     #textfile
where    substring(line,3,1) = '-';

set @msg = convert(nchar(19),getdate(),120) + N' - selecting'; raiserror(@msg,0,1) with nowait;

select   *
from     #parsed
order by [ENTRY_TIME];
--*/

select   [HOST]
       , [IP_ADDRESS]
       , [USER]
       , [PROGRAM]
       , count(*) as qty
       , min([ENTRY_TIME]) as first_entry_time
       , max([ENTRY_TIME]) as last_entry_time
from     #parsed
group by [HOST]
       , [IP_ADDRESS]
       , [USER]
       , [PROGRAM]
order by [IP_ADDRESS]
       , [USER]
       , [PROGRAM];


/*
-- clean up
if object_id(N'tempdb..#textfile',N'U') is not null drop table #textfile;
if object_id(N'tempdb..#parsed',N'U') is not null drop table #parsed;
go
*/