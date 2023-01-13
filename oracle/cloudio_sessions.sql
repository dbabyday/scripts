
/*

update ca.exit_loop set flag='N';
update ca.exit_loop set flag='Y';

select * from ca.cloudio_sessions order by entry_time desc fetch next 10 rows only;

*/



declare
	l_entry_time date;
	l_xxapps_sessions number;
	l_xxapps_sessions_prev number;
	l_xxcloudio_sessions number;
	l_xxcloudio_sessions_prev number;
	l_exit_flag char(1);
	l_qty number;
begin
	while 1=1
	loop
		select count(*)
		into   l_qty
		from   ca.cloudio_sessions;

		if l_qty=0 then
			l_xxapps_sessions_prev := -1;
			l_xxcloudio_sessions_prev := -1;
		else
			select nvl(xxapps_sessions,0), nvl(xxcloudio_sessions,0)
			into   l_xxapps_sessions_prev, l_xxcloudio_sessions_prev
			from   ca.cloudio_sessions
			where  entry_time=(select max(entry_time) from ca.cloudio_sessions);
		end if;

		select sysdate, count(*) 
		into   l_entry_time, l_xxapps_sessions
		from   v$session 
		where  username='XXAPPS';

		select count(*) 
		into   l_xxcloudio_sessions
		from   v$session 
		where  username='XXCLOUDIO';

		if 
			l_xxapps_sessions <> l_xxapps_sessions_prev 
			or l_xxcloudio_sessions <> l_xxcloudio_sessions_prev 
		then
			insert into ca.cloudio_sessions (entry_time, xxapps_sessions, xxcloudio_sessions)
			values (l_entry_time, l_xxapps_sessions, l_xxcloudio_sessions);	

			commit;
		end if;

		select flag
		into   l_exit_flag
		from   ca.exit_loop
		fetch next 1 rows only;

		if l_exit_flag='Y' then
			exit;
		end if;

		dbms_session.sleep(15);
	end loop;
end;
/
