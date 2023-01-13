SET NOCOUNT ON;
--************** If no table changes, then no need to check in this script ****************-- 
DECLARE @TablesRequired TABLE (
	 TableSchema VARCHAR(500)
    ,TableName VARCHAR(500))

DECLARE @GlobalFilter TABLE (
	 TableSchema VARCHAR(500)
	,TableName  VARCHAR(500)
	,Filter VARCHAR(MAX) ) 

--************** Developers Require to change this part******************--
DECLARE 
	 @database_type AS VARCHAR(50)= 'Transfer' -- Global, Regional or Transfer ** Change accordingly **

INSERT INTO @TablesRequired(
	 TableSchema
    ,TableName)
VALUES 
		 ('Genealogy','Association')
	    ,('UnitSetup','UnitHeader')
	    

----Insert into this table only got filters in Global database articles. Enable it only if requires. 

--INSERT INTO @GlobalFilter(
--	 TableSchema
--    ,TableName
--    ,Filter)
--  VALUES
--	 ('Audit','Audit','NOT EXISTS (SELECT * FROM Part.ItemHeader AS ih WHERE ih.ItemHeaderId = Part.RevisionCustomer.ItemHeaderId AND ih.IsItar = 1)')
--	,('Working','AgileInterfacePartLoad','Select Top 1 * From Audit.RevisionCustomer')

--************** Developers Require to change this part******************--




DECLARE 
	 @vcPublication_Name AS VARCHAR(50)
	,@vcGetDatabaseType AS VARCHAR(50) 
	,@vcTableSchema AS VARCHAR(500)
	,@vcTableName AS VARCHAR(500)
	,@nvcSchema_option AS NVARCHAR(250) 
	,@vcGlobalFilterValue AS VARCHAR(MAX)
	,@nvcSql AS NVARCHAR(MAX)
	,@nvcTransferFilterValue AS NVARCHAR(500) -- its only meant for transfer database

-- Step 1 : Verify the script is executing on proper environment. 
IF (DB_NAME() LIKE '%Global%')
	BEGIN
		SET @vcGetDatabaseType='Global'
		SET @nvcSchema_option='0x000000000807109F'	
	END

IF (DB_NAME() LIKE '%Transfer%')
	BEGIN
		SET @vcGetDatabaseType='Transfer'
		SET @nvcSchema_option='0x000000010203008D'
	END
	
IF (DB_NAME() LIKE '%GSF2_%')
	BEGIN
		SET @vcGetDatabaseType='Regional'
		SET @nvcSchema_option='0x000000010203008F'
	END



IF (@database_type<>@vcGetDatabaseType)
	BEGIN
		RAISERROR('Script either executing on wrong database or provided wrong value for "@database_type" variable.',16,1);
		RETURN;
	END

-- Step 2 : Get Publication details  



DECLARE @Publication AS TABLE (
	Publication_Name VARCHAR(50)
    ,PublicationId INT)

INSERT INTO @Publication
SELECT 
	 sp.name
    ,sp.pubid
FROM 
	dbo.syspublications AS sp




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
END


-- Step 4 : Verify articles that are inserting are not exists in article list 
IF EXISTS
		(
		 SELECT 
			 1
		 FROM 
			 dbo.sysarticles AS a
			 INNER JOIN @Publication AS p
				 ON a.pubid = p.PublicationId
			 INNER JOIN @TablesRequired AS t
				 ON t.TableName = a.dest_table
				    AND t.TableSchema = a.dest_owner
		) 
BEGIN
	RAISERROR('Some of the articles are already exists in Publication. Please verify.',16,1);
	RETURN;
END






