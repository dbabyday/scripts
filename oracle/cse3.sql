set pages 70

column ora_login_user format a20
column host format a30
column module format a35
column ora_server_error_msg format a100
column sql format a100

select
          id
        , error_date
        , ora_login_user
        , host
        , module
        , ora_server_error_msg
        , sql
from      sys.server_errors
--where   ora_server_error_msg like 'ORA-00001: unique constraint%PRODDTA.F5530269_PK%'
where     ora_login_user in ('JDEARC','ARCHIVE_READER_SVC')
          and sql not like '%V$PARAMETER%'
order by  error_date ;
-- fetch next 50 rows only;