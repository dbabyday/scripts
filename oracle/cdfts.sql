/*

	see datafiles for a specified tablespace

*/


set echo off
set linesize 500
set pagesize 100
set verify off

col "%_MAX"         format 999
col "%_USED"        format 999
col autoextensible  format a14
col file_name       format a50
col free_mb         format 999,999,999
col increment_by_mb format 999,999,999
col max_free        format 999,999,999
col max_mb          format 999,999,999
col size_gb         format 999999.9
col tablespace_name format a20
col used_gb         format 999999.9
col resize_stmt     format a100

set feedback off
prompt ;
prompt substitution variable 1 is for TABLESPACE_NAME
column my_tablespace_name new_value TABLESPACE_NAME noprint;
select '&1' my_tablespace_name from dual;
set feedback on


select          t.tablespace_name
              , df.file_name
              , round(df.bytes/1024/1024/1024,1) size_gb
              , case when e.used_bytes is null then 0
                     else round(e.used_bytes/1024/1024/1024,1)
                end used_gb
              , case when f.free_bytes is null then 0
                     else round(f.free_bytes/1024/1024,0)
                end free_mb
              , case when e.used_bytes is null then 0
                     else round((e.used_bytes/df.bytes)*100,0)
                end "%_USED"
              , df.increment_by*t.block_size/1024/1024 increment_by_mb
              , df.maxbytes/1024/1024 max_mb
              , case when df.maxbytes = 0 then (df.bytes-e.used_bytes)/1024/1024
                     else (df.maxbytes-e.used_bytes)/1024/1024
                end  max_free
              , case when df.maxbytes = 0 then round(e.used_bytes/df.bytes*100,0)
                     else round(e.used_bytes/df.maxbytes*100,0)
                end "%_MAX"
              , df.autoextensible
              , case when df.bytes>=32767*1024*1024 then ''
                     when df.bytes<32767*1024*1024 and e.used_bytes>=23808*1024*1024 then 'alter database datafile '''||df.file_name||''' resize 32767m;'||chr(10)||'alter database datafile '''||df.file_name||''' autoextend off;'
                     when e.used_bytes is not null and e.used_bytes>df.bytes*0.75 then 'alter database datafile '''||df.file_name||''' resize '||to_char(ceil(e.used_bytes/1024/1024/1024/0.75))||'g;'
                     else ''
                end resize_stmt
from            dba_data_files                df
join            dba_tablespaces t on t.tablespace_name = df.tablespace_name
left outer join (  select file_id,
                          sum(bytes) used_bytes
                   from dba_extents
                   group by file_id  )        e on e.file_id = df.file_id
left outer join (  select sum(bytes) free_bytes,
                                 file_id
                          from dba_free_space
                          group by file_id  ) f on f.file_id  = df.file_id
where           upper(t.tablespace_name) = upper('&&TABLESPACE_NAME')
order by        t.tablespace_name
              , df.file_name;


undefine 1
undefine TABLESPACE_NAME
clear columns


