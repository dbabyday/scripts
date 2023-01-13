
-- create the table to hold the text file lines
if object_id(N'tempdb..#textfile',N'U') is not null drop table #textfile;
create table #textfile ( line varchar(max) not null );

if object_id(N'tempdb..#parsed',N'U') is not null drop table #parsed;
create table #parsed ( entry_time datetime2(0), [USER] varchar(max), [HOST] varchar(max), [PROGRAM] varchar(max), line varchar(max));


-- insert the lines from the text file
bulk insert #textfile from '\\neen-dsk-011\it$\database\users\James\JamesProjects\DataRefresh\20190211\jdrf\jdtrn_scripts\Round2\listener_jdtrn.log' with ( rowterminator = '\n' );



-- let's see what we got
INSERT INTO #parsed (entry_time,[USER],HOST,PROGRAM,line)
select   case when left(line,2) = '12' then '2019-02-12 ' + substring(line,12,8)
              when left(line,2) = '13' then '2019-02-13 ' + substring(line,12,8)
              when left(line,3) = 'Tue' then '2019-02-12 ' + substring(line,12,8)
              when left(line,3) = 'Wed' then '2019-02-13 ' + substring(line,12,8)
              else '1900-01-01 00:00:00'
         end as entry_time
       , case when charindex('(USER=',line) <> 0 then substring(line,charindex('(USER=',line) + 6,charindex(')',line,charindex('(USER=',line) + 6) - charindex('(USER=',line) - 6)
              else ''
         end as [USER]
       , case when charindex('(HOST=',line) <> 0 then substring(line,charindex('(HOST=',line) + 6,charindex(')',line,charindex('(HOST=',line) + 6) - charindex('(HOST=',line) - 6)
              else ''
         end as [HOST]
       , case when charindex('(PROGRAM=',line) <> 0 then substring(line,charindex('(PROGRAM=',line) + 9,charindex(')',line,charindex('(PROGRAM=',line) + 9) - charindex('(PROGRAM=',line) - 9)
              else ''
         end as [PROGRAM]
       , line
from     #textfile
--where    charindex('<name>',line) <> 0
--         and line <> '      <name>All</name>'
order by 1;


select   *
from     #parsed
where    ( [USER] <> '' and HOST <> '' AND PROGRAM <> '')
         AND [USER] NOT IN ('srvcoemagent.na','james.lutsey.admin','dave.dunn')
order by entry_time;


/*
-- clean up
if object_id(N'tempdb..#textfile',N'u') is not null drop table #textfile;
go
*/