

USE [];
GO

-- orphaned users
SELECT
	[dp].[name],
	'DROP USER [' + [dp].[name] + '];'
FROM 
	[sys].[database_principals] AS dp
LEFT JOIN 
	[sys].[server_principals] AS sp
	ON [dp].[sid] = [sp].[sid]
WHERE
	[dp].[type] IN ('U','S','G')
	AND [dp].[name] NOT IN ('dbo','guest','INFORMATION_SCHEMA','sys')
	AND [sp].[sid] IS NULL;


/*
-- schemas and objects with specific schema owners
SELECT
	o.name AS [object],
	o.type_desc AS [ObjectType],
	s.name AS [schema],
	USER_NAME(s.principal_id) AS [SchemaOwner]
FROM 
	sys.schemas AS s
LEFT OUTER JOIN 
	sys.objects AS o
	ON [o].[schema_id] = [s].[schema_id]
WHERE
	USER_NAME(s.principal_id) IN	(	'',
										''
									);
--*/