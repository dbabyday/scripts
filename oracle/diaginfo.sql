set linesize 32767
set pagesize 50000

col name format a30
col value format a70

select name, value from v$diag_info;
