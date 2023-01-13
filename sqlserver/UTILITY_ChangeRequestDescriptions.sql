-- CHANGE REQUEST DESCRIPTIONS

DECLARE @ServerName  NVARCHAR(128) = N'CO-DB-025',
        @Drive       NCHAR(1)      = N'G',
        @CurrentGB   INT           = 140,
        @TargetGB    INT           = 250;

SELECT UPPER(@ServerName) + N' - Add ' + CAST(@TargetGB - @CurrentGB AS NVARCHAR(10)) + N' GB to ' + @Drive + N':\ Drive'
UNION
SELECT N'Please add ' + CAST(@TargetGB - @CurrentGB AS NVARCHAR(10)) + N' GB to ' + @Drive + N':\ drive on ' + LOWER(@ServerName) + N' to accommodate database file growth.
The drive is currently ' + CAST(@CurrentGB AS NVARCHAR(10)) + N' GB, the target is ' + CAST(@TargetGB AS NVARCHAR(10)) + N' GB.';

