set linesize 300
set pagesize 100

col "%_USED"        format 999
col "%_MAX"         format 999
col free_gb         format 999,999
col max_free        format 999,999.99
col maxsize_gb      format 999,999
col size_gb         format 999,999
col tablespace_name format a20
col used_gb         format 999,999

select    t.tablespace_name
        , df.total_bytes/1024/1024/1024 size_gb
        , case when e.used_bytes is null then 0
               else round(e.used_bytes/1024/1024/1024,0)
          end used_gb
        , case when f.free_bytes is null then 0
               else round(f.free_bytes/1024/1024/1024,0)
          end free_gb
        , case when e.used_bytes is null then 0
               else round(e.used_bytes/df.total_bytes*100,0)
          end "%_USED"
        , round(df.total_maxbytes/1024/1024/1024,0) maxsize_gb
        , round((df.total_maxbytes-e.used_bytes)/1024/1024/1024,2) max_free
        , case when e.used_bytes is null then 0
               else round(e.used_bytes/df.total_maxbytes*100,0)
          end "%_MAX"
from      dba_tablespaces t
left join (  select   tablespace_name
                    , sum(bytes) total_bytes
                    , sum(  case when maxbytes=0 then bytes
                    	           else maxbytes
                    	      end  ) total_maxbytes
             from     dba_data_files
             group by tablespace_name  
          ) df on df.tablespace_name = t.tablespace_name
left join (  select   tablespace_name
                    , sum(bytes) used_bytes
             from     dba_extents
             group by tablespace_name  
          ) e on e.tablespace_name = t.tablespace_name
left join (  select   sum(bytes) free_bytes
                    , tablespace_name
             from     dba_free_space
             group by tablespace_name  
          ) f on f.tablespace_name = t.tablespace_name
where     e.used_bytes/df.total_maxbytes >= .9
order by  "%_MAX" desc
          --t.tablespace_name
/

exit;