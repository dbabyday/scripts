set linesize 300
set pagesize 100
set echo off
set feedback off

col parameter    format a25
col value        format a25
col datbase_name format a20
col name         format a20
col mb           format 999,999
col sga_free_mb  format 999,999
col sga_used_mb  format 999,999

prompt ;
prompt ;
prompt ;

select name datbase_name 
from   v$database;

select   parameter
       , value 
from     nls_database_parameters
where    parameter in (   'NLS_CHARACTERSET'
                        , 'NLS_NCHAR_CHARACTERSET'
                        , 'NLS_LANGUAGE'  )
union
select   name as paramter
       , value
from     v$parameter
where    name = 'db_block_size';

prompt ;
prompt ;
prompt -------------------------------------------;
prompt --// SGA                               //--;
prompt -------------------------------------------;

select   name
       , value/1024/1024 mb
from     v$parameter 
where    name in (   'sga_max_size'
                   , 'sga_target'  )
union all
select 'sga_used'           name
     , sum(bytes)/1024/1024 mb
from   v$sgastat
where  name != 'free memory'
union all
select 'sga_free'           name
     , sum(bytes)/1024/1024 mb
from   v$sgastat where name = 'free memory';

prompt ;
prompt ;
prompt -------------------------------------------;
prompt --// PGA                               //--;
prompt -------------------------------------------;

select   name
       , value/1024/1024 mb
from     v$parameter 
where    name = 'pga_aggregate_target'
union all
select   name
       , value/1024/1024 mb 
from     v$pgastat
where    name in ('total PGA allocated','total PGA inuse')
order by name;

prompt ;
prompt ;
prompt ;


clear columns
set feedback on
set echo on