DECLARE curAddArticle CURSOR 	
	FOR
		SELECT 
			publication_Name
		FROM
			@Publication

	OPEN curAddArticle
	FETCH NEXT FROM curAddArticle INTO @vcPublication_Name

	WHILE (@@FETCH_STATUS=0)
		BEGIN
			DECLARE curGenerateArticleScript CURSOR
			FOR
				SELECT
					 tr.TableSchema
					,tr.Tablename
					,gf.Filter
				FROM
					@TablesRequired AS tr
					LEFT JOIN @GlobalFilter AS gf
						ON tr.tablename=gf.tablename
						AND tr.TableSchema=gf.TableSchema
						
			OPEN curGenerateArticleScript
			FETCH NEXT FROM curGenerateArticleScript INTO @vcTableSchema,@vcTableName,@vcGlobalFilterValue
		
			WHILE (@@FETCH_STATUS=0)
				BEGIN

					
					IF (@database_type='Regional' AND @vcGetDatabaseType='Regional')
						BEGIN
						
						SET @nvcsql = '
									exec sp_addarticle 
											@publication=N'''+@vcPublication_Name+'''
										   ,@article=N'''+@vcTableName+'''
										   ,@source_owner=N'''+@vcTableSchema+'''
										   ,@source_object=N'''+@vcTableName+'''
										   ,@type = N''logbased''
										   ,@description = N''''
										   ,@creation_script = null
										   ,@pre_creation_cmd = N''none''
										   ,@schema_option ='+@nvcSchema_option+'
										   ,@identityrangemanagementoption = N''manual''
										   ,@destination_table =N'''+@vcTableName+'''
										   ,@destination_owner =N'''+@vcTableSchema+'''
										   ,@vertical_partition = N''false''
										   ,@ins_cmd =N'' CALL [dbo].[sp_MSins_'+@vcTableSchema+@vcTableName+']''
										   ,@del_cmd = N''CALL [dbo].[sp_MSdel_'+@vcTableSchema+@vcTableName+']''
										   ,@upd_cmd = N''SCALL [dbo].[sp_MSupd_'+@vcTableSchema+@vcTableName+']'';
									
									exec sp_refreshsubscriptions @publication = N'''+@vcPublication_Name+''';
									'
						
						EXEC SP_EXECUTESQL @nvcsql
						END			
					
					IF (@database_type='Global' AND @vcGetDatabaseType='Global')		
						BEGIN
						SET @nvcSql = '
										exec sp_addarticle 
												@publication=N'''+@vcPublication_Name+'''
											   ,@article=N'''+@vcTableName+'''
											   ,@source_owner=N'''+@vcTableSchema+'''
											   ,@source_object=N'''+@vcTableName+'''
											   ,@type = N''logbased''
											   ,@description = N''''
											   ,@creation_script = null
											   ,@pre_creation_cmd = N''drop''
											   ,@schema_option ='+@nvcSchema_option+'
											   ,@identityrangemanagementoption = N''manual''
											   ,@destination_table =N'''+@vcTableName+'''
											   ,@destination_owner =N'''+@vcTableSchema+'''
											   ,@vertical_partition = N''false''
											   ,@ins_cmd =N'' CALL [dbo].[sp_MSins_'+@vcTableSchema+@vcTableName+']''
											   ,@del_cmd = N''CALL [dbo].[sp_MSdel_'+@vcTableSchema++']''
											   ,@upd_cmd = N''SCALL [dbo].[sp_MSupd_'+@vcTableSchema+@vcTableName+']'';
										'
						IF ((@vcPublication_Name LIKE '%APAC%' OR @vcPublication_Name LIKE '%XIAM%' OR @vcPublication_Name LIKE '%CHINA%')
							AND (@vcGlobalFilterValue IS NOT NULL OR @vcGlobalFilterValue<>''))
								BEGIN
								SET @nvcSQL=@nvcSQL+
											'
											EXEC sp_articlefilter 
												 @publication = N'''+@vcPublication_Name+'''
												,@article = N'''+@vcTableName+'''
												,@filter_name = N''FLTR_'+@vcTableName+'_'+@vcPublication_Name+'''
												,@filter_clause = '''+@vcGlobalFilterValue+'''
												,@force_invalidate_snapshot = 1
												,@force_reinit_subscription = 1'
								
								SET @nvcSQL=@nvcSQL+
											'
											EXEC sp_articleview 
												@publication = N'''+@vcPublication_Name+'''
												,@article = N'''+@vcTableName+'''
												,@view_name = N''SYNC_'+@vcTableName+'_'+@vcPublication_Name+'''
												,@filter_clause = '''+@vcGlobalFilterValue+'''
												,@force_invalidate_snapshot = 1
												,@force_reinit_subscription = 1'
											
								END
							
						
						SET @nvcSQL=@nvcSql+'
											
											exec sp_refreshsubscriptions @publication = N'''+@vcPublication_Name+''';
											'
										
						EXEC SP_EXECUTESQL @nvcsql
						
						
						END
					
					IF (@database_type='Transfer' AND @vcGetDatabaseType='Transfer')
						BEGIN
							SELECT TOP 1
								@nvcTransferFilterValue= a.filter_clause
							FROM
								dbo.sysarticles AS a
								INNER JOIN dbo.syspublications AS p
									ON a.pubId=p.pubId
							WHERE
								p.name=@vcPublication_Name
						
							SET @nvcSQL='
										EXEC sp_addarticle 
											 @publication = N'''+@vcPublication_Name+'''
											,@article = N'''+@vcTableName+'''
											,@source_owner = N'''+@vcTableSchema+'''
											,@source_object = N'''+@vcTableName+'''
											,@type = N''logbased''
											,@description = N''''
											,@creation_script = NULL
											,@pre_creation_cmd = N''none''
											,@schema_option ='+@nvcSchema_option+'
											,@force_invalidate_snapshot = 1
											,@identityrangemanagementoption = N''manual''
											,@destination_table = N'''+@vcTableName+'''
											,@destination_owner = N'''+@vcTableSchema+'''
											,@status = 24
											,@vertical_partition = N''false''
											,@ins_cmd = N''SQL''
											,@del_cmd = N''NONE''
											,@upd_cmd = N''NONE'';'
							
							SET @nvcSQL=@nvcSQL+'
										EXEC sp_articlecolumn 
											@publication =N'''+@vcPublication_Name+'''
											,@article =  N'''+@vcTableName+'''
											,@column = N''RegionalSqlServerId''
											,@operation = N''drop''
											,@force_invalidate_snapshot = 1
											,@force_reinit_subscription = 1;'
							SET @nvcSQL=@nvcSQL+'
	 									EXEC sp_articlefilter 
											 @publication = N'''+@vcPublication_Name+'''
											,@article = N'''+@vcTableName+'''
											,@filter_name = N''FLTR_'+@vcTableName+'_'+@vcPublication_Name +'''
											,@filter_clause = N'''+@nvcTransferFilterValue+'''
											,@force_invalidate_snapshot = 1
											,@force_reinit_subscription = 1;'
							SET @nvcSQL=@nvcSQL+'
										EXEC sp_articleview 
											 @publication =  N'''+@vcPublication_Name+'''
											,@article = N'''+@vcTableName+'''
											,@view_name = N''SYNC_'+@vcTableName+'_'+@vcPublication_Name +'''
											,@filter_clause =N'''+@nvcTransferFilterValue+'''
											,@force_invalidate_snapshot = 1
											,@force_reinit_subscription = 1;'

							EXEC SP_EXECUTESQL @nvcSQL
						END
					
					FETCH NEXT FROM curGenerateArticleScript INTO @vcTableSchema,@vcTableName,@vcGlobalFilterValue
				END
			CLOSE curGenerateArticleScript
			DEALLOCATE curGenerateArticleScript

			FETCH NEXT FROM curAddArticle INTO @vcPublication_Name
		END
	
	CLOSE curAddArticle
	DEALLOCATE curAddArticle
	
	