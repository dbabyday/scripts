select name from v$database;
/* drop the old table if it exists */
declare
	l_qty number;
begin
	select count(*)
	into   l_qty
	from   dba_tables
	where  owner='CA' and table_name='PWCHARACTERS';

	if l_qty=1 then
		execute immediate 'drop table ca.pwcharacters';
	end if;
end;
/

/* create the table that holds the possible characters */
create table ca.pwcharacters (
	  id     number not null
	, symbol char(1) not null
);
create unique index ca.pwcharacters_0 on ca.pwcharacters (id);
alter table ca.pwcharacters add constraint pwcharacters_pk primary key (id) using index ca.pwcharacters_0;

/* the characters from which we will randomly choose */
truncate table ca.pwcharacters;
insert all
	into ca.pwcharacters (id, symbol) values (1,'A')
	into ca.pwcharacters (id, symbol) values (2,'B')
	into ca.pwcharacters (id, symbol) values (3,'C')
	into ca.pwcharacters (id, symbol) values (4,'D')
	into ca.pwcharacters (id, symbol) values (5,'E')
	into ca.pwcharacters (id, symbol) values (6,'F')
	into ca.pwcharacters (id, symbol) values (7,'G')
	into ca.pwcharacters (id, symbol) values (8,'H')
	into ca.pwcharacters (id, symbol) values (9,'I')
	into ca.pwcharacters (id, symbol) values (10,'J')
	into ca.pwcharacters (id, symbol) values (11,'K')
	into ca.pwcharacters (id, symbol) values (12,'L')
	into ca.pwcharacters (id, symbol) values (13,'M')
	into ca.pwcharacters (id, symbol) values (14,'N')
	into ca.pwcharacters (id, symbol) values (15,'O')
	into ca.pwcharacters (id, symbol) values (16,'P')
	into ca.pwcharacters (id, symbol) values (17,'Q')
	into ca.pwcharacters (id, symbol) values (18,'R')
	into ca.pwcharacters (id, symbol) values (19,'S')
	into ca.pwcharacters (id, symbol) values (20,'T')
	into ca.pwcharacters (id, symbol) values (21,'U')
	into ca.pwcharacters (id, symbol) values (22,'V')
	into ca.pwcharacters (id, symbol) values (23,'W')
	into ca.pwcharacters (id, symbol) values (24,'X')
	into ca.pwcharacters (id, symbol) values (25,'Y')
	into ca.pwcharacters (id, symbol) values (26,'Z')
	into ca.pwcharacters (id, symbol) values (27,'a')
	into ca.pwcharacters (id, symbol) values (28,'b')
	into ca.pwcharacters (id, symbol) values (29,'c')
	into ca.pwcharacters (id, symbol) values (30,'d')
	into ca.pwcharacters (id, symbol) values (31,'e')
	into ca.pwcharacters (id, symbol) values (32,'f')
	into ca.pwcharacters (id, symbol) values (33,'g')
	into ca.pwcharacters (id, symbol) values (34,'h')
	into ca.pwcharacters (id, symbol) values (35,'i')
	into ca.pwcharacters (id, symbol) values (36,'j')
	into ca.pwcharacters (id, symbol) values (37,'k')
	into ca.pwcharacters (id, symbol) values (38,'l')
	into ca.pwcharacters (id, symbol) values (39,'m')
	into ca.pwcharacters (id, symbol) values (40,'n')
	into ca.pwcharacters (id, symbol) values (41,'o')
	into ca.pwcharacters (id, symbol) values (42,'p')
	into ca.pwcharacters (id, symbol) values (43,'q')
	into ca.pwcharacters (id, symbol) values (44,'r')
	into ca.pwcharacters (id, symbol) values (45,'s')
	into ca.pwcharacters (id, symbol) values (46,'t')
	into ca.pwcharacters (id, symbol) values (47,'u')
	into ca.pwcharacters (id, symbol) values (48,'v')
	into ca.pwcharacters (id, symbol) values (49,'w')
	into ca.pwcharacters (id, symbol) values (50,'x')
	into ca.pwcharacters (id, symbol) values (51,'y')
	into ca.pwcharacters (id, symbol) values (52,'z')
	into ca.pwcharacters (id, symbol) values (53,'1')
	into ca.pwcharacters (id, symbol) values (54,'2')
	into ca.pwcharacters (id, symbol) values (55,'3')
	into ca.pwcharacters (id, symbol) values (56,'4')
	into ca.pwcharacters (id, symbol) values (57,'5')
	into ca.pwcharacters (id, symbol) values (58,'6')
	into ca.pwcharacters (id, symbol) values (59,'7')
	into ca.pwcharacters (id, symbol) values (60,'8')
	into ca.pwcharacters (id, symbol) values (61,'9')
	into ca.pwcharacters (id, symbol) values (62,'0')
	into ca.pwcharacters (id, symbol) values (63,'%')
	into ca.pwcharacters (id, symbol) values (64,'+')
	into ca.pwcharacters (id, symbol) values (65,'!')
	into ca.pwcharacters (id, symbol) values (66,'#')
	into ca.pwcharacters (id, symbol) values (67,'$')
	into ca.pwcharacters (id, symbol) values (68,'^')
	into ca.pwcharacters (id, symbol) values (69,'?')
	into ca.pwcharacters (id, symbol) values (70,':')
	into ca.pwcharacters (id, symbol) values (71,'[')
	into ca.pwcharacters (id, symbol) values (72,']')
	into ca.pwcharacters (id, symbol) values (73,'~')
	into ca.pwcharacters (id, symbol) values (74,'-')
	into ca.pwcharacters (id, symbol) values (75,'_')
	into ca.pwcharacters (id, symbol) values (76,'.')
select * from dual;
commit;




create or replace procedure ca.pw (
	  in_pw_qty    in number default 3
	, in_pw_length in number default 14
)
is
	l_maxid        number(3);
	l_pw_qty_count number(3);
	l_pw_qty_count number(3);
	l_pw           varchar2(32767);
	l_char         char(1);
begin
	dbms_output.put_line(chr(10));
	
	/* find out how many characters we have to choose from */
	select max(id)
	into   l_maxid
	from   ca.pwcharacters;

	for l_pw_qty_count in 1..in_pw_qty loop
		l_pw := to_char(l_pw_qty_count)||': ';
		for l_pw_qty_count in 1..in_pw_length loop
			/* select a random character */
			select symbol
			into   l_char
			from   ca.pwcharacters
			where  id=ceil(dbms_random.value(0,l_maxid));
			
			/* add it to the pw string */
			l_pw := l_pw||l_char;
		end loop;

		/* print the pw */
		dbms_output.put_line(l_pw);
	end loop;
	
	dbms_output.put_line(chr(10));
end;
/

exit;