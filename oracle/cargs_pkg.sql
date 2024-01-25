/*

https://github.com/dbabyday
Warranty: The software is provided "AS IS", without warranty of any kind

Name: cargs_pkg.sql
Description: See arguments for a specified package

*/


variable a_owner        varchar2(128);
variable a_package_name varchar2(128);
variable a_object_name  varchar2(128);
variable o_object_name  varchar2(128);
set define "&"
begin

	:a_owner        := '&_OWNER';
	:a_package_name := '&_PACKAGE_NAME';
	:a_object_name  := '&_OBJECT_NAME';

	if nvl(:a_package_name,'a_package_name is null')='a_package_name is null' then
		:o_object_name := :a_object_name;
	else
		:o_object_name := :a_package_name;
	end if;
end;
/





/****************************/
/* SHOW ARGUMENTS           */
/****************************/

/*
PRODDTA.P_AMS_REV_REC_DETAIL_REPORT
*/

column fully_qualified_object_name format a50
column overload format a8
column argument_name format a25
column data_type format a25
column defaulted format a9

set pagesize 50000
set feedback off
break on object_type nodup on fully_qualified_object_name nodup on overload skip 1 nodup

select	  o.object_type
	, case	when a.package_name is null then o.owner||'.'||o.object_name
		else a.owner||'.'||a.package_name||'.'||a.object_name
	  end fully_qualified_object_name
	, a.overload
	, a.argument_name
	, case	when a.data_type='NUMBER' and a.data_precision is not null and a.data_scale is not null then a.data_type||'('||to_char(a.data_precision)||','||to_char(a.data_scale)||')'
		when a.data_type='NUMBER' and a.data_precision is not null and a.data_scale is null then a.data_type||'('||to_char(a.data_precision)||')'
		when a.data_type='NUMBER' and a.data_precision is null then a.data_type
		when a.char_length is not null and a.char_used='B' then a.pls_type||'('||to_char(a.char_length)||' BYTE)'
		when a.char_length is not null and a.char_used='C' then a.pls_type||'('||to_char(a.char_length)||' CHAR)'
		when a.type_owner is not null and a.type_subname is not null then a.type_owner||'.'||a.type_name||'.'||a.type_subname
		when a.type_owner is not null and a.type_subname is null then a.type_owner||'.'||a.type_name
		else a.data_type
	  end data_type
	, a.in_out
	, a.defaulted
	, a.sequence
from	  dba_objects o
left join dba_arguments a on a.object_id=o.object_id
where	  o.object_type in ('FUNCTION','PACKAGE','PROCEDURE','TYPE')
	  and o.owner=nvl(:a_owner,o.owner)
	  and o.object_name=nvl(:o_object_name,o.object_name)
	  and a.package_name=nvl(:a_package_name,a.package_name)
	  and a.object_name=nvl(:a_object_name,a.object_name)
	  and (a.data_level=0 or a.data_level is null)
order by  fully_qualified_object_name
	, a.overload
	, a.sequence;

clear breaks




/****************************/
/* SHOW TEMPLATES           */
/****************************/

declare
	l_argument_count number;
	l_line  varchar2(500);
	l_qty_overloads number;
	l_qty_arguments number;
	l_argument varchar2(500);
