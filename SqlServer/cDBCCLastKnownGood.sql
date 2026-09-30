DECLARE @dbname varchar(255);
SET @dbname = ''; --<----- Enter the database name

CREATE TABLE #dbinfo
(
	[ParentObject] varchar(255),
	[Object] varchar(255),
	[Field] varchar(255),
	[Value] varchar(255)
)

INSERT INTO #dbinfo
EXECUTE('DBCC DBINFO (' + @dbname + ') WITH TABLERESULTS')

SELECT 
    @dbname,
    [Field], 
	[Value]
FROM
    #dbinfo
WHERE
    Field = 'dbi_dbccLastKnownGood'
