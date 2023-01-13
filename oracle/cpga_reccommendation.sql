
declare
	l_max_pga             number;
	l_max_utilization     number;
	l_pga_aggregate_limit varchar2(20);
begin
	select value 
	into   l_max_pga 
	from   v$pgastat 
	where  name='maximum PGA allocated' 
	minus 
	select value 
	from   v$pgastat 
	where  name='MGA allocated (under PGA)';

	select max_utilization
	into   l_max_utilization
	from   v$resource_limit 
	where  resource_name='processes';

	select to_char(round(((l_max_pga / 1024 / 1024) + (l_max_utilization * 5)) * 1.1 / 1024,1))
	into   l_pga_aggregate_limit
	from   dual;

	dbms_output.put_line(chr(10));
	dbms_output.put_line('Suggested PGA_AGGREGATE_LIMIT in GB formula:');
	dbms_output.put_line('((maximum aggregate PGA in use for the life of the instance) + ((maximum number of attached processes for the life the instance) * 5M)) * 1.1');
	dbms_output.put_line(chr(10));
	dbms_output.put_line('MAX_PGA: '||to_char(round(l_max_pga/1024/1024,1))||' MB');
	dbms_output.put_line('MAX_UTLIZIATION: '||to_char(l_max_utilization));
	dbms_output.put_line('('||to_char(round(l_max_pga/1024/1024,1))||' + ('||to_char(l_max_utilization)||' * 5M)) * 1.1 / 1024');
	dbms_output.put_line(chr(10));
	dbms_output.put_line(l_pga_aggregate_limit||' GB');
	dbms_output.put_line(chr(10));
end;
/


