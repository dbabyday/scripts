rem  Copyright 1997-2018, DBConnect Solutions, Inc.  All Rights Reserved.
rem  NightOwl® and the NightOwl® logo are trademarks of 
rem  DBConnect Solutions, Inc.
rem
rem  ---------------------------------------------------------------------------

rem  ---------------------------------------------------------------------------
rem  wait_details.sql
rem  
rem  Purpose:		Report database wait information.  This will 
rem                     immediately indicate the health of active sessions.
rem
rem  Author:		DBConnect Solutions, Inc.
rem 
rem  Original Date:	September 30, 1999
rem  Last Modified:	January 30, 2013
rem
rem  Modifications:	Updated for version 8.x, 9.x, 9i, 10g, 11g, 12c
rem
rem  Program Type:	SQL*Plus
rem
rem  --------------------------------------------------------------------------


rem
rem  Do some standard settings in SQL*Plus.
rem
set linesize 132
set pagesize 58
set heading  on
set serveroutput on
set termout on
set trimspool on
set define off
set echo off

rem
rem  The filename can be changed to any valid location in your system.
rem
spool \\neen-dsk-011\it$\database\users\James\JamesDownloads\cwait_details.txt


prompt © 1997-2018 DBConnect Solutions, Inc., Niles, MI (574) 527-9286. All Rights Reserved.
prompt NightOwl® and the NightOwl® logo are trademarks of DBConnect Solutions, Inc.  Oracle and Java
prompt are registered trademarks of Oracle and/or its affiliates. Other names may be trademarks of 
prompt their respective owners.


prompt
prompt DBConnect Solutions, Inc. NightOwl® Monitoring & Messaging System
prompt
prompt Reporting on the first 50 database waits in the database system, sorted by descending order of run time.
prompt      

declare

	bind_info	raw(2000);
	statement_ctr	number;
	i		number;
        owner		varchar2(30);
        segment_type    varchar2(30);
        segment_name    varchar2(30);
	sql_hash	gv$sqlarea.hash_value%type;
	sql_address	gv$sqlarea.address%type;
	sql_inst_id	gv$sqlarea.inst_id%type;
	ind_owner	dba_ind_columns.index_owner%type;
	ind_name	dba_ind_columns.index_name%type;
	svm_schema	varchar2(30);
	svm_job_name	varchar2(132);

	cursor c1 is
	select 	
		s.sid,
		s.osuser,
		s.username,
                s.client_info,
		decode(substr(s.event,1,55),'db file scattered read','Full Table Scan',
			'db file sequential read','Index Scan',substr(s.event,1,55)) event, 
		c.disk_reads,
		c.buffer_gets,
		c.first_load_time,
		c.executions,
		s.seconds_in_wait wait_time,
		s.p1,	
		s.p1text,
		s.p2,
		s.p2text,
		s.p3,
		s.p3text,
		c.sql_fulltext,
		c.rows_processed, 
		c.sql_profile,
		round(c.elapsed_time / 1000000 / decode(c.executions,0,1,c.executions) * 10000) / 10000 avg_time,
		s.process,
		s.machine,
		s.terminal,
		s.program,
		s.module,
		s.sql_id,
		s.sql_child_number,
		c.bind_data,
		c.hash_value,
		c.address,
		c.inst_id
	from 	gv$session s,
		gv$sqlarea c
 -- where s.sid = 509
	where	s.wait_class    != 'Idle'
	-- where	s.event like 'buffer busy wait%'
	and	s.inst_id	 = c.inst_id (+)
	and 	s.sql_address	 = c.address (+)
	and 	s.sql_hash_value = c.hash_value (+)
