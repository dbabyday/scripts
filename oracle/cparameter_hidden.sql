declare
	l_parameter             varchar2(200) := '';
	l_defalut_value         varchar2(200) := '';
	l_session_value         varchar2(200) := '';
	l_instance_value        varchar2(200) := '';
	l_is_session_modifiable varchar2(200) := '';
	l_is_system_modifiable  varchar2(200) := '';
begin
	dbms_output.put_line(chr(10));
	dbms_output.put_line('-----------------------------------------------');

	for x in (
		SELECT
			  a.ksppinm  "PARAMETER"
			, b.KSPPSTDF "DEFAULT_VALUE"
			, b.ksppstvl "SESSION_VALUE"
			, c.ksppstvl "INSTANCE_VALUE"
			, decode(bitand(a.ksppiflg/256,1),1,'TRUE','FALSE') IS_SESSION_MODIFIABLE
			, decode(bitand(a.ksppiflg/65536,3),1,'IMMEDIATE',2,'DEFERRED',3,'IMMEDIATE','FALSE') IS_SYSTEM_MODIFIABLE
		FROM
			  x$ksppi a
			, x$ksppcv b
			, x$ksppsv c
		WHERE
			a.indx = b.indx
			AND a.indx = c.indx
			AND a.ksppinm LIKE '%&PARAMETER_NAME_LIKE%'
	)
	loop
		dbms_output.put_line('Parameter            : '||x.PARAMETER);
		dbms_output.put_line('Default Value        : '||x.DEFAULT_VALUE);
		dbms_output.put_line('Session Value        : '||x.SESSION_VALUE);
		dbms_output.put_line('Instance Value       : '||x.INSTANCE_VALUE);
		dbms_output.put_line('IS_SESSION_MODIFIABLE: '||x.IS_SESSION_MODIFIABLE);
		dbms_output.put_line('IS_SYSTEM_MODIFIABLE : '||x.IS_SYSTEM_MODIFIABLE);
		dbms_output.put_line('-----------------------------------------------');
	end loop;

	dbms_output.put_line(chr(10));
end;
/