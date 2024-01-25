column name format a30
column sql_ids format a15
column sql_text format a50
column force_matching format a14
column created format a15
column last_modified format a20


with 
	sql_profile_text as (
		select
			name
			, case 
				when length(sql_text)>47 then to_char(substr(sql_text,1,47))||'...'
				else to_char(sql_text)
			  end sql_text
		from
			dba_sql_profiles
	)
select
	  p.name
	, listagg(sql_id,chr(10)) within group (order by sql_id) sql_ids
	, t.sql_text
	, p.status
	, p.force_matching
	, to_char(p.created,'DD-MON-YYYY') created
	, to_char(p.last_modified ,'DD-MON-YYYY HH24:MI:SS') last_modified 
from
	dba_sql_profiles p
join
	sql_profile_text t on t.name=p.name
left join
	v$sql s on p.name=s.sql_profile
group by
	  p.name
	, t.sql_text
	, p.status
	, p.force_matching
	, p.created
	, p.last_modified
order by
	p.created;


/*



begin
	dbms_sqltune.alter_sql_profile (
		  name => 'SYS_SQLPROF_016d605c60f90000'
		, attribute_name => 'FORCE_MATCHING'
		, value => 'YES'
	);
end;
/



*/

