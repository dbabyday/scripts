set linesize 500
set pagesize 500
set echo off

col datbase_name  format a20
col display_value format a13
col name          format a20
col mb            format 999,999
col gb            format 999.9
col sga_free_mb   format 999,999
col sga_used_mb   format 999,999

prompt ;
prompt ;
prompt ;

select name datbase_name 
from   v$database;

prompt ;
prompt ;
prompt -------------------------------------------;
prompt --// MEMORY PARAMETERS                 //--;
prompt -------------------------------------------;

select   name
       , display_value
from     v$parameter
where    lower(name) like 'memory%'
         or lower(name) like '_ga%'
order by name;

prompt ;
prompt ;
prompt -------------------------------------------;
prompt --// SGA                               //--;
prompt -------------------------------------------;

select   name
       , round(value/1024/1024/1024,1) gb
from     v$parameter 
where    name in (   'sga_max_size'
                   , 'sga_target'  )
union all
select 'sga_used'           name
     , round(sum(bytes)/1024/1024/1024,1) gb
from   v$sgastat
where  name != 'free memory'
union all
select 'sga_free'           name
     , round(sum(bytes)/1024/1024/1024,1) gb
from   v$sgastat where name = 'free memory';

break on report
compute sum label total of total_gb used_gb free_gb on report

with 
         total_mem as (
              select   case when pool is null then name else pool end pool
                     , sum(bytes) bytes
              from     v$sgastat
              group by case when pool is null then name else pool end
         )
       , used_mem as (
              select   case when pool is null then name else pool end pool
                     , sum(bytes) bytes
              from     v$sgastat
              where    name<>'free memory'
              group by case when pool is null then name else pool end
         )
       , free_mem as (
              select   case when pool is null then name else pool end pool
                     , sum(bytes) bytes
              from     v$sgastat
              where    name='free memory'
              group by case when pool is null then name else pool end
         )
select 
         t.pool
       , round(t.bytes/1024/1024/1024,1) total_gb
       , round(u.bytes/1024/1024/1024,1) used_gb
       , round(f.bytes/1024/1024/1024,1) free_gb
from
       total_mem t
left join
       used_mem u on u.pool=t.pool
left join
       free_mem f on f.pool=t.pool
order by
       t.bytes desc;

clear computes
clear breaks


prompt ;
prompt ;
prompt -------------------------------------------;
prompt --// PGA                               //--;
prompt -------------------------------------------;

select   name
       , round(value/1024/1024/1024,1) gb
from     v$parameter 
where    name in ('pga_aggregate_target','pga_aggregate_limit')
union all
select   name
       , round(value/1024/1024/1024,1) gb 
from     v$pgastat
where    name in ('total PGA allocated','total PGA inuse')
order by name;

prompt ;
prompt ;
prompt ;

clear columns

