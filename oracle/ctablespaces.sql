set echo off
set linesize 300
set pagesize 100

col "%_USED"        format 999
col "%_MAX"         format 999
col contents        format a9
col free_gb         format 999,999
col max_free_gb     format 999,999.99
col maxsize_gb      format 999,999
col size_gb         format 999,999
col tablespace_name format a20
col used_gb         format 999,999

-- tablespaces and their datafiles
select          a.tablespace_name
              , a.contents
              , round(c.total_bytes/1024/1024/1024,0) size_gb
              , case when e.used_bytes is null then 0
                     else round(e.used_bytes/1024/1024/1024,0)
                end used_gb
              , case when g.free_bytes is null then 0
                     else round(g.free_bytes/1024/1024/1024,0)
                end free_gb
              , case when e.used_bytes is null then 0
                     else round(e.used_bytes/c.total_bytes*100,0)
                end "%_USED"
              , round(c.total_maxbytes/1024/1024/1024,0) maxsize_gb
              , case when e.used_bytes is null then round((c.total_maxbytes-0)/1024/1024/1024,2)
                     else round((c.total_maxbytes-e.used_bytes)/1024/1024/1024,2)
                end max_free_gb
              , case when e.used_bytes is null then 0
                     else round(e.used_bytes/c.total_maxbytes*100,0)
                end "%_MAX"
              , ceil(((case when e.used_bytes is null then 0 else e.used_bytes end) / 0.75 - c.total_maxbytes) / 32/1024/1024/1024) add_files
from            dba_tablespaces a
join            (  select   b.tablespace_name
                          , sum(b.bytes) total_bytes
                          , sum(  case when b.maxbytes=0 then b.bytes
                                       else b.maxbytes
                                  end  ) total_maxbytes
                   from     dba_data_files b
                   group by b.tablespace_name
                ) c on c.tablespace_name = a.tablespace_name
left outer join (  select   d.tablespace_name
                          , sum(d.bytes) used_bytes
                   from     dba_extents d
                   group by d.tablespace_name  
                ) e on e.tablespace_name = a.tablespace_name
left outer join (  select   sum(f.bytes) free_bytes
                          , f.tablespace_name
                   from     dba_free_space f
                   group by f.tablespace_name  
                ) g on g.tablespace_name = a.tablespace_name
union all
-- temp tablespaces and their tempfiles
select          k.tablespace_name
              , k.contents
              , round(k.total_bytes / 1024 / 1024 / 1024, 0) size_gb
              , case when m.total_used_blocks is null then 0
                     else round(m.total_used_blocks * k.block_size / 1024 / 1024 / 1024, 0)
                end used_gb
              , case when m.total_used_blocks is null then round((k.total_bytes - 0 * k.block_size) / 1024 / 1024 / 1024, 0)
                     else round((k.total_bytes - m.total_used_blocks * k.block_size) / 1024 / 1024 / 1024, 0)
                end free_gb
              , case when m.total_used_blocks is null then 0
                     else round(m.total_used_blocks * k.block_size / k.total_bytes * 100, 0)
                end "%_USED"
              , round(sum(k.total_maxbytes) / 1024 / 1024 / 1024, 0) maxsize_gb
              , case when m.total_used_blocks is null then round((sum(k.total_maxbytes) - 0 * k.block_size) / 1024 / 1024 / 1024, 2)
                     else round((sum(k.total_maxbytes) - m.total_used_blocks * k.block_size) / 1024 / 1024 / 1024, 2)
                end max_free_gb
              , case when m.total_used_blocks is null then 0
                     else round((m.total_used_blocks * k.block_size / sum(k.total_maxbytes)) / 1024 / 1024 / 1024, 0)
                end "%_MAX"
              , case when m.total_used_blocks is null then 0
                     else ceil((m.total_used_blocks * k.block_size / 0.75 - sum(k.total_maxbytes)) / 32/1024/1024/1024)
                end add_files
from            (  select h.tablespace_name
                        , h.contents
                        , j.block_size
                        , sum(j.bytes) total_bytes
                        , sum(case when i.maxbytes=0 then 32*1024*1024*1024 else i.maxbytes end) total_maxbytes
                   from dba_tablespaces h
                   join dba_temp_files  i on i.tablespace_name=h.tablespace_name
                   join v$tempfile      j on j.name=i.file_name
                   group by h.tablespace_name
                          , h.contents
                          , j.block_size
                ) k
left join       (  select   l.tablespace_name
                          , sum(l.used_blocks) total_used_blocks
                   from     v$sort_segment l
                   group by l.tablespace_name
                ) m on m.tablespace_name=k.tablespace_name
group by        k.tablespace_name
              , k.contents
              , k.total_bytes
              , k.block_size
              , m.total_used_blocks
order by        "%_MAX" desc
-- order by        tablespace_name
/



