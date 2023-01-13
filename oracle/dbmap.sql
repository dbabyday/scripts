SET ECHO OFF LINES 300 PAGES 50000 HEAD OFF VERIFY OFF FEEDBACK OFF
ttitle -
center  'Database File Map'  skip 2

SET EMBEDDED ON

SELECT 'Date -  '||TO_CHAR(SYSDATE,'Day Ddth Month YYYY     HH24:MI:SS'),
       'Database Name -  '||value nline,'Username      -  '||USER
FROM  v$parameter
WHERE name = 'db_name';
--
SELECT * FROM v$version;
--
SET EMBEDDED OFF HEAD ON
PROMPT
col file_type_sort  noprint
col file_type       format a14 heading 'Type'       justify c
col file_name       format a45 heading 'File'       justify c word
col name       format a45 heading 'File'       justify c word
col file_size       format a12 heading 'Size (MB)' justify c
col bytes       format a12 heading 'Size (MB)' justify c
col tablespace_name format a12 heading 'Tablespace' justify c trunc
col extent_management format a10 heading 'Extent Mgt' justify c trunc
col status          format a10 heading 'Status'     justify c
set pages 200 lines 132 feedback off
break -
  on file_type duplicates skip 0

select
  1           file_type_sort,
  'CONTROL FILE'   file_type,
  name        file_name,
  ''          file_size,
  ''          tablespace_name,
  ''          extent_management,
  ''          autoextensible,
  status      status
from
  v$controlfile
union
select
  2              file_type_sort,
  'ARCHIVE_DEST' file_type,
  destination    file_name,
  ''             file_size,
  ''             tablespace_name,
  ''          extent_management,
  ''          autoextensible,
  status         status
from
  v$archive_dest
where status != 'INACTIVE'
union
select
  3   file_type_sort,
  'REDO LOG FILE'   file_type,
  f.group#||':'||f.member file_name,
  rpad(to_char(round(l.bytes/1024/1024,1),'9,999,999.9'),12)    file_size,
  ''       tablespace_name,
  ''          extent_management,
  ''          autoextensible,
  l.status         status
from
  v$logfile f, v$log l
where f.group# = l.group#
union
select
  4                                      file_type_sort,
  'DATA FILE'                   file_type,
  a.file_name                                  file_name,
  rpad(to_char(round(a.bytes/1024/1024,1),'9,999,999.9'),12)    file_size,
  a.tablespace_name                            tablespace_name ,
  b.extent_management          extent_management,
  a.autoextensible          auto_extend,
  a.status                                     status
from
  dba_data_files a,
  dba_tablespaces b
where b.tablespace_name = a.tablespace_name
union
select
  5                                      file_type_sort,
  'TEMP FILE'                   file_type,
  a.name                                  file_name,
  rpad(to_char(round(a.bytes/1024/1024,1),'9,999,999.9'),12)    file_size,
  b.name                            tablespace_name ,
  ''          extent_management,
  ''          auto_extend,
  a.status                                     status
from
  v$tempfile a,
  v$tablespace b
where b.ts# = a.ts#
order by
  1,5,3
/
ttitle off;
clear columns;
clear breaks;
