SET NOCOUNT ON;
--************** If no table changes, then no need to check in this script ****************-- 
DECLARE @TablesRequired TABLE (
	TableSchema VARCHAR(500)
    ,TableName VARCHAR(500));

--************** Developers Require to change only this part *********************--
--************** This Script is only applicable to Regional and Transfer database ******************--

DECLARE @database_type AS VARCHAR(50) = 'Global'; -- Regional or Transfer ** Change accordingly ***

INSERT INTO @TablesRequired(
	TableSchema
    ,TableName)
VALUES ('Part','ItemDetail'),
       ('Part','RevisionInternal')
          
--************** Developers Require to change only this part ******************--

DECLARE @vcPublication_Name AS VARCHAR(50)
	  ,@vcGetDatabaseType AS VARCHAR(50)
	  ,@vcTableSchema AS VARCHAR(500)
	  ,@vcTableName AS VARCHAR(500)
	  ,@nvcSql AS NVARCHAR(MAX);

-- Step 1 : Verify the script is executing on proper environment. 

IF (DB_NAME() LIKE '%Transfer%') 
BEGIN
	SET @vcGetDatabaseType = 'Transfer';
END;
IF (DB_NAME() LIKE '%GSF2_%') 
BEGIN
	SET @vcGetDatabaseType = 'Regional';
END;
IF (DB_NAME() LIKE '%GsfGlobal_%') 
BEGIN
	SET @vcGetDatabaseType = 'Global';
END;
IF
   (@database_type <> @vcGetDatabaseType
   ) 
BEGIN
	RAISERROR('Script either executing on wrong database or provided wrong value for "@database_type" variable.',16,1);
	RETURN;
END;
IF (@vcGetDatabaseType = ''
    OR @vcGetDatabaseType IS NULL) 
BEGIN
	RAISERROR('Script is executing on wrong database',16,1);
	RETURN;
END;    

-- Step 2 : Get Publication details  

DECLARE @Publication AS TABLE (
	Publication_Name VARCHAR(50)
    ,PublicationId INT);
INSERT INTO @Publication
SELECT 
	sp.name
    ,sp.pubid
FROM 
	dbo.syspublications AS sp;
      
-- Step 3 : Verify all of the tables are exist in database

IF EXISTS
		(
		 SELECT 
			 1
		 FROM 
			 @TablesRequired AS tr
			 LEFT JOIN INFORMATION_SCHEMA.TABLES AS sct
				 ON tr.TableName = sct.TABLE_NAME
				    AND tr.TableSchema = sct.TABLE_SCHEMA
		 WHERE sct.TABLE_NAME IS NULL
		) 
BEGIN
	RAISERROR('Some of the tables are not exists in database. Please verify and create those tables before executing this script.',16,1);
	RETURN;
END;

-- Step 4 : Verify all the articles that dropped are members of publication

IF EXISTS
		(
		 SELECT 
			 1
		 FROM 
			 @TablesRequired AS t
			 LEFT JOIN dbo.sysarticles AS a
				 ON t.TableName = a.dest_table
				    AND t.TableSchema = a.dest_owner
			 LEFT JOIN @Publication AS p
				 ON a.pubid = p.PublicationId
		 WHERE a.dest_table IS NULL
		) 
BEGIN
	RAISERROR('Some of the articles are not exists in Publication. Please verify before dropping articles',16,1);
	RETURN;
END;
DECLARE curAddArticle CURSOR
FOR SELECT 
	    publication_Name
    FROM 
	    @Publication;
OPEN curAddArticle;
FETCH NEXT FROM curAddArticle INTO @vcPublication_Name;
WHILE
	 (@@FETCH_STATUS = 0
	 ) 
BEGIN
	DECLARE curGenerateArticleScript CURSOR
	FOR SELECT 
		    tr.TableSchema
		   ,tr.Tablename
	    FROM 
		    @TablesRequired AS tr;
	OPEN curGenerateArticleScript;
	FETCH NEXT FROM curGenerateArticleScript INTO @vcTableSchema
										,@vcTableName;
	WHILE
		 (@@FETCH_STATUS = 0
		 ) 
	BEGIN
		SET @nvcSQL =
		'
                                                exec sp_dropsubscription 
                                                       @publication='''+@vcPublication_Name+''''+',@article='''+@vcTableName+''''+
		', @subscriber=N''all'';';
		SET @nvcSQL = @nvcSQL+
		'
                                                exec sp_dropArticle
                                                @publication='''+@vcPublication_Name+''''+',@article='''+@vcTableName+''';';
                                                
                        
		--PRINT @nvcSQL
		EXEC SP_EXECUTESQL 
			@nvcSQL;
		FETCH NEXT FROM curGenerateArticleScript INTO @vcTableSchema
											,@vcTableName;
	END;
	CLOSE curGenerateArticleScript;
	DEALLOCATE curGenerateArticleScript;
	FETCH NEXT FROM curAddArticle INTO @vcPublication_Name;
END;
CLOSE curAddArticle;
DEALLOCATE curAddArticle;
