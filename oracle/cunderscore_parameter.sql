column name        format a25
column description format a50
column ksppstvl    format a30

select
	  nam.ksppinm  name
	, nam.ksppdesc description
	, val.ksppstvl
from
	x$ksppi nam
join
	x$ksppsv val on nam.indx = val.indx
where
	nam.ksppinm like '%&name%';
