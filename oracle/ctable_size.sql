set define "&" feedback off

compute sum of gb on report
compute sum of mb on report
break on report


column num_rows format 999,999,999,999
column segment_name format a40
column mb format 999,999,999
column gb format 999,999.9


prompt substitution variable 1 is for OWNER
column myowner new_value OWNER noprint;
select '&1' myowner from dual;

prompt substitution variable 2 is for TABLE_NAME
column mytablename new_value TABLE_NAME noprint;
select '&2' mytablename from dual;


select num_rows
from   dba_tables
where  owner=upper('&&OWNER')
       and table_name=upper('&&TABLE_NAME');

select   s.segment_type
       , s.segment_name
       , s.tablespace_name
       , round(sum(s.bytes)/1024/1024/1024,1) gb
       , round(sum(s.bytes)/1024/1024,0) mb
from     dba_segments s
         where s.owner=upper('&&OWNER')
               and s.segment_name=upper('&&TABLE_NAME')
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
where    i.table_owner=upper('&&OWNER')
         and i.table_name=upper('&&TABLE_NAME')
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
where    l.owner=upper('&&OWNER')
         and l.table_name=upper('&&TABLE_NAME')
         and s.segment_type like '%LOB%'
group by s.segment_type
       , s.segment_name
       , s.tablespace_name
order by segment_type desc
       , mb;





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

undefine OWNER
undefine TABLE_NAME