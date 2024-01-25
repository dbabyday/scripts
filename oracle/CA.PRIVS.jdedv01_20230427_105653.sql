
  CREATE OR REPLACE EDITIONABLE PACKAGE "CA"."PRIVS" AS
	-- Purpose: Collection of procedures that will script out current privileges and manage default privileges.
	--
	-- Date        Name                  Object      Description of change
	-- ----------  --------------------  ----------  ----------------------------------------------------------------
	-- 2019-11-18  James Lutsey          obj         Initial creation
	-- 2019-11-18  James Lutsey          role        Initial creation
	-- 2019-11-18  James Lutsey          user        Initial creation
	-- 2020-12-04  James Lutsey          dflt        Initial creation
	-- 2020-12-07  James Lutsey          grant_dflt  Initial creation

	PROCEDURE dflt (
		  in_owner      IN ca.dflt_privs.owner%type default null
		, in_table_name IN varchar2                 default null );

	PROCEDURE grant_dflt (
		  out_checkTime OUT ca.missing_dflt_privs_granted.check_time%type );

	PROCEDURE obj (
		  in_owner IN sys.dba_tab_privs.owner%type      default null
		, in_obj   IN sys.dba_tab_privs.table_name%type default null );

	PROCEDURE role (
		in_role IN sys.dba_roles.role%type  default null );

	PROCEDURE user (
		in_username IN sys.dba_role_privs.grantee%type default null );
