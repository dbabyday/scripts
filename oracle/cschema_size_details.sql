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



select   s.segment_name tbl_name
       , s.tablespace_name
       , round(sum(s.bytes)/1024/1024/1024,1) gb
       , round(sum(s.bytes)/1024/1024,0) mb
from     dba_segments s
         where s.owner=upper('&&OWNER')
               and s.segment_type='TABLE'
group by s.segment_type
       , s.segment_name
       , s.tablespace_name
union all
select   i.table_name tbl_name
       , s.tablespace_name
       , round(sum(s.bytes)/1024/1024/1024,1) gb
       , round(sum(s.bytes)/1024/1024,0) mb
from     dba_segments s
join     dba_indexes  i on i.owner=s.owner and i.index_name=s.segment_name
where    i.table_owner=upper('&&OWNER')
         and i.table_name=upper('&&TABLE_NAME')
         and s.segment_type like '%INDEX%'
group by s.segment_type
       , i.table_name
       , s.tablespace_name
union all
select   l.table_name tbl_name
       , s.tablespace_name
       , round(sum(s.bytes)/1024/1024/1024,1) gb
       , round(sum(s.bytes)/1024/1024,0) mb
from     dba_segments s
join     dba_lobs  l on l.owner=s.owner and l.segment_name=s.segment_name
where    l.owner=upper('&&OWNER')
         and l.table_name=upper('&&TABLE_NAME')
         and s.segment_type like '%LOB%'
group by l.table_name
       , s.tablespace_name
order by mb;




SELECT
 (SELECT SUM(S.BYTES)                                                                                                 -- The Table Segment size
  FROM DBA_SEGMENTS S
  WHERE S.OWNER = UPPER('&SCHEMA') AND
       (S.SEGMENT_NAME = UPPER('&TABNAME'))) +
 (SELECT SUM(S.BYTES)                                                                                                 -- The Lob Segment Size
  FROM DBA_SEGMENTS S, DBA_LOBS L
  WHERE S.OWNER = UPPER('&SCHEMA') AND
       (L.SEGMENT_NAME = S.SEGMENT_NAME AND L.TABLE_NAME = UPPER('&TABNAME') AND L.OWNER = UPPER('&SCHEMA'))) +
 (SELECT SUM(S.BYTES)                                                                                                 -- The Lob Index size
  FROM DBA_SEGMENTS S, DBA_INDEXES I
  WHERE S.OWNER = UPPER('&SCHEMA') AND
       (I.INDEX_NAME = S.SEGMENT_NAME AND I.TABLE_NAME = UPPER('&TABNAME') AND INDEX_TYPE = 'LOB' AND I.OWNER = UPPER('&SCHEMA')))
  "TOTAL TABLE SIZE"
FROM DUAL;




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