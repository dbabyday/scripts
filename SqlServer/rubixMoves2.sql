/* USER INPUT: how many moves do you want? */
DECLARE @qty INT = 100;

DROP TABLE IF EXISTS #face;
DROP TABLE IF EXISTS #turn;

DROP TABLE IF EXISTS #results;
CREATE TABLE #results (id int identity, the_move varchar(2));


DECLARE
	  @rand int
	, @face varchar(1)
	, @turn varchar(1)
	, @U INT = 0
	, @D INT = 0
	, @F INT = 0
	, @B INT = 0
	, @L INT = 0
	, @R INT = 0;

WHILE (SELECT COUNT(*) FROM #results) < @qty
BEGIN
	SET @rand = CAST((RAND(CHECKSUM(NEWID())) * 6) + 1 AS INT);
	SET @face =
		CASE @rand
			WHEN 1 THEN 'U'
			WHEN 2 THEN 'D'
			WHEN 3 THEN 'F'
			WHEN 4 THEN 'B'
			WHEN 5 THEN 'L'
			WHEN 6 THEN 'R'
			ELSE 'X'
		END;
		
	SET @rand = CAST((RAND(CHECKSUM(NEWID())) * 3) + 1 AS INT);
	SET @turn =
		CASE @rand
			WHEN 1 THEN ''
			WHEN 2 THEN '2'
			WHEN 3 THEN '`'
			ELSE 'Y'
		END;

	IF @face = 'U'
	BEGIN
		IF @U = 1
			CONTINUE;

		SELECT @U = 1, @F=0, @B=0, @L=0, @R=0;
		INSERT #results (the_move) VALUES (@face + @turn);
	END;

	IF @face = 'D'
	BEGIN
		IF @D = 1
			CONTINUE;

		SELECT @D = 1, @F=0, @B=0, @L=0, @R=0;
		INSERT #results (the_move) VALUES (@face + @turn);
	END;

	IF @face = 'F'
	BEGIN
		IF @F = 1
			CONTINUE;

		SELECT @F = 1, @U=0, @D=0, @L=0, @R=0;
		INSERT #results (the_move) VALUES (@face + @turn);
	END;

	IF @face = 'B'
	BEGIN
		IF @B = 1
			CONTINUE;

		SELECT @B = 1, @U=0, @D=0, @L=0, @R=0;
		INSERT #results (the_move) VALUES (@face + @turn);
	END;

	IF @face = 'L'
	BEGIN
		IF @L = 1
			CONTINUE;

		SELECT @L = 1, @F=0, @B=0, @U=0, @D=0;
		INSERT #results (the_move) VALUES (@face + @turn);
	END;

	IF @face = 'R'
	BEGIN
		IF @R = 1
			CONTINUE;

		SELECT @R = 1, @F=0, @B=0, @U=0, @D=0;
		INSERT #results (the_move) VALUES (@face + @turn);
	END;
END;


WITH 
	results_segmented AS (
		SELECT the_move, id
		FROM #results
		UNION ALL
		SELECT '---------' AS the_move, id + 0.1
		FROM #results
		WHERE id % 5 = 0
	  )
SELECT the_move
FROM results_segmented
ORDER BY id;




