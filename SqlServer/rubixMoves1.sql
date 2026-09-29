/* USER INPUT: how many moves do you want? If more than 800, you should add another CROSS JOIN to the random_XXXX CTEs */
DECLARE @qty INT = 100;

WITH
	  face AS (
		SELECT id, the_face 
		FROM (VALUES (1,'U'),(2,'D'),(3,'F'),(4,'B'),(5,'L'),(6,'R')) AS tbl(id,the_face)
	  )
	, turn AS (
		SELECT id, the_turn 
		FROM (VALUES (1,' '),(2,''''),(3,'2')) AS tbl(id,the_turn)
	  )
	, random_face AS (
		SELECT TOP(10000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS id, CAST((RAND(CHECKSUM(NEWID())) * 6) + 1 AS INT) AS one_through_six
		FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t1(n)        /* 10 rows */
		CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t2(n)  /* 10 rows (Total: 100) */
		CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t3(n)  /* 10 rows (Total: 1,000) */
	  )
	, random_turn AS (
		SELECT TOP(10000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS id, CAST((RAND(CHECKSUM(NEWID())) * 3) + 1 AS INT) AS one_through_three
		FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t1(n)        /* 10 rows */
		CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t2(n)  /* 10 rows (Total: 100) */
		CROSS JOIN (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t3(n)  /* 10 rows (Total: 1,000) */
	  )
	, combined AS (
		SELECT rf.id, f.the_face, t.the_turn, LAG(f.the_face, 1) OVER (ORDER BY rf.id) AS previous_face
		FROM random_face rf
		INNER JOIN random_turn rt ON rt.id = rf.id
		INNER JOIN face f ON f.id=rf.one_through_six
		INNER JOIN turn t ON t.id=rt.one_through_three
	  )
	, results AS (
		SELECT TOP(@qty) the_face + the_turn AS the_move, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS id
		FROM combined
		WHERE the_face <> previous_face
		ORDER BY id
	  )
	, results_segmented AS (
		SELECT the_move, id
		FROM results
		UNION ALL
		SELECT '---------' AS the_move, id + 0.1
		FROM results
		WHERE id % 5 = 0
	  )
SELECT the_move
FROM results_segmented
ORDER BY id;



