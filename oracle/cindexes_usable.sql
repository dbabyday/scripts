
set feedback off define "&"
prompt Substitution variable 1 = TABLE_OWNER;
prompt Substitution variable 2 = TABLE_NAME;
column my_table_owner new_value _TABLE_OWNER noprint;
column my_table_name new_value _TABLE_NAME noprint;
select '&1' my_table_owner, '&2' my_table_name from dual;
set feedback on


column owner format a11
column table_owner format a11
column table_name format a15
column index_name format a15
column status format a50
column logging format a50

select
	  i.table_owner
	, i.table_name
	, i.owner
	, i.index_name
	, case
		when p.status_list is not null then p.status_list
		else i.status
	  end status
	, i.degree
from
	dba_indexes i
left join
	(
		select
			  index_owner
			, index_name
			, 'PARTITIONS: '||listagg(status||' ('||to_char(qty)||')', ', ') within group (order by status) status_list
		from
			(
				select
					  psq_p.index_owner
					, psq_p.index_name
					, psq_p.status
					, count(*) qty
				from
					dba_indexes psq_i
				join
					dba_ind_partitions psq_p on psq_p.index_owner=psq_i.owner and psq_p.index_name=psq_i.index_name
				where
					psq_i.table_owner='&&_TABLE_OWNER'
					and psq_i.table_name='&&_TABLE_NAME'
				group by
					  psq_p.index_owner
					, psq_p.index_name
					, psq_p.status
			)
		group by
			  index_owner
			, index_name
	) p on p.index_owner=i.owner and p.index_name=i.index_name
where
	i.table_owner='&&_TABLE_OWNER'
	and i.table_name='&&_TABLE_NAME'
order by
	  i.owner
	, length(i.index_name)
	, i.index_name;


select
	  t.owner
	, t.table_name
	, case
		when p.logging_list is not null then p.logging_list
		else t.logging
	  end logging
from
	dba_tables t
left join
	(
		select
			  table_owner
			, table_name
			, 'PARTITIONS: '||listagg(logging||' ('||to_char(qty)||')', ', ') within group (order by logging) logging_list
		from
			(
				select
					  table_owner
					, table_name
					, logging
					, count(*) qty
				from
					dba_tab_partitions
				where
					table_owner='&&_TABLE_OWNER'
					and table_name='&&_TABLE_NAME'
				group by
					  table_owner
					, table_name
					, logging
			)
		group by
			  table_owner
			, table_name
	) p on p.table_owner=t.owner and p.table_name=t.table_name
where
	t.owner='&&_TABLE_OWNER'
	and t.table_name='&&_TABLE_NAME';

undefine 1
undefine 2
undefine _TABLE_OWNER
undefine _TABLE_NAME