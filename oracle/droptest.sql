set serveroutput on

-- drop backup table if exists
begin
    execute immediate 'drop table appworx.backup_aw_module_sched_v8';
    dbms_output.put_line('table dropped: appworx.backup_aw_module_sched_v8');
exception
    when others then dbms_output.put_line('table does not exist: appworx.backup_aw_module_sched_v8');
end;
/