begin
	dbms_output.put_line(chr(10)||'/* TEMPLATES */'||chr(10));
	/* loop through objects */
	for x1 in (  select   case when a.package_name is null then o.owner||'.'||o.object_name
	                           else a.owner||'.'||a.package_name||'.'||a.object_name
	                      end fully_qualified_object_name
	                    , a.owner
	                    , a.package_name
	                    , a.object_name
	                    , a.overload
	             from     dba_objects o
	             left join dba_arguments a on a.object_id=o.object_id
	             where     o.object_type in ('FUNCTION','PACKAGE','PROCEDURE','TYPE')
	                       and o.owner=nvl(:a_owner,o.owner)
	                       and o.object_name=nvl(:o_object_name,o.object_name)
	                       and a.package_name=nvl(:a_package_name,a.package_name)
	                       and a.object_name=nvl(:a_object_name,a.object_name)
	                       and (a.data_level=0 or a.data_level is null)
	             group by a.owner
	                    , a.package_name
	                    , a.object_name
	                    , a.overload
	                    , o.owner
	                    , o.object_name
	             order by  fully_qualified_object_name
	                     , length(a.overload), a.overload
	          )
	loop
		/* check how many overloads there are */
		select count(1)
		into   l_qty_overloads
		from   (  select    a.overload
		          from      dba_objects o
		          left join dba_arguments a on a.object_id=o.object_id
		          where     o.object_type in ('FUNCTION','PACKAGE','PROCEDURE','TYPE')
	                            and o.owner=nvl(:a_owner,o.owner)
	                            and o.object_name=nvl(:o_object_name,o.object_name)
	                            and a.package_name=nvl(:a_package_name,a.package_name)
	                            and a.object_name=nvl(:a_object_name,a.object_name)
	                            and (a.data_level=0 or a.data_level is null)
	                  group by  a.overload
	               );

		/* if there is only one, the overload value will be null and we cannot use the same equality operator */
		if l_qty_overloads=1 then
			/* check how many arguments there are so we can format the command nicely */
			select count(1)
			into   l_qty_arguments
			from   dba_arguments a
			where  a.data_level=0
			       and a.owner=x1.owner
			       and a.package_name=x1.package_name
			       and a.object_name=x1.object_name;

			/* if there are no arguments, put the command on one line */
			if l_qty_arguments=0 then
				dbms_output.put_line(x1.fully_qualified_object_name||'();'||chr(10));
			/* if there is just one argument, put the command on one line */
			elsif l_qty_arguments=1 then
				select case when a.defaulted='Y' then '/*'||a.argument_name||' => */'
				            else a.argument_name||' => '
				       end
				into   l_argument
				from   dba_arguments a
				where  a.data_level=0
				       and a.owner=x1.owner
				       and a.package_name=x1.package_name
				       and a.object_name=x1.object_name;

				dbms_output.put_line(x1.fully_qualified_object_name||'('||l_argument||');'||chr(10));
			/* if there are multiple arguments, put them on separate lines */
			else
				/* first line is listing the object and opening the parenthesis for the arguments */
				dbms_output.put_line(x1.fully_qualified_object_name||' (');

				/* loop through the arguments, listing mandatory ones first, then optional ones that have default values */
				l_argument_count := 1; /* l_argument_count tracks which argument we are on */
				for x2 in (  select   a.argument_name
				                    , a.defaulted
				             from     dba_arguments a
				             where    a.data_level=0
				                      and a.owner=x1.owner
				                      and a.package_name=x1.package_name
				                      and a.object_name=x1.object_name
				             order by a.defaulted
				                    , a.sequence
				          )
				loop
					/* if the argument has a default, start the line as a comment so the user can see that it is optional */
					if x2.defaulted='Y' then
						l_line := '	--';
					else
						l_line := '	';
					end if;

					/* separate the arguments with a comma */
					if l_argument_count>1 then
						l_line := l_line||', ';
					else
						l_line := l_line||'  ';
					end if;

					/* add the argument */
					l_line := l_line||x2.argument_name||' => ';

					dbms_output.put_line(l_line);
					l_argument_count := l_argument_count + 1;
				end loop;

				/* end the command */
				dbms_output.put_line(');'||chr(10));
			end if;
		/* multiple overloads, so we can use the overload value in an equality operator */
		else
			dbms_output.put_line('/* overload '||x1.overload||' */');
			/* check how many arguments there are so we can format the command nicely */
			select count(1)
			into   l_qty_arguments
			from   dba_arguments a
			where  a.data_level=0
			       and a.owner=x1.owner
			       and a.package_name=x1.package_name
			       and a.object_name=x1.object_name
			       and a.overload=x1.overload;

			/* if there are no arguments, put the command on one line */
			if l_qty_arguments=0 then
				dbms_output.put_line(x1.fully_qualified_object_name||'();'||chr(10));
			/* if there is just one argument, put the command on one line */
			elsif l_qty_arguments=1 then
				select case when a.defaulted='Y' then '/*'||a.argument_name||' => */'
				            else a.argument_name||' => '
				       end
				into   l_argument
				from   dba_arguments a
				where  a.data_level=0
				       and a.owner=x1.owner
				       and a.package_name=x1.package_name
				       and a.object_name=x1.object_name
				       and a.overload=x1.overload;

				dbms_output.put_line(x1.fully_qualified_object_name||'('||l_argument||');'||chr(10));
			/* if there are multiple arguments, put them on separate lines */
			else
				/* first line is listing the object and opening the parenthesis for the arguments */
				dbms_output.put_line(x1.fully_qualified_object_name||' (');

				/* loop through the arguments, listing mandatory ones first, then optional ones that have default values */
				l_argument_count := 1; /* l_argument_count tracks which argument we are on */
				for x3 in (  select   a.argument_name
				                    , a.defaulted
				             from     dba_arguments a
				             where    a.data_level=0
				                      and a.owner=x1.owner
				                      and a.package_name=x1.package_name
				                      and a.object_name=x1.object_name
				                      and a.overload=x1.overload
				             order by a.defaulted
				                    , a.sequence
				          )
				loop
					/* if the argument has a default, start the line as a comment so the user can see that it is optional */
					if x3.defaulted='Y' then
						l_line := '	--';
					else
						l_line := '	';
					end if;

					/* separate the arguments with a comma */
					if l_argument_count>1 then
						l_line := l_line||', ';
					else
						l_line := l_line||'  ';
					end if;

					/* add the argument */
					l_line := l_line||x3.argument_name||' => ';

					dbms_output.put_line(l_line);
					l_argument_count := l_argument_count + 1;
				end loop;

				/* end the command */
				dbms_output.put_line(');'||chr(10));
			end if;
		end if;
	end loop;
end;
/



variable a_owner        varchar2(128);
variable a_package_name varchar2(128);
variable a_object_name  varchar2(128);
variable o_object_name  varchar2(128);
