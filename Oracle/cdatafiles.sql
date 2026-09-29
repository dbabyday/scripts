set linesize 300
set pagesize 100

col "%_MAX"         format 999
col "%_USED"        format 999
col autoextensible  format a14
col file_name       format a50
col free_mb         format 999,999,999
col increment_by_mb format 999,999,999
col max_free        format 999,999,999
col max_mb          format 999,999,999
col size_mb         format 999,999,999
col tablespace_name format a20
col used_mb         format 999,999,999

select          t.tablespace_name
              , df.file_name
              , df.bytes/1024/1024 size_mb
              , case when e.used_bytes is null then 0
                     else round(e.used_bytes/1024/1024,0)
                end used_mb
              , case when f.free_bytes is null then 0
                     else round(f.free_bytes/1024/1024,0)
                end free_mb
              , case when e.used_bytes is null then 0
                     else round(e.used_bytes/df.bytes*100,0)
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
order by        t.tablespace_name
              , df.file_name;

clear columns


