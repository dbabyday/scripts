DECLARE @disk INT

-- SET @disk = 50 --single disk
SET @disk = 200 -- SAN disk

;WITH t1 (countertime, avgTransfer, diskBytes, ReadWrites, DataBytes)
     AS (SELECT 
             h.counterdatetime,
             SUM(CASE
                     WHEN d.CounterID = 3 THEN CONVERT(DECIMAL(10, 5), h.CounterValue)
                     ELSE 0
                 END),
             SUM(CASE
                     WHEN d.CounterID = 9 THEN CONVERT(DECIMAL(10,2), h.CounterValue/1000000.0)
                     ELSE 0
                 END),
             SUM(CASE
                     WHEN d.CounterID IN (14,15) THEN CONVERT(DECIMAL(18,2), h.CounterValue)
                     ELSE 0
                 END),
             SUM(CASE
                     WHEN d.CounterID = 13 THEN CONVERT(DECIMAL(18,2), h.CounterValue/1000000.0)
                     ELSE 0
                 END)
         FROM   
             counterdata h
             JOIN counterdetails d ON d.counterid = h.CounterID
         WHERE  
             d.counterid IN (3, 9, 13, 15, 16)
         GROUP BY 
             h.counterdatetime)

SELECT 
    t1.countertime  AS 'Time',
    t1.avgTransfer  AS 'Avg. Disk sec/Transfer',
    t1.diskBytes    AS 'Disk MB/sec',
    t1.ReadWrites   AS 'Page RW/sec',
    t1.DataBytes    AS 'IO Data MB/Sec',
    CASE
        WHEN t1.avgTransfer > 0.015 AND t1.diskBytes <= @disk THEN 'Potential I/O subsystem bottleneck.'
        WHEN t1.avgTransfer > 0.015 AND t1.diskBytes > @disk THEN 'Application I/O'
        ELSE ''
    END             AS 'Resolution'
FROM 
    t1 
ORDER BY 
    1 DESC
