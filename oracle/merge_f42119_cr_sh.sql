set echo off feedback off serveroutput on timing off trimout on trimspool on linesize 40
spool merge_f42119.sh

declare
    i     number(38)   := 0;
    j     number(38)   := 10000;
    k     number(38)   := 10000;
    top   number(38)   := 18000000;
    line1 varchar2(50) := 'sqlplus "/ as sysdba" << EOF';
    line2 varchar2(50) := '';
    line3 varchar2(50) := 'EOF';
begin
    while j<=top
    loop
        line2 := '@merge_f42119.sql '||to_char(i)||' '||to_char(j);

        dbms_output.put_line(line1);
        dbms_output.put_line(line2);
        dbms_output.put_line(line3);
        dbms_output.put_line(chr(10));

        i := i+k;
        j := j+k;
    end loop;
end;
/

spool off


