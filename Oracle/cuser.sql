set echo off
set feedback off
set verify off
set define "&"
set linesize 300
set serveroutput on format wrapped
set trimout on

prompt ;
prompt substitution variable 1 is for USERNAME
column myusername new_value USERNAME noprint;
select '&1' myusername from dual;

DECLARE
	l_username                    varchar2(128);
	l_account_status              varchar2(32);
	l_lock_date                   date;
	l_expiry_date                 date;
	l_default_tablespace          varchar2(30);
	l_temporary_tablespace        varchar2(30);
	l_created                     date;
	l_profile                     varchar2(128);
	l_last_login                  timestamp(9) with time zone;
	l_password_grace_time         number(14,5);
	l_qty                         number(1);
BEGIN
	-- check if the user exists
	select count(*) into l_qty from dba_users where username=upper('&&USERNAME');
	IF l_qty=0 THEN
		dbms_output.put_line(chr(10)||'Username, &&USERNAME, does not exist'||chr(10));
		return;
	END IF;

	-- get the data about the user
	select u.username
	     , u.account_status
	     , u.lock_date
	     , u.expiry_date
	     , u.default_tablespace
	     , u.temporary_tablespace
	     , u.created
	     , u.profile
	     , u.last_login
	     , case p.limit when 'UNLIMITED' then -1
	                    else                  to_number(p.limit)
	       end
	into   l_username
	     , l_account_status
	     , l_lock_date
	     , l_expiry_date
	     , l_default_tablespace
	     , l_temporary_tablespace
	     , l_created
	     , l_profile
	     , l_last_login
	     , l_password_grace_time
	from   dba_users u
	join   dba_profiles p on p.profile=u.profile
	where  u.username=upper('&&USERNAME')
	       and p.resource_name='PASSWORD_GRACE_TIME';

	-- if the we have passed the expiry date, but the user has not tried to
	-- log in, the account status will not indicate that the password has expired
	-- here we check for that and update the status accordingly
	IF instr(l_account_status,'EXPIRED')=0 THEN
		IF l_expiry_date + l_password_grace_time < sysdate AND l_password_grace_time>=0 THEN
			IF l_account_status='OPEN' THEN
				l_account_status := 'EXPIRED';
			ELSE
				l_account_status := 'EXPIRED and '||l_account_status;
			END IF;
		ELSIF l_expiry_date < sysdate THEN
			IF l_account_status='OPEN' THEN
				l_account_status := 'EXPIRED(GRACE)';
			ELSE
				l_account_status := 'EXPIRED(GRACE) and '||l_account_status;
			END IF;
		END IF;
	END IF;

	-- set the expiry date to include the grace time
	if instr(l_account_status,'GRACE')>0 THEN
		l_expiry_date := l_expiry_date + l_password_grace_time;
	END IF;

	-- display results
	dbms_output.put_line('---------------------------------------------------------');
	dbms_output.put_line('USERNAME           : '||l_username);
	dbms_output.put_line('ACCOUNT STATUS     : '||l_account_status);
	dbms_output.put_line('EXPIRY DATE        : '||to_char(l_expiry_date,'YYYY-MM-DD HH24:MI:SS'));
	dbms_output.put_line('LOCK_DATE          : '||to_char(l_lock_date,'YYYY-MM-DD HH24:MI:SS'));
	dbms_output.put_line('LAST LOGIN         : '||to_char(l_last_login,'YYYY-MM-DD HH24:MI:SS'));
	dbms_output.put_line('PROFILE            : '||l_profile);
	dbms_output.put_line('DEFAULT TABLESPACE : '||l_default_tablespace);
	dbms_output.put_line('TEMP TABLESPACE    : '||l_temporary_tablespace);
	dbms_output.put_line('CREATED            : '||to_char(l_created,'YYYY-MM-DD HH24:MI:SS'));
	dbms_output.put_line('---------------------------------------------------------');
END;
/

undefine USERNAME
undefine 1

set feedback on