SET NOCOUNT ON;

CREATE TABLE #indexmap
  (
       INSTANCE_name  NVARCHAR(500),
       Database_name  NVARCHAR(500),
       Table_Name     NVARCHAR(500),
       Table_id       INT,
       index_name     NVARCHAR(500),
       index_id       INT,
       total_accesses BIGINT,
       seeks          BIGINT,
       scans          BIGINT,
       lookups        BIGINT,
       ROWS           BIGINT
  );

CREATE TABLE #databaseindexmap
  (
       INSTANCE_name NVARCHAR(500),
       Database_name NVARCHAR(500),
       Table_Name    NVARCHAR (500),
       Table_ID      INT,
       index_name    NVARCHAR(500),
       index_id      INT,
       ROWS          BIGINT
  );

CREATE TABLE #mainindexmap
  (
       INSTANCE_name  NVARCHAR(500),
       Database_name  NVARCHAR(500),
       TYPE           VARCHAR(100),
       Table_Name     NVARCHAR(500),
       Table_id       INT,
       index_name     NVARCHAR(500),
       index_id       INT,
       total_accesses BIGINT,
       seeks          BIGINT,
       scans          BIGINT,
       lookups        BIGINT,
       ROWS           BIGINT
  );

DECLARE
    @database_name VARCHAR(500),
    @CMD           NVARCHAR(MAX);

DECLARE dblist CURSOR FOR
    SELECT NAME
    FROM   sys.databases
    WHERE  NAME NOT IN ('master', 'tempdb', 'model', 'msdb', 'distribution')
    --WHERE  NAME IN ('plaid')
    ORDER  BY NAME;

OPEN dblist;

FETCH NEXT FROM dblist INTO @database_name;

WHILE(@@FETCH_STATUS = 0)
    BEGIN
        --	print   @database_name
        SELECT @CMD = '
					use [' + @database_name + ']' + CHAR(13) + '
					insert #indexmap
					select
					@@SERVERNAME,
					db_name(),
					iv.Table_Name,
					iv.object_id Table_id,
					isnull(i.name,''Table Scan'') as index_name,
					i.index_id,
					iv.seeks + iv.scans + iv.lookups as total_accesses,
					iv.seeks,
					iv.scans,
					iv.lookups,
					sum(p.rows)   over   (partition by i.object_id,i.index_id)  [Rows]
					from
					(
							select
							i.object_id,
							object_name(i.object_id) as Table_Name,
							i.index_id,
							sum(i.user_seeks) as seeks,
							sum(i.user_scans) as scans,
							sum(i.user_lookups) as lookups
							from
							sys.tables t
							inner join sys.dm_db_index_usage_stats i
							on t.object_id = i.object_id
							group by
							i.object_id,
							i.index_id
					) as iv
					inner join sys.indexes i on iv.object_id = i.object_id
					and iv.index_id = i.index_id
					inner join sys.partitions p on i.index_id=p.index_id
					and		i.object_id=p.object_id
					order by i.index_id 

					insert #databaseindexmap
					select @@SERVERNAME,db_name(),object_name(i.object_id) Table_Name,i.object_id Table_ID,i.name index_name,i.index_id,sum(p.rows)   over   (partition by i.object_id,i.index_id)  [Rows]   
					from sys.indexes i inner join sys.partitions p on i.index_id=p.index_id	and		i.object_id=p.object_id
					where  i.index_id<>0  ---------------{ list of table with their indexes within database excluding tables iwth table scan }
					-------------------------------------------------------------------------------------------------------------------------------------------------{return all tables without any index, which dose table scan} 
					declare @table_Heap_scans int
					set nocount on 
					select @table_Heap_scans=count(*) from #indexmap where index_name=''table scan''
					print ''Database [' + @database_name + '] ------------------------------------------------- Total number of Tables without any indexs ( Heap Table Scan ) : ''+convert (varchar(10),@table_Heap_scans)
					
					insert #mainindexmap
					select INSTANCE_name,Database_name,''Table Scan Only'',Table_Name,Table_id,index_name,index_id,total_accesses,seeks,scans,lookups,Rows from #indexmap  where index_name=''table scan'' and rows>1000 --order by scans desc
					union
					-------------------------------------------------------------------------------------------------------------------------------------------------{return all the clustered indexes  which do more table scan than using the index} 
					select INSTANCE_name,Database_name,''Index are not getting used efficiently (scan>seeks)'',Table_Name,Table_id,index_name,index_id,total_accesses,seeks,scans,lookups,Rows from #indexmap where index_id=1 and scans>seeks and rows>1000 --order by scans-seeks desc
					union
					-------------------------------------------------------------------------------------------------------------------------------------------------{return all the tables that the indexes are not getting used} 
					select INSTANCE_name,Database_name,''Indexes not being used at all'',Table_Name,Table_ID,index_name,index_id,0 total_accesses,0 seeks,0 scans,0 lookups,Rows
					from #databaseindexmap i where i.Table_Name+'':''+i.index_name not in (select Table_Name+'':''+index_name from #indexmap ) and i.Table_Name not like ''sys%'' and i.rows>10 --order by i.rows  desc
					';

        EXECUTE sp_executesql
            @cmd;

        DELETE #indexmap;

        DELETE #databaseindexmap;

        FETCH NEXT FROM dblist INTO @database_name;
    END;

CLOSE dblist;

DEALLOCATE dblist;

SELECT *
FROM   #mainindexmap;

DROP TABLE #indexmap;

DROP TABLE #mainindexmap;

DROP TABLE #databaseindexmap; 
