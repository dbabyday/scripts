--
-- Copyright (c) 1988, 2005, Oracle.  All Rights Reserved.
--
-- NAME
--   glogin.sql
--
-- DESCRIPTION
--   SQL*Plus global login "site profile" file
--
--   Add any SQL*Plus commands here that are to be executed when a
--   user starts SQL*Plus, or uses the SQL*Plus CONNECT command.
--
-- USAGE
--   This script is automatically run
--

-- no need to display what we are doing
set termout off

-- sqlplus settings
set history on
set linesize 500
set pagesize 50
set long 2000000
set serveroutput on format wrapped
set trimout on
set trimspool on
set feedback on
set echo off
set verify off
set sqlblanklines on
set time off

-- set sqlprompt
define _db_name;
define _session_user;
define _sid;
column db_name      new_value _db_name      noprint;
column session_user new_value _session_user noprint;
column sid          new_value _sid          noprint;
select sys_context('userenv','con_name') db_name
     , lower(sys_context('userenv','session_user')) session_user
     , sys_context('userenv','sid') sid
from   dual;     
set sqlprompt '&_db_name SQL> ';
undefine _db_name;
undefine _session_user;
undefine _sid;

-- format date and times
alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';
-- alter session set nls_timestamp_format='YYYY-MM-DD HH24:MI:SS';

-- remove any column settings we made in here
clear columns

-- set column lengths
column name_col_plus_show_param format a43   -- for "show parameter"
column value_col_plus_show_param format a92  -- for "show parameter"
column stmt format a400

-- start showing output again
set termout on
