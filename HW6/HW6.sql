/* **************************************************************************************** */
-- when set, it prevents potentially dangerous updates and deletes
set SQL_SAFE_UPDATES=0;

-- when set, it disables the enforcement of foreign key constraints.
set FOREIGN_KEY_CHECKS=0;
use HW6;
/* **************************************************************************************** 
-- These control:
--     the maximum time (in seconds) that the client will wait while trying to establish a 
	   connection to the MySQL server 
--     how long the client will wait for a response from the server once a request has 
       been sent over
**************************************************************************************** */
SHOW SESSION VARIABLES LIKE '%timeout%';       
SET GLOBAL mysqlx_connect_timeout = 600;
SET GLOBAL mysqlx_read_timeout = 600;

-- Create the accounts table
CREATE TABLE accounts (
  account_num CHAR(6) PRIMARY KEY,    -- 5-digit account number (e.g., 00001, 00002, ...)
  branch_name VARCHAR(50),            -- Branch name (e.g., Brighton, Downtown, etc.)
  balance DECIMAL(10, 2),             -- Account balance, with two decimal places (e.g., 1000.50)
  account_type VARCHAR(50)            -- Type of the account (e.g., Savings, Checking)
);
DROP TABLE accounts;

/* ***************************************************************************************************
The procedure generates 50,000 records for the accounts table, with the account_num padded to 5 digits.
branch_name is randomly selected from one of the six predefined branches.
balance is generated randomly, between 0 and 100,000, rounded to two decimal places.
***************************************************************************************************** */
-- Change delimiter to allow semicolons inside the procedure
DELIMITER $$

CREATE PROCEDURE generate_accounts()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE branch_name VARCHAR(50);
  DECLARE account_type VARCHAR(50);
  
  -- Loop to generate 50,000 account records
  WHILE i <= 150000 DO
    -- Randomly select a branch from the list of branches
    SET branch_name = ELT(FLOOR(1 + (RAND() * 6)), 'Brighton', 'Downtown', 'Mianus', 'Perryridge', 'Redwood', 'RoundHill');
    
    -- Randomly select an account type
    SET account_type = ELT(FLOOR(1 + (RAND() * 2)), 'Savings', 'Checking');
    
    -- Insert account record
    INSERT INTO accounts (account_num, branch_name, balance, account_type)
    VALUES (
      LPAD(i, 6, '0'),                   -- Account number as just digits, padded to 5 digits (e.g., 00001, 00002, ...)
      branch_name,                       -- Randomly selected branch name
      ROUND((RAND() * 100000), 2),       -- Random balance between 0 and 100,000, rounded to 2 decimal places
      account_type                       -- Randomly selected account type (Savings/Checking)
    );

    SET i = i + 1;
  END WHILE;
END$$

-- Reset the delimiter back to the default semicolon
DELIMITER ;

-- ******************************************************************
-- execute the procedure
-- ******************************************************************
CALL generate_accounts();

select count(*) from accounts;

select * from accounts limit 10;

select branch_name, count(*)
from accounts
group by branch_name
order by branch_name;

-- ****************************************************************************************
-- If you frequently run queries that filter or sort by both branch_name and account_type, 
-- creating a composite index on these two columns can improve performance.
-- ****************************************************************************************
SHOW INDEXES from accounts;
CREATE INDEX idx_branch ON accounts (branch_name);
DROP INDEX idx_branch ON accounts;
CREATE INDEX idx_account ON accounts (account_type);
DROP INDEX idx_account ON accounts;
CREATE INDEX idx_balance ON accounts (balance);
DROP INDEX idx_balance ON accounts;
CREATE INDEX idx_bal_branch ON accounts (balance, branch_name);
DROP INDEX idx_bal_branch on accounts;

-- ****************************************************************************************
-- Create a stored procedure to measure average execution time
-- ****************************************************************************************
DELIMITER $$

CREATE PROCEDURE GetAvgTime(IN query_text TEXT)
BEGIN
	-- DECLARE total_time DOUBLE DEFAULT 0;
    DECLARE start_time DOUBLE;
    DECLARE end_time DOUBLE;
    DECLARE execution_time_microseconds DOUBLE;
    DECLARE total_time BIGINT DEFAULT 0;
    DECLARE avg_time_microseconds DOUBLE;
    DECLARE i INT DEFAULT 1;
    SET @qry = query_text;
    -- Prepare the query
    PREPARE stmt FROM @qry;
    
    WHILE i <= 10 DO
		SET start_time = NOW(6);
		-- Execute the prepared statement
		EXECUTE stmt;
		SET end_time = NOW(6);

		SET total_time = total_time + TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
        
        SET i = i + 1;
	END WHILE;
	-- Clean up the prepared statement
	DEALLOCATE PREPARE stmt;
    
    SET avg_time_microseconds = total_time/10.0;
    SELECT avg_time_microseconds;
END $$

DELIMITER ;

-- ****************************************************************************************
-- Call the stored procedure
-- ****************************************************************************************
-- Point Query
SELECT count(*) FROM accounts WHERE branch_name = "Downtown" AND balance = 41250.19;
CALL GetAvgTime('SELECT count(*) FROM accounts WHERE account_type = "Savings" AND balance = 89780.22');
SELECT count(*) FROM accounts WHERE balance = 20000;
CALL GetAvgTime('SELECT count(*) FROM accounts WHERE balance = 20000');
SELECT count(*) FROM accounts WHERE balance = 5000;
CALL GetAvgTime('SELECT count(*) FROM accounts WHERE balance = 5000');
-- Range Query
SELECT count(*) FROM accounts WHERE branch_name = "Downtown" AND balance BETWEEN 50000 AND 100000;
CALL GetAvgTime('SELECT count(*) FROM accounts WHERE branch_name = "Downtown" AND balance BETWEEN 50000 AND 100000');
SELECT count(*) FROM accounts WHERE account_type = 'Savings' AND balance BETWEEN 90000 AND 100000;
CALL GetAvgTime('SELECT count(*) FROM accounts WHERE account_type = "Savings" AND balance BETWEEN 90000 AND 100000');
SELECT count(*) FROM accounts WHERE account_type = 'Savings' AND balance BETWEEN 1000 AND 5000;
CALL GetAvgTime('SELECT count(*) FROM accounts WHERE balance BETWEEN 1000 AND 5000');

-- ******************************************************************************************
-- Timing analysis
-- ******************************************************************************************
-- Step 1: Capture the start time with microsecond precision (6)
SET @start_time = NOW(6);

-- Step 2: Run the query you want to measure
SELECT count(*) FROM accounts 
WHERE balance BETWEEN 1000 AND 5000;

-- Step 3: Capture the end time with microsecond precision
SET @end_time = NOW(6);

-- Step 4: Calculate the difference in microseconds
SELECT 
    TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) AS execution_time_microseconds,
    TIMESTAMPDIFF(SECOND, @start_time, @end_time) AS execution_time_seconds;
    
    
