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

-- select          t.tablespace_name
--               , df.file_name
--               , df.bytes/1024/1024 size_mb
--               , case when e.used_bytes is null then 0
--                      else round(e.used_bytes/1024/1024,0)
--                 end used_mb
--               , case when f.free_bytes is null then 0
--                      else round(f.free_bytes/1024/1024,0)
--                 end free_mb
--               , case when e.used_bytes is null then 0
--                      else round(e.used_bytes/df.bytes*100,0)
--                 end "%_USED"
--               , df.increment_by*t.block_size/1024/1024 increment_by_mb
--               , df.maxbytes/1024/1024 max_mb
--               , case when df.maxbytes = 0 then (df.bytes-e.used_bytes)/1024/1024
--                      else (df.maxbytes-e.used_bytes)/1024/1024
--                 end  max_free
--               , case when df.maxbytes = 0 then round(e.used_bytes/df.bytes*100,0)
--                      else round(e.used_bytes/df.maxbytes*100,0)
--                 end "%_MAX"
--               , df.autoextensible
-- from            dba_data_files                df
-- join            dba_tablespaces t on t.tablespace_name = df.tablespace_name
-- left outer join (  select file_id,
--                           sum(bytes) used_bytes
--                    from dba_extents
--                    group by file_id  )        e on e.file_id = df.file_id
-- left outer join (  select sum(bytes) free_bytes,
--                                  file_id
--                           from dba_free_space
--                           group by file_id  ) f on f.file_id  = df.file_id
-- order by        t.tablespace_name
--               , df.file_name;




select    c.tablespace_name
        , b.file_name
        , b.bytes / 1024 / 1024 / 1024 size_gb
        , sum(d.bytes) / 1024 / 1024 / 1024 used_gb
        , (b.bytes - sum(d.bytes)) / 1024 / 1024 / 1024 free_gb
        , 'to do' "%_USED"
        , (b.increment_by*c.block_size) / 1024 / 1024 / 1024 autoextend_gb
        , b.maxbytes  / 1024 / 1024 / 1024 max_gb
        , 'to do' "%_MAX"
        , b.autoextensible
from      v$tempfile        a
join      dba_temp_files    b on b.file_name=a.name
join      dba_tablespaces   c on c.tablespace_name=b.tablespace_name
left join v$temp_extent_map d on d.file_id=a.file#
group by  c.tablespace_name
        , b.file_name
        , b.bytes
        , b.increment_by
        , c.block_size
        , b.maxbytes
        , b.autoextensible
order by c.tablespace_name
       , b.file_name;

-- select          h.tablespace_name
--               , round(l.total_bytes / 1024 / 1024 / 1024, 0) size_gb
--               , round(sum(h.used_blocks * l.block_size) / 1024 / 1024 / 1024, 0) used_gb
--               , round((l.total_bytes - sum(h.used_blocks * l.block_size)) / 1024 / 1024 / 1024, 0) free_gb
--               , round(sum(h.used_blocks * l.block_size) / l.total_bytes * 100, 0) "%_USED"
--               , round(sum(l.total_maxbytes) / 1024 / 1024 / 1024, 0) maxsize_gb
--               , round((sum(l.total_maxbytes) - sum(h.used_blocks * l.block_size)) / 1024 / 1024 / 1024, 2) max_free_gb
--               , round((sum(h.used_blocks * l.block_size) / sum(l.total_maxbytes)) / 1024 / 1024 / 1024, 0) "%_MAX"
--               , ceil((sum(h.used_blocks * l.block_size) / 0.75 - sum(l.total_maxbytes)) / 32/1024/1024/1024) add_files
-- from            v$sort_segment h
-- join            (  select i.name tablespace_name
--                         , j.block_size
--                         , sum(j.bytes) total_bytes
--                         , sum(case when k.maxbytes=0 then 32*1024*1024*1024 else k.maxbytes end) total_maxbytes
--                    from v$tablespace    i
--                    join v$tempfile      j on j.ts#=i.ts#
--                    join dba_temp_files  k on k.file_name=j.name
--                    group by i.name
--                           , j.block_size
--                 ) l on l.tablespace_name=h.tablespace_name
-- group by        h.tablespace_name
--               , l.total_bytes
-- order by        "%_MAX" desc

-- clear columns


