USE CentralAdmin;
GO
/*
T-SQL Scalar Function to Calculate Time Difference

This function calculates the difference between two DATETIME parameters in total seconds,
then converts that value into a formatted string representing the time in days, hours,
minutes, and seconds.
*/
CREATE OR ALTER FUNCTION dbo.GetTimeDifferenceFormatted (
    @startDate DATETIME,
    @endDate DATETIME
)
RETURNS VARCHAR(50)
AS
BEGIN
    -- Declare variables to hold the total seconds and the breakdown of time units.
    DECLARE @totalSeconds BIGINT;
    DECLARE @days INT;
    DECLARE @hours INT;
    DECLARE @minutes INT;
    DECLARE @seconds INT;
    DECLARE @result VARCHAR(50);

    -- Calculate the total difference in seconds.
    -- Using DATEDIFF on seconds is the most reliable way to get a precise difference.
    SET @totalSeconds = DATEDIFF(second, @startDate, @endDate);

    -- Handle cases where the end date is earlier than the start date.
    IF @totalSeconds < 0
    BEGIN
        SET @totalSeconds = ABS(@totalSeconds);
        SET @result = '-';
    END
    ELSE
    BEGIN
        SET @result = '';
    END

    -- Calculate the number of full days.
    SET @days = @totalSeconds / 86400; -- 60 sec/min * 60 min/hr * 24 hr/day
    SET @totalSeconds = @totalSeconds % 86400;

    -- Calculate the remaining hours.
    SET @hours = @totalSeconds / 3600; -- 60 sec/min * 60 min/hr
    SET @totalSeconds = @totalSeconds % 3600;

    -- Calculate the remaining minutes.
    SET @minutes = @totalSeconds / 60;
    SET @totalSeconds = @totalSeconds % 60;

    -- The remaining seconds are the final value.
    SET @seconds = @totalSeconds;

    -- Format the output string. Use `RIGHT` and `REPLICATE` for zero-padding hours, minutes, and seconds.
    SET @result = @result +
                  CAST(@days AS VARCHAR(10)) + 'd ' +
                  RIGHT('0' + CAST(@hours AS VARCHAR(2)), 2) + ':' +
                  RIGHT('0' + CAST(@minutes AS VARCHAR(2)), 2) + ':' +
                  RIGHT('0' + CAST(@seconds AS VARCHAR(2)), 2);

    -- Return the formatted string.
    RETURN @result;
END;
GO