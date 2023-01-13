DECLARE @dbname VARCHAR(255);
SET @dbname = ''; --<----- Enter the database name

DECLARE @dbinfo TABLE
(
	[ParentObject] VARCHAR(255),
	[Object] VARCHAR(255),
	[Field] VARCHAR(255),
	[Value] VARCHAR(255)
)

INSERT INTO @dbinfo
EXECUTE('DBCC DBINFO (' + @dbname + ') WITH TABLERESULTS')

SELECT 
    @dbname,
    [Field], 
	[Value]
FROM
    @dbinfo
WHERE
    Field = 'dbi_dbccLastKnownGood'