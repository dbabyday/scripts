set linesize 500

col owner format a15
col db_link format a20
col username format a20
col host format a20

select   owner
       , db_link
       , username
       , host
       , created
from     dba_db_links
order by db_link;