-- and upper(s.osuser) not like '%RCARTER%'
	order 	by round(c.elapsed_time / 1000000 / decode(c.executions,0,1,c.executions) * 10000) / 10000 desc;


	cursor binds is
	select 
		position, 
		value_string 
	from 	table(dbms_sqltune.extract_binds(bind_info));

	cursor 	c3 is
	select	distinct
		operation,
		object_owner,
		object_name
	from	gv$sql_plan
	where	hash_value 	= sql_hash
	and	address		= sql_address
	and	inst_id		= sql_inst_id
	and	operation not in ('MERGE JOIN','NESTED LOOPS','BUFFER','SELECT STATEMENT',
				'SORT','FILTER','TABLE ACCESS','HASH','INLIST ITERATOR',
				'BITMAP CONVERSION','BITMAP OR','UNION-ALL','CONCATENATION',
				'HASH JOIN')
	order	by 1,3;


	cursor 	c4 is
	select	column_name
	from	dba_ind_columns
	where	index_owner	= ind_owner
	and	index_name	= ind_name
	order	by column_position;


begin
	dbms_output.enable(900000);
	statement_ctr := 0;

	--
	-- Obtain the schema name of the server map owner so we can obtain the
	-- job name of any running UBEs.
	--
	begin

   	   select xxx.owner
   	   into svm_schema
   	   from 
		(select owner from dba_segments
		where owner like 'SVM%'
		and segment_name = 'F986110'
		order by bytes desc) xxx
   	   where rownum = 1;

	exception
   	   when others then
      		svm_schema := null;
	end;
	

	--
	-- Loop through all SQL statements in a wait state.
	--
	for inrec in c1 loop

	   --
	   -- Only report the first 50 statements.
	   --
	   statement_ctr := statement_ctr + 1;
	   if statement_ctr >= 51 then
	      exit;
	   end if;

           --
           --  Locate the object the statement is waiting on.
           --   (too slow when there are multiple waits, due to known issue with dba_extents view)
           -- if inrec.p1text = 'file#'     
           --   and inrec.p2text = 'block#'
           --   and inrec.p3text = 'blocks' then

           --    begin

	   --   select	/*+ RULE */ owner,
           --             segment_type,
           --             segment_name
           --    into     owner,
           --             segment_type,
           --             segment_name
           --    from     dba_extents
           --    where    file_id = inrec.p1
           --    and      inrec.p2 between block_id and (block_id + blocks - 1);

           --    exception
           --       when others then
                     owner := NULL;
                     segment_name := NULL;
                     segment_type := NULL;
           --    end;

           -- end if;

	   --
	   -- If the SQL statement comes from a UBE, go find the job name
	   -- associated with the running SQL.
	   --
           svm_job_name := ' '; 
           -- if (inrec.program like 'runbatch%') then
              -- if (svm_schema is not null) then

                 -- begin
                    -- select '            Job No: ' || to_char(jcjobnbr) || chr(10) ||
			--   '              Name: ' || trim(jcfndfuf2)   || chr(10) ||
			--   '    Time Submitted: ' || to_char(jcsbmdate) || ':' || to_char(jcsbmtime)
	            -- into   svm_job_name
	            -- from   svm_schema.f986110
	            -- from   svmpd900.f986110
	            -- where  trim(jcexehost)    = inrec.machine
	            -- and    jcprocessid + 0    = to_number(inrec.process)
                    -- and    jcjobsts           = 'P';
                 -- exception
                 --   when others then
                 --      svm_job_name := 'error';
                 -- end;
              -- else
              --   svm_job_name := '(unknown program name)';
              -- end if;
           -- else
           --   svm_job_name := ' ';
	   -- end if;


	   dbms_output.put_line('Statement Number: ' || to_char(statement_ctr));
	   dbms_output.put_line('--------------------------------------------');
	   dbms_output.put_line('SID Id         : ' || 
				to_char(inrec.sid));
	   dbms_output.put_line('OS User        : ' || 
				inrec.osuser);
	   dbms_output.put_line('Oracle User    : ' || 
				inrec.username);

	   dbms_output.put_line('Source Machine : ' || 
				inrec.machine);
	   dbms_output.put_line('Source Program : ' || 
				inrec.program);
	   dbms_output.put_line(svm_job_name);
	   -- dbms_output.put_line('Source Module  : ' || 
	   --			inrec.module);
	   dbms_output.put_line('Source Terminal: ' || 
				inrec.terminal);
	   dbms_output.put_line('Source Process : ' || 
				inrec.process);

           -- dbms_output.put_line('Client Info    : ' || 
	   --			inrec.client_info);
	   dbms_output.put_line('Wait Event     : ' || 
				inrec.event);
	   dbms_output.put_line('Disk Reads     : ' || 
				to_char(inrec.disk_reads));
	   dbms_output.put_line('Buffer Gets    : ' || 
				to_char(inrec.buffer_gets));
	   dbms_output.put_line('First Load Time: ' || 
				inrec.first_load_time);
	   dbms_output.put_line('Executions     : ' || 
				to_char(inrec.executions));
	   dbms_output.put_line('Avg Run Seconds: ' || 
				to_char(inrec.avg_time));

	   dbms_output.put_line('SQL Profile    : ' || 
				to_char(inrec.sql_profile));
	   dbms_output.put_line('Rows Processed : ' || 
				to_char(inrec.rows_processed));
	   dbms_output.put_line('No Secs Waiting: ' || 
				to_char(inrec.wait_time));

           if segment_name is not null then
	      dbms_output.put_line('Waiting On Object: ' || 
	   			owner || '.' || segment_name || 
	   			' of type ' || segment_type);
           end if;

	   dbms_output.put_line('Wait Parm 1    : ' || 
				to_char(inrec.p1));
	   dbms_output.put_line('Wait Parm Info : ' || 
				to_char(inrec.p1text));
	   dbms_output.put_line('Wait Parm 2    : ' || 
				to_char(inrec.p2));
	   dbms_output.put_line('Wait Parm Info : ' || 
				to_char(inrec.p2text));
	   dbms_output.put_line('Wait Parm 3    : ' || 
				to_char(inrec.p3));
	   dbms_output.put_line('Wait Parm Info : ' || 
				to_char(inrec.p3text));

	   dbms_output.put_line('SQL Id         : ' || 
				inrec.sql_id);
	   dbms_output.put_line('SQL Child No   : ' || 
				to_char(inrec.sql_child_number));


	   dbms_output.put_line('SQL Statement-------->');

	   i := 1;
           while i <= ceil(length(inrec.sql_fulltext) / 72) loop

	      dbms_output.put_line('.....' || 
					substr(inrec.sql_fulltext,((i-1)*72)+1,72));
              i := i + 1;


           end loop;
	   
           dbms_output.put_line('"Peeked" Bind Values Captured-------->');

	   bind_info := inrec.bind_data;
	   for bind_rec in binds loop
		dbms_output.put_line(to_char(bind_rec.position) || '- ' || bind_rec.value_string);
	   end loop;

	   -- dbms_output.put_line('--------------------------------------------');
	   -- dbms_output.put_line( chr(10) );

	   sql_hash 	:= inrec.hash_value;
	   sql_address	:= inrec.address;	
	   sql_inst_id	:= inrec.inst_id;

	   dbms_output.put_line('****** Optimizer Path -------->');

	   for inrec3 in c3 loop
	      dbms_output.put_line('Operation: ' || inrec3.operation);
	      dbms_output.put_line('   Object: ' || inrec3.object_owner || '.' || inrec3.object_name);

	      if inrec3.operation = 'INDEX' then
	         ind_owner	:= inrec3.object_owner;
	         ind_name	:= inrec3.object_name;

		 for inrec4 in c4 loop
		    dbms_output.put_line('   Index Column: ' || inrec4.column_name);
		 end loop;

	      end if;

 	   end loop;

	   dbms_output.put_line('--------------------------------------------');
	   dbms_output.put_line( chr(10) );


	end loop;
end;
/



spool off

set define on

edit \\neen-dsk-011\it$\database\users\James\JamesDownloads\cwait_details.txt