-- select   compression
--        , compress_for
--        , count(*) 
-- from     dba_tables
-- group by compression
--        , compress_for 
-- order by compression
--        , compress_for;



set echo off feedback on

col compression format a11
col compress_for format a12
col owner format a10
col qty format 99999999999

select   compression
       , compress_for
       , owner
       , count(*) as qty
from     sys.dba_tables
where    compression = 'ENABLED'
         and compress_for = 'ADVANCED'
group by compression
       , compress_for
       , owner
order by owner;

