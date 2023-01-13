USE [tempdb];
GO

SELECT
	df.name,
	CAST(ROUND(df.size / 128.0,0) AS INT) AS 'size_df_MB',
	CAST(ROUND(mf.size / 128.0,0) AS INT) AS 'size_mf_MB',
	CAST(ROUND((df.size - mf.size) / 128.0,0) AS INT) AS 'difference_MB',
	df.physical_name
FROM
	sys.database_files AS df
LEFT OUTER JOIN
	sys.master_files AS mf
	ON df.name = mf.name
ORDER BY
	df.name;