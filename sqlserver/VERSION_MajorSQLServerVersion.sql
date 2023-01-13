DECLARE 
	@Vers	VARCHAR(400),
	@Start	INT,
	@Length	INT;

SELECT @Vers	= @@VERSION;
SELECT @Start	= CHARINDEX( '-', @Vers );
SELECT @Length	= CHARINDEX( ' (X', @Vers ) - @Start -2;

SELECT 
	@@SERVERNAME AS [Server],
	CASE SUBSTRING(@Vers, @Start, 6)
		WHEN '- 7.0.' THEN '7.0'
		WHEN '- 8.00' THEN '2000'
		WHEN '- 9.00' THEN '2005'
		WHEN '- 10.0' THEN '2008'
		WHEN '- 10.5' THEN '2008 R2'
		WHEN '- 11.0' THEN '2012'
		WHEN '- 12.0' THEN '2014'
		WHEN '- 13.0' THEN '2016'
		ELSE 'Other'
	END AS [Version],
	SERVERPROPERTY('Edition') AS [Edition],
	SUBSTRING(@Vers, @Start + 2, @Length) AS [Build];
