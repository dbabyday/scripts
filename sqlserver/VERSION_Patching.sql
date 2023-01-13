DECLARE 
	@Vers				VARCHAR(400),
	@Start				INT,
	@End				INT,
	@Length				INT,
	@VersionDescription	VARCHAR(128),
	@Build				VARCHAR(25),
	@DesiredPatch		VARCHAR(25);

-- get the version description
SET @Vers				= @@VERSION;
SET @Start				= CHARINDEX( 'SQL', @Vers );
SET @End				= CHARINDEX(  ' -', @Vers );
SET @VersionDescription	= SUBSTRING(@Vers, @Start, @End - @Start);

-- get the version (build number)
SET @Start  = CHARINDEX( ' - ', @Vers ) + 3;
IF (CHARINDEX(' (X', @Vers) > 0)
	SET @Length = CHARINDEX( ' (X', @Vers ) - @Start;
ELSE
	SET @Length	= CHARINDEX( ' (', @Vers ) - @Start;
SET @Build = SUBSTRING(@Vers, @Start, @Length);

-- get the desired patch level
SELECT @DesiredPatch = 
	CASE
		WHEN LEFT(@Build, 2) = '9.'   THEN '9.00.5000.00'
		WHEN LEFT(@Build, 4) = '10.0' THEN '10.00.6000.29'
		WHEN LEFT(@Build, 4) = '10.5' THEN '10.50.6000.34'
		WHEN LEFT(@Build, 2) = '11'   THEN '11.0.6020'
		WHEN LEFT(@Build, 2) = '12'   THEN '12.0.4100.1'
	END;

SELECT 
	@@SERVERNAME AS [Server], 
	@VersionDescription AS [Version Description], 
	@Build AS [Version], 
	@DesiredPatch AS [Desired Patch Level];
