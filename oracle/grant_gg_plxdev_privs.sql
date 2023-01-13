set serveroutput on format wrapped
begin
	for x in (
		with my_role_tables as (
			select owner
			     , table_name
			from   dba_tab_privs
			where  grantee='PLXDEV'
		)
		select    'grant select on '||t.owner||'.'||t.table_name||' to plxdev' grant_stmt
		from      dba_tables t
		left join my_role_tables r on r.owner=t.owner and r.table_name=t.table_name
		where     r.table_name is null
		          and t.owner in ('PRODCTL','PRODDTA')
	)
	loop
		dbms_output.put_line(x.grant_stmt);
		execute immediate x.grant_stmt;
	end loop;
end;
/