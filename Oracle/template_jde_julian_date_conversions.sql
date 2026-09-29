

/* Convert Gregorian date to JDE Julian date */
SELECT TO_NUMBER(TO_CHAR(TO_DATE(your_gregorian_date_string, 'DD-MON-YYYY'), 'RRRR') - 1900 || TO_CHAR(TO_DATE(your_gregorian_date_string, 'DD-MON-YYYY'), 'DDD')) AS jde_julian_date
FROM dual;


/* Convert JDE Julian date to Gregorian date */
SELECT TO_DATE(TO_CHAR(your_jde_julian_date_column + 1900000), 'YYYYDDD') AS gregorian_date
FROM your_table_name;


