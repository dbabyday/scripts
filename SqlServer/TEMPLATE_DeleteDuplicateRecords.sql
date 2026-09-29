/* https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/development/remove-duplicate-rows-sql-server-tab */

DELETE T
FROM
	(
		SELECT
			  *
			, DupRank = ROW_NUMBER() OVER (
				PARTITION BY key_value 
				ORDER BY (SELECT NULL)
			  )
		FROM
			original_table
	) AS T
WHERE DupRank > 1