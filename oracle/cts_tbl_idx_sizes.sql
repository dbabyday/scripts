set define "&" feedback off

compute sum of gb on report
compute sum of mb on report
break on report


column num_rows format 999,999,999,999
column segment_name format a40
column mb format 999,999,999
column gb format 999,999.9


prompt substitution variable 1 is for Tablespace Name
column my_tablespace_name new_value _TABLESPACE_NAME noprint;
select '&1' my_tablespace_name from dual;



select   s.segment_type
       , s.segment_name
       , s.tablespace_name
       , round(sum(s.bytes)/1024/1024/1024,1) gb
       , round(sum(s.bytes)/1024/1024,0) mb
from     dba_segments s
where    s.tablespace_name='&&_TABLESPACE_NAME'
         and s.segment_type like '%TABLE%'
group by s.segment_type
       , s.segment_name
       , s.tablespace_name
union all
select   s.segment_type
       , s.segment_name
       , s.tablespace_name
       , round(sum(s.bytes)/1024/1024/1024,1) gb
       , round(sum(s.bytes)/1024/1024,0) mb
from     dba_segments s
join     dba_indexes  i on i.owner=s.owner and i.index_name=s.segment_name
where    s.tablespace_name='&&_TABLESPACE_NAME'
         and s.segment_type like '%INDEX%'
group by s.segment_type
       , s.segment_name
       , s.tablespace_name
union all
select   s.segment_type
       , s.segment_name
       , s.tablespace_name
       , round(sum(s.bytes)/1024/1024/1024,1) gb
       , round(sum(s.bytes)/1024/1024,0) mb
from     dba_segments s
join     dba_lobs  l on l.owner=s.owner and l.segment_name=s.segment_name
where    s.tablespace_name='&&_TABLESPACE_NAME'
         and s.segment_type like '%LOB%'
group by s.segment_type
       , s.segment_name
       , s.tablespace_name
order by mb;





/*
column mb format 999,999,999

select   segment_type
       , segment_name
       , round(sum(bytes)/1024/1024,0) mb
from     dba_segments
         where owner=upper('&&OWNER')
               and segment_name=upper('&&TABLE_NAME')
               and segment_type like '%TABLE%'
group by segment_type
       , segment_name
union all
select   s.segment_type
       , s.segment_name
       , round(sum(s.bytes)/1024/1024,0) mb
from     dba_segments s
join     dba_indexes  i on i.owner=s.owner and i.index_name=s.segment_name
where    i.table_owner=upper('&&OWNER')
         and i.table_name=upper('&&TABLE_NAME')
         and s.segment_type like '%INDEX%'
group by s.segment_type
       , s.segment_name
order by segment_type desc
       , mb;
*/



clear breaks;

undefine 1
undefine _TABLESPACE_NAME