set linesize 200
col owner format a30
col segment_name format a30
col gb format 999999.9

select   owner
       , segment_name
       , sum(bytes)/1024/1024/1024 as gb
from     dba_segments 
where    UPPER(owner)=UPPER('&owner')
         and UPPER(segment_name)=UPPER('&index_name')
group by owner
       , segment_name;

undefine owner
undefine index_name