END privs;
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "CA"."PRIVS" AS
	PROCEDURE dflt (
		  in_owner      in ca.dflt_privs.owner%type default null
		, in_table_name in varchar2                 default null
	)
	AS
		l_db_name varchar2(63);
	BEGIN
		IF in_owner is null OR in_table_name is null THEN
			dbms_output.put_line(chr(10));
			dbms_output.put_line('SYNTAX: execute ca.script_dflt_privs(''<OWNER>'',''<TABLE_NAME>'';');
			dbms_output.put_line('NOTE: Parameters are case sensitive');
			dbms_output.put_line(chr(10));
			return;
		END IF;

		select case when sys_context('userenv','db_name') = sys_context('userenv','con_name') then '-- '||sys_context('userenv','db_name')
			        else '-- '||sys_context('userenv','db_name')||'.'||sys_context('userenv','con_name')
			   end
		into   l_db_name
		from   dual;
		dbms_output.put_line(l_db_name);

		FOR x IN (  select   case grantable when 'YES' THEN 'grant '||privilege||' on '||in_owner||'.'||in_table_name||' to '||grantee||' with grant option;'
		                                    else            'grant '||privilege||' on '||in_owner||'.'||in_table_name||' to '||grantee||';'
		                     end stmt
		            from     ca.dflt_privs
		            where    owner=in_owner
		            order by grantee
		                   , owner
		                   , privilege
		         )
		LOOP
			dbms_output.put_line(x.stmt);
		END LOOP;
	END dflt;




	PROCEDURE grant_dflt (
		out_checkTime OUT ca.missing_dflt_privs_granted.check_time%type )
	AS
		l_stmt varchar2(4000);
	BEGIN
		select sysdate into out_checkTime from dual;

		FOR x IN (  select    d.privilege
		                    , d.owner
		                    , t.table_name
		                    , d.grantee
		                    , d.grantable
		            from      dba_tables    t
		            join      ca.dflt_privs d on d.owner=t.owner
		            left join dba_tab_privs p on p.owner=d.owner and p.table_name=t.table_name and p.grantee=d.grantee and p.privilege=d.privilege and p.grantable=d.grantable
		            where     p.grantee is null
		         )
		LOOP
			IF x.grantable='YES' THEN
				l_stmt := 'grant '||x.privilege||' on "'||x.owner||'"."'||x.table_name||'" to "'||x.grantee||'" with grant option';
			ELSE
				l_stmt := 'grant '||x.privilege||' on "'||x.owner||'"."'||x.table_name||'" to "'||x.grantee||'"';
			END IF;

			execute immediate l_stmt;
			l_stmt :=         'insert into ca.missing_dflt_privs_granted (check_time, privilege, owner, table_name, grantee, grantable)'||chr(10);
			l_stmt := l_stmt||'values (to_date('''||to_char(out_checkTime,'YYYYMMDD HH24MISS')||''',''YYYYMMDD HH24MISS'')';
			l_stmt := l_stmt||', '''||x.privilege||'''';
			l_stmt := l_stmt||', '''||x.owner||'''';
			l_stmt := l_stmt||', '''||x.table_name||'''';
			l_stmt := l_stmt||', '''||x.grantee||'''';
			l_stmt := l_stmt||', '''||x.grantable||''')';
			execute immediate l_stmt;
		END LOOP;

		commit;
	END grant_dflt;




	PROCEDURE obj (
		  in_owner IN sys.dba_tab_privs.owner%type      default null
		, in_obj   IN sys.dba_tab_privs.table_name%type default null )
	AS
		obj_exists_1      number(38)     := 0;
		obj_exists_2      number(38)     := 0;
		owner_exists_1    number(38)     := 0;
		owner_exists_2    number(38)     := 0;
		stmt              varchar2(4000) := null;
	BEGIN
		----------------------------------------
		-- VERIFY INPUT                       --
		----------------------------------------

		IF in_owner is null OR in_obj is null THEN
			dbms_output.put_line(chr(10));
			dbms_output.put_line('SYNTAX:  execute ca.privs.obj(''<owner>'',''<object_name>'');');
			dbms_output.put_line('EXAMPLE: execute ca.privs.obj(''PRODDTA'',''F0911'');');
			dbms_output.put_line(chr(10));
			return;
		END IF;

		-- owners
		select count(1) into owner_exists_1 from sys.dba_tab_privs where owner=in_owner;
		select count(1) into owner_exists_2 from sys.dba_col_privs where owner=in_owner;

		IF owner_exists_1=0 AND owner_exists_2=0 THEN
			dbms_output.put_line(chr(10));
			dbms_output.put_line('ERROR: Owner, '||in_owner||', does not exist.');
			dbms_output.put_line('Note: this is a case-sensitive parameter. You can get owner names with the following queries...');
			dbms_output.put_line('select distinct owner from sys.dba_tab_privs order by owner;');
			dbms_output.put_line('select distinct owner from sys.dba_col_privs order by owner;');
			dbms_output.put_line(chr(10));
			return;
		END IF;

		-- objects
		select count(1) into obj_exists_1 from sys.dba_tab_privs where owner=in_owner and table_name=in_obj;
		select count(1) into obj_exists_2 from sys.dba_col_privs where owner=in_owner and table_name=in_obj;

		IF obj_exists_1=0 AND obj_exists_2=0 THEN
			dbms_output.put_line(chr(10));
			dbms_output.put_line('ERROR: Object, "'||in_owner||'"."'||in_obj||'", does not exist in the privileges tables.');
			dbms_output.put_line('Note: this is a case-sensitive parameter. You can get object names with the following queries...');
			dbms_output.put_line('select distinct table_name from sys.dba_tab_privs where owner='''||in_owner||''' order by table_name;');
			dbms_output.put_line('select distinct table_name from sys.dba_col_privs where owner='''||in_owner||''' order by table_name;');
			dbms_output.put_line(chr(10));
			return;
		END IF;



		----------------------------------------
		-- HEADER INFO                        --
		----------------------------------------

		dbms_output.put_line(chr(10));

		dbms_output.put_line('-- =====================================');

		dbms_output.put_line('-- Date: '||to_char(sysdate,'YYYY-MM-DD HH24:MI:SS'));

		select '-- Database: '||name into stmt from v$database;
		dbms_output.put_line(stmt);

		dbms_output.put_line('-- Object: "'||in_owner||'"."'||in_obj||'"');

		dbms_output.put_line('-- =====================================');



		----------------------------------------
		-- OBJECT PRIVS                       --
		----------------------------------------

		dbms_output.put_line(chr(10));
		dbms_output.put_line('-- object privleges');

		FOR s IN (  select   case when hierarchy='YES' and grantable='YES' then 'grant '||privilege||' on "'||owner||'"."'||table_name||'" to "'||grantee||'" with hierarchy option with grant option;'
				                  when hierarchy='YES' and grantable='NO'  then 'grant '||privilege||' on "'||owner||'"."'||table_name||'" to "'||grantee||'" with hierarchy option;'
				                  when hierarchy='NO'  and grantable='YES' then 'grant '||privilege||' on "'||owner||'"."'||table_name||'" to "'||grantee||'" with grant option;'
				                  else 'grant '||privilege||' on "'||owner||'"."'||table_name||'" to "'||grantee||'";'
				             end stmt
				    from     sys.dba_tab_privs
				    where    owner=in_owner
				             and table_name=in_obj
				    order by owner
				           , grantee
				           , privilege
				 )
		LOOP
			dbms_output.put_line(s.stmt);
		END LOOP;



		----------------------------------------
		-- COLUMN PRIVS                       --
		----------------------------------------

		dbms_output.put_line(chr(10));
		dbms_output.put_line('-- column privleges');

		FOR s IN (  select   case when grantable='YES' then 'grant '||privilege||' ("'||column_name||'") on "'||owner||'"."'||table_name||'" to "'||grantee||'" with grant option;'
				                  else 'grant '||privilege||' ("'||column_name||'") on "'||owner||'"."'||table_name||'" to "'||grantee||'";'
				             end stmt
				    from     sys.dba_col_privs
				    where    owner=in_owner
				             and table_name=in_obj
				    order by grantee
				           , column_name
				           , privilege
				 )
		LOOP
			dbms_output.put_line(s.stmt);
		END LOOP;

		dbms_output.put_line(chr(10));
	END obj;



	PROCEDURE role (
		in_role IN sys.dba_roles.role%type  default null )
	AS
		auth_type      varchar2(11)   := null;
		pw_vals_exists number(38)     := 0;
		role_exists    number(38)     := 0;
		stmt           varchar2(4000) := null;
	BEGIN
		----------------------------------------
		-- VERIFY INPUT                       --
		----------------------------------------

		IF in_role is null THEN
			dbms_output.put_line(chr(10));
			dbms_output.put_line('SYNTAX:  execute ca.privs.role(''<role>'');');
			dbms_output.put_line('EXAMPLE: execute ca.privs.role(''TROLE01'');');
			dbms_output.put_line(chr(10));
			return;
		END IF;

		select count(1) into role_exists from sys.dba_roles where role=in_role;

		IF role_exists=0 THEN
			dbms_output.put_line(chr(10));
			dbms_output.put_line('ERROR: Role, '||in_role||', does not exist.');
			dbms_output.put_line('Note: this is a case-sensitive parameter. Use the following query to find roles...');
			dbms_output.put_line('select role from sys.dba_roles order by role;');
			dbms_output.put_line(chr(10));
			return;
		END IF;



		----------------------------------------
		-- HEADER INFO                        --
		----------------------------------------

		dbms_output.put_line(chr(10));

		dbms_output.put_line('-- =====================================');

		dbms_output.put_line('-- Date: '||to_char(sysdate,'YYYY-MM-DD HH24:MI:SS'));

		select '-- Database: '||name into stmt from v$database;
		dbms_output.put_line(stmt);

		dbms_output.put_line('-- Role: '||in_role);

		dbms_output.put_line('-- =====================================');



		----------------------------------------
		-- ROLE                               --
		----------------------------------------

		select count(1) into pw_vals_exists
		from   sys.user$
		where  name=in_role
			   and spare4 is not null;

		select authentication_type into auth_type
		from   sys.dba_roles
		where  role=in_role;

		dbms_output.put_line(chr(10));
		dbms_output.put_line('-- create role');

		IF auth_type='NONE' THEN
			dbms_output.put_line('create role "'||in_role||'" not identified;');
		ELSIF auth_type='EXTERNAL' THEN
			dbms_output.put_line('create role "'||in_role||'" identified externally;');
		ELSIF auth_type='GLOBAL' THEN
			dbms_output.put_line('create role "'||in_role||'" identified globally;');
		ELSIF auth_type='APPLICATION' THEN
			dbms_output.put_line('create role "'||in_role||'" identified using <schema>.<package>; /*Script limitation: find out where the package is stored*/;');
		ELSIF auth_type='PASSWORD' and pw_vals_exists>0 THEN
			select 'create role "'||in_role||'" identified by values '''||spare4||''';' into stmt from sys.user$ where name=in_role;
			dbms_output.put_line(stmt);
		ELSIF auth_type='PASSWORD' and pw_vals_exists=0 THEN
			dbms_output.put_line('create role "'||in_role||'" identified by <password>;');
		END IF;



		----------------------------------------
		-- ROLES                              --
		----------------------------------------

		dbms_output.put_line(chr(10));
		dbms_output.put_line('-- roles');

		FOR s IN (  select   case when admin_option='YES'    then 'grant "'||granted_role||'" to "'||grantee||'" with admin option;'
				                  when delegate_option='YES' then 'grant "'||granted_role||'" to "'||grantee||'" with delegate option;'
				                  else 'grant "'||granted_role||'" to "'||grantee||'";'
				             end stmt
				    from     sys.dba_role_privs
				    where    grantee=in_role
				    order by granted_role
				 )
		LOOP
			dbms_output.put_line(s.stmt);
		END LOOP;



		----------------------------------------
		-- SYS PRIVS                          --
		----------------------------------------

		dbms_output.put_line(chr(10));
		dbms_output.put_line('-- system privleges');

		FOR s IN (  select   case when admin_option='YES' then 'grant '||privilege||' to "'||grantee||'" with admin option;'
				                  else 'grant '||privilege||' to "'||grantee||'";'
				             end stmt
				    from     sys.dba_sys_privs
				    where    grantee=in_role
				    order by privilege
				 )
		LOOP
			dbms_output.put_line(s.stmt);
		END LOOP;



		----------------------------------------
		-- OBJECT PRIVS                       --
		----------------------------------------

		dbms_output.put_line(chr(10));
		dbms_output.put_line('-- object privleges');

		FOR s IN (  select   case when hierarchy='YES' and grantable='YES' then 'grant '||privilege||' on "'||owner||'"."'||table_name||'" to "'||grantee||'" with hierarchy option with grant option;'
				                  when hierarchy='YES' and grantable='NO'  then 'grant '||privilege||' on "'||owner||'"."'||table_name||'" to "'||grantee||'" with hierarchy option;'
				                  when hierarchy='NO'  and grantable='YES' then 'grant '||privilege||' on "'||owner||'"."'||table_name||'" to "'||grantee||'" with grant option;'
				                  else 'grant '||privilege||' on "'||owner||'"."'||table_name||'" to "'||grantee||'";'
				             end stmt
				    from     sys.dba_tab_privs
				    where    grantee=in_role
				    order by owner
				           , table_name
				           , privilege
				 )
		LOOP
			dbms_output.put_line(s.stmt);
		END LOOP;



		----------------------------------------
		-- COLUMN PRIVS                       --
		----------------------------------------

		dbms_output.put_line(chr(10));
		dbms_output.put_line('-- column privleges');

		FOR s IN (  select   case when grantable='YES' then 'grant '||privilege||' ("'||column_name||'") on "'||owner||'"."'||table_name||'" to "'||grantee||'" with grant option;'
				                  else 'grant '||privilege||' ("'||column_name||'") on "'||owner||'"."'||table_name||'" to "'||grantee||'";'
				             end stmt
				    from     sys.dba_col_privs
				    where    grantee=in_role
				    order by owner
				           , table_name
				           , column_name
				           , privilege
				 )
		LOOP
			dbms_output.put_line(s.stmt);
		END LOOP;

		dbms_output.put_line(chr(10));
	END role;



	PROCEDURE user (
		in_username IN sys.dba_role_privs.grantee%type default null )
	AS
		dfltroles       varchar2(1000) := null;
		dfltrolesqty    number(38)     := 0;
		grantedrolesqty number(38)     := 0;
		is_expired      number(38)     := 0;
		is_locked       number(38)     := 0;
		pw_vals_exists  number(38)     := 0;
		stmt            varchar2(4000) := null;
		usr_dflt_tblspc varchar2(30)   := null;
		usr_exists      number(38)     := 0;
		usr_profile     varchar2(128)  := null;
		usr_tmp_tblspc  varchar2(30)   := null;
	BEGIN
		----------------------------------------
		-- VERIFY INPUT                       --
		----------------------------------------

		IF in_username is null THEN
			dbms_output.put_line(chr(10));
			dbms_output.put_line('SYNTAX:  execute ca.privs.user(''<username>'');');
			dbms_output.put_line('EXAMPLE: execute ca.privs.user(''TUSER01'');');
			dbms_output.put_line(chr(10));
			return;
		END IF;

		select count(1) into usr_exists from sys.dba_users where username=in_username;

		IF usr_exists=0 THEN
			dbms_output.put_line(chr(10));
			dbms_output.put_line('ERROR: Username, '||in_username||', does not exist.');
			dbms_output.put_line('Note: this is a case-sensitive parameter. Use the following query to find usernames...');
			dbms_output.put_line('select username from sys.dba_users order by username;');
			dbms_output.put_line(chr(10));
		   return;
		END IF;



		----------------------------------------
		-- HEADER INFO                        --
		----------------------------------------

		dbms_output.put_line(chr(10));

		dbms_output.put_line('-- =====================================');

		dbms_output.put_line('-- Date: '||to_char(sysdate,'YYYY-MM-DD HH24:MI:SS'));

		select '-- Database: '||name into stmt from v$database;
		dbms_output.put_line(stmt);

		dbms_output.put_line('-- Username: '||in_username);

		dbms_output.put_line('-- =====================================');



		----------------------------------------
		-- USER                               --
		----------------------------------------

		dbms_output.put_line(chr(10));
		dbms_output.put_line('-- user');
		dbms_output.put_line('create user "'||in_username||'"');

		select count(1) into pw_vals_exists
		from   sys.user$
		where  name=in_username
			   and spare4 is not null;
		IF pw_vals_exists=0 THEN
			select 'identified by <PASSWORD>' into stmt from dual;
		ELSE
			select 'identified by values '''||spare4||'''' into stmt
			from   sys.user$
			where  name=in_username;
		END IF;
		dbms_output.put_line(stmt);

		select default_tablespace
			 , temporary_tablespace
			 , profile
			 , instr(account_status,'EXPIRED')
			 , instr(account_status,'LOCKED')
		into   usr_dflt_tblspc
			 , usr_tmp_tblspc
			 , usr_profile
			 , is_expired
			 , is_locked
		from   sys.dba_users
		where  username=in_username;

		dbms_output.put_line('default tablespace "'||usr_dflt_tblspc||'"');
		dbms_output.put_line('temporary tablespace "'||usr_tmp_tblspc||'"');
		dbms_output.put_line('profile "'||usr_profile||'";');

		IF is_expired>0 THEN
			dbms_output.put_line('alter user "'||in_username||'" password expire;');
		END IF;

		IF is_locked>0 THEN
			dbms_output.put_line('alter user "'||in_username||'" account lock;');
		END IF;

		FOR s in (  select   case when max_bytes=-1 THEN 'alter user "'||username||'" quota unlimited on "'||tablespace_name||'";'
							      when max_bytes>=1152921504606846976 and mod(max_bytes,1152921504606846976)=0 then 'alter user "'||username||'" quota '||to_char(max_bytes/1152921504606846976)||'E on "'||tablespace_name||'";'
							      when max_bytes>=1125899906842624 and mod(max_bytes,1125899906842624)=0 then 'alter user "'||username||'" quota '||to_char(max_bytes/1125899906842624)||'P on "'||tablespace_name||'";'
							      when max_bytes>=1099511627776 and mod(max_bytes,1099511627776)=0 then 'alter user "'||username||'" quota '||to_char(max_bytes/1099511627776)||'T on "'||tablespace_name||'";'
							      when max_bytes>=1073741824 and mod(max_bytes,1073741824)=0 then 'alter user "'||username||'" quota '||to_char(max_bytes/1073741824)||'G on "'||tablespace_name||'";'
							      when max_bytes>=1232896 and mod(max_bytes,1232896)=0 then 'alter user "'||username||'" quota '||to_char(max_bytes/1232896)||'M on "'||tablespace_name||'";'
							      when max_bytes>=1024 and mod(max_bytes,1024)=0 then 'alter user "'||username||'" quota '||to_char(max_bytes/1024)||'K on "'||tablespace_name||'";'
							      else 'alter user "'||username||'" quota '||to_char(max_bytes)||' on "'||tablespace_name||'";'
							 end stmt
					from     sys.dba_ts_quotas
					where    username=in_username
					order by tablespace_name
				 )
		LOOP
			dbms_output.put_line(s.stmt);
		END LOOP;



		----------------------------------------
		-- PROXIES                            --
		----------------------------------------

		dbms_output.put_line(chr(10));
		dbms_output.put_line('-- proxies');

		FOR s IN (
			select
				'alter user "'||client||'" grant connect through "'||proxy||'";' stmt
			from
				dba_proxies
			where
				proxy=in_username
			order by
				  proxy
				, client
		)
		LOOP
			dbms_output.put_line(s.stmt);
		END LOOP;



		----------------------------------------
		-- ROLES                              --
		----------------------------------------

		dbms_output.put_line(chr(10));
		dbms_output.put_line('-- roles');

		FOR s IN (  select   case when admin_option='YES'    then 'grant "'||granted_role||'" to "'||grantee||'" with admin option;'
							      when delegate_option='YES' then 'grant "'||granted_role||'" to "'||grantee||'" with delegate option;'
							      else 'grant "'||granted_role||'" to "'||grantee||'";'
							 end stmt
					from     sys.dba_role_privs
					where    grantee=in_username
					order by granted_role
				 )
		LOOP
			dbms_output.put_line(s.stmt);
		END LOOP;

		select count(1) into grantedrolesqty
		from   sys.dba_role_privs
		where  grantee=in_username;

		select count(1) into dfltrolesqty
		from   sys.dba_role_privs
		where  grantee=in_username
			   and default_role='YES';

		IF grantedrolesqty = dfltrolesqty AND grantedrolesqty > 0 THEN
			dbms_output.put_line('alter user "'||in_username||'" default role all;');
		ELSIF dfltrolesqty > 0 THEN
			select '"'||listagg(granted_role,'", "') within group(order by granted_role)||'"' into dfltroles
			from   sys.dba_role_privs
			where  grantee=in_username
				   and default_role='YES';

			select 'alter user "'||username||'" default role '||dfltroles||';' into stmt
			from   sys.dba_users
			where  username=in_username;

			dbms_output.put_line(stmt);
		END IF;



		----------------------------------------
		-- SYS PRIVS                          --
		----------------------------------------

		dbms_output.put_line(chr(10));
		dbms_output.put_line('-- system privleges');

		FOR s IN (  select   case when admin_option='YES' then 'grant '||privilege||' to "'||grantee||'" with admin option;'
							      else 'grant '||privilege||' to "'||grantee||'";'
							 end stmt
					from     sys.dba_sys_privs
					where    grantee=in_username
					order by privilege
				 )
		LOOP
			dbms_output.put_line(s.stmt);
		END LOOP;



		----------------------------------------
		-- OBJECT PRIVS                       --
		----------------------------------------

		dbms_output.put_line(chr(10));
		dbms_output.put_line('-- object privleges');

		FOR s IN (  select   case when hierarchy='YES' and grantable='YES' then 'grant '||privilege||' on "'||owner||'"."'||table_name||'" to "'||grantee||'" with hierarchy option with grant option;'
							      when hierarchy='YES' and grantable='NO'  then 'grant '||privilege||' on "'||owner||'"."'||table_name||'" to "'||grantee||'" with hierarchy option;'
							      when hierarchy='NO'  and grantable='YES' then 'grant '||privilege||' on "'||owner||'"."'||table_name||'" to "'||grantee||'" with grant option;'
							      else 'grant '||privilege||' on "'||owner||'"."'||table_name||'" to "'||grantee||'";'
							 end stmt
					from     sys.dba_tab_privs
					where    grantee=in_username
					order by owner
						   , table_name
						   , privilege
				 )
		LOOP
			dbms_output.put_line(s.stmt);
		END LOOP;



		----------------------------------------
		-- COLUMN PRIVS                       --
		----------------------------------------

		dbms_output.put_line(chr(10));
		dbms_output.put_line('-- column privleges');

		FOR s IN (  select   case when grantable='YES' then 'grant '||privilege||' ("'||column_name||'") on "'||owner||'"."'||table_name||'" to "'||grantee||'" with grant option;'
							      else 'grant '||privilege||' ("'||column_name||'") on "'||owner||'"."'||table_name||'" to "'||grantee||'";'
							 end stmt
					from     sys.dba_col_privs
					where    grantee=in_username
					order by owner
						   , table_name
						   , column_name
						   , privilege
				 )
		LOOP
			dbms_output.put_line(s.stmt);
		END LOOP;
	END user;
END privs;


1 row selected.

