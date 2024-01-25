/*
    Primary Keys
*/


set feedback on

column owner format a15
column table_name format a15
column column_name format a15
column constraint_name format a15
column data_type format a15

SELECT   

	--   cons.owner
	-- , cons.table_name
	-- , cols.column_name
	-- , tc.data_type
	-- , cols.position
	-- , cons.constraint_name
	-- , cons.constraint_type
	-- , cons.status

	'select '''||cons.table_name||''' table_name, count(*) duplicates --'||listagg(lower('a.'||cols.column_name), ', ') within group (order by cols.position)||chr(10)||
	'from arcdta.'||lower(cons.table_name)||' a'||chr(10)||
	'join proddta.'||lower(cons.table_name)||'@jdepd03_jlutsey t'||chr(10)||
	'on '||listagg(lower('t.'||cols.column_name||'=a.'||cols.column_name), ' and ')||';' stmt
FROM     dba_constraints  cons
JOIN     dba_cons_columns cols ON cons.owner = cols.owner AND cons.constraint_name = cols.constraint_name
JOIN     dba_tab_columns  tc   ON tc.owner=cols.owner AND tc.table_name=cols.table_name AND tc.column_name=cols.column_name
WHERE    cons.constraint_type = 'P'
	  AND cons.owner = 'PRODDTA'
	  AND cons.table_name in (
		  'F0018'
		, 'F03B11'
		, 'F03B112'
		, 'F03B13'
		, 'F03B14'
		, 'F0411'
		, 'F0413'
		, 'F0414'
		, 'F0911'
		, 'F0911T'
		, 'F0911_73'
		, 'F3002'
		, 'F3003'
		, 'F3003T'
		, 'F3007'
		, 'F3011'
		, 'F3013'
		, 'F3015'
		, 'F3102'
		, 'F3102T'
		, 'F3105'
		, 'F3106'
		, 'F3111'
		, 'F3111T'
		, 'F3111_73'
		, 'F3112'
		, 'F31122'
		, 'F31122T'
		, 'F31122_73'
		, 'F3112T'
		, 'F3112Z1'
		, 'F3118'
		, 'F4006'
		, 'F4074'
		, 'F4074TEM'
		, 'F4074_73'
		, 'F4104'
		, 'F4111'
		, 'F4111_73'
		, 'F4140'
		, 'F4141'
		, 'F4209'
		, 'F42199'
		, 'F42199A'
		, 'F4301'
		, 'F43092'
		, 'F43099'
		, 'F4311'
		, 'F4311T'
		, 'F43121'
		, 'F43121T'
		, 'F4314'
		, 'F4318'
		, 'F43199'
		, 'F43199_73'
		, 'F4332'
		, 'F4801'
		, 'F4801T'
		, 'F4802'
		, 'F4818'
		, 'F5531002'
		, 'F5531003'
		, 'F5531005'
		, 'F5531033'
		, 'F5531038'
		, 'F5531051'
		, 'F5543011'
		, 'F5543022'
		, 'F5543121'
		, 'F5543122'
		, 'F5543123'
		, 'F554312T'
		, 'F5543199'
		, 'F5548002'
	  )
group by
		cons.table_name
ORDER BY cons.table_name;

undefine 1
undefine 2
undefine _OWNER
undefine _TABLE_NAME