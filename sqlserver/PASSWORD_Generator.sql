set nocount on;


/* user input */
declare	  @qtyPwds as int = 2
	, @length  as int = 30;



/* verify input */
if (@length<3)
begin
	print 'Length must be at least 3 to get at least one letter, one digit, and one special character';
	return;
end;


/* other variables */
declare	  @i     as int = 0
	, @j     as int = 0
	, @maxId as int
	, @pw    as varchar(max) = '';



/* holds the characters */
if object_id(N'tempdb..#characters', N'U') is not null drop table #characters;
create table #characters (
	  id     int identity(1,1) not null primary key
	, symbol char(1)           not null
);

/* holds the passwords we create */
if object_id(N'tempdb..#passwords', N'U') is not null drop table #passwords;
create table #passwords (pw varchar(max) not null);



/* the characters from which we will randomly choose */
insert #characters (symbol) 
values ('A'), ('B'), ('C'), ('D'), ('E'), ('F'), ('G'), ('H'), ('I'), ('J'), ('K'), ('L'), ('M'), ('N'), ('O'), ('P'), ('Q'), ('R'), ('S'), ('T'), ('U'), ('V'), ('W'), ('X'), ('Y'), ('Z')
     , ('a'), ('b'), ('c'), ('d'), ('e'), ('f'), ('g'), ('h'), ('i'), ('j'), ('k'), ('l'), ('m'), ('n'), ('o'), ('p'), ('q'), ('r'), ('s'), ('t'), ('u'), ('v'), ('w'), ('x'), ('y'), ('z')
     , ('1'), ('2'), ('3'), ('4'), ('5'), ('6'), ('7'), ('8'), ('9'), ('0')
     , ('%'), ('+'), ('!'), ('#'), ('$'), ('^'), ('?'), (':'), ('['),  (']'), ('~'), ('-'), ('_'), ('.');



/* find out how many characters we have to choose from using rand() */
select @maxId = max(id) from #characters;

/* create the specified number of passwords */
set @i = 0;
while @i < @qtyPwds
begin
	/* add random characters until we reach the specified length */
	set @pw = '';
	while len(@pw) < @length
		select @pw += symbol from #characters where id = ceiling(rand(checksum(newid())) * @maxId);
print @pw;
	/* check if the password contains a number, a letter, and a special character */
	if (  @pw like '%[0-9]%'
	      and @pw like '%[A-Za-z]%'
	      and @pw like '%[^A-Za-z0-9]%'
	   )
	begin
		/* if yes, enter the pw into our list */
		insert into #passwords (pw) VALUES ( @pw );
		set @i += 1;
	end;
end;
    



/* display the resutls */
select pw from #passwords;




/* clean up */
if object_id(N'tempdb..#characters', N'U') is not null drop table #characters;
if object_id(N'tempdb..#passwords', N'U') is not null drop table #passwords;




