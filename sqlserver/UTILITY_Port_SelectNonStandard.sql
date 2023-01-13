-- randomly select non-standard port

DECLARE @min INT = 49152,
        @max INT = 65535;

SELECT CEILING(RAND(CHECKSUM(NEWID()))*(@max-@min+1)) + @min - 1;