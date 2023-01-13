-- Convert Hexadecimal to Decimal

DECLARE 
	-- USER INPUT
	@hexadecimal VARCHAR(25) = 'Fa8', 

	-- other variables
	@decimal     INT         = 0,
	@digit       VARCHAR(2),
	@i           INT         = 0,
	@length      INT;

-- get the length of the hexadecimal value
SELECT @length = LEN(@hexadecimal);

-- loop through each digit of the hexadecimal value
WHILE @i < @length
BEGIN
	-- get the digit, starting from the right and working towar the left
	SELECT @digit = SUBSTRING(@hexadecimal,@length-@i,1);

	-- conver the letter digits to an integer value
	SELECT @digit = CASE UPPER(@digit)
						WHEN 'A' THEN '10'
						WHEN 'B' THEN '11'
						WHEN 'C' THEN '12'
						WHEN 'D' THEN '13'
						WHEN 'E' THEN '14'
						WHEN 'F' THEN '15'
						ELSE @digit
					END

	-- determine the value of the digit based on its location and add it to the decimal value
	SET @decimal += CAST(@digit AS INT) * POWER(16,@i);

	SET @i += 1;
END

SELECT @decimal;