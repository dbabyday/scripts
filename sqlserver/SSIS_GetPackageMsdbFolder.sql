USE msdb;

DECLARE @packageId AS UNIQUEIDENTIFIER;

IF OBJECT_ID('tempdb..#SsisPackages',N'U') IS NOT NULL DROP TABLE #SsisPackages;
CREATE TABLE #SsisPackages
(
    id             UNIQUEIDENTIFIER NOT NULL,
    name           SYSNAME          NOT NULL,
    verbuild       INT              NULL,
    folder         NVARCHAR(1000)   NULL,
    parentfolderid UNIQUEIDENTIFIER NULL
);


INSERT INTO #SsisPackages ( id, name, verbuild, folder, parentfolderid )
SELECT p.id,
       p.name,
       p.verbuild,
       f.foldername,
       f.parentfolderid
FROM   dbo.sysssispackages       AS p
JOIN   dbo.sysssispackagefolders AS f ON f.folderid = p.folderid

WHILE EXISTS(SELECT 1 FROM #SsisPackages WHERE parentfolderid IS NOT NULL AND parentfolderid <> '00000000-0000-0000-0000-000000000000')
BEGIN
    SELECT TOP(1) @packageId = id
    FROM   #SsisPackages
    WHERE  parentfolderid IS NOT NULL 
           AND parentfolderid <> '00000000-0000-0000-0000-000000000000';

    UPDATE t
    SET    t.folder = f.foldername + N'\' + t.folder,
           t.parentfolderid = f.parentfolderid
    FROM   #SsisPackages AS t
    JOIN   dbo.sysssispackagefolders AS f ON f.folderid = t.parentfolderid
    WHERE  t.id = @packageId
END;

SELECT   name,
         folder,
         verbuild
FROM     #SsisPackages
--WHERE    name IN ( N'' )
ORDER BY name,
         verbuild,
         folder;

         

IF OBJECT_ID('tempdb..#SsisPackages',N'U') IS NOT NULL DROP TABLE #SsisPackages;


