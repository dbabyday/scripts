/*

https://github.com/dbabyday
Warranty: The software is provided "AS IS", without warranty of any kind

Name: cbadusers.sql
Description: See users that do not have a status of "OPEN"

*/


set linesize 32767
set pagesize 50000

column username       format a30
column profile        format a20
column account_status format a30
column created        format a12
column lock_date      format a21
column expire_date    format a21

select   username
       , profile
       , account_status
       , to_char(created,    'YYYY-MM-DD')            created
       , to_char(lock_date,  'YYYY-MM-DD HH24:MI:SS') lock_date
       , to_char(expiry_date,'YYYY-MM-DD HH24:MI:SS') expire_date
from     dba_users
where    account_status<>'OPEN'
order by username;

undefine USERNAME;
clear columns

