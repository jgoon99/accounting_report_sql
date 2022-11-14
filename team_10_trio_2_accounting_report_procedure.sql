/* ***************************************
 * Name of Project: A2: Case - Rosas Palas Franchise (Pairs/Trios)
 * Due Nov 13th, Sunday by 10pm
 * TEAM 10 - Beverages
 * TRIO 2. 
 * *************************************** */

/* ********************************************************************************************************************************
	 *	Requirement Definition
	 * ----------------------------------------
	 * 1. Receive as an argument the year for which the user wants to produce the P&L and B/S statements.
	 * 2. Do the necessary calculations to obtain the net profit or loss for that year
	 * 3. Use that value, to produce the B/S
	 * 4. Demonstrate that A = L + E
	 * 5. Print both the P&L and B/S as clear as possible on the Result Grids
	 * 6. Show the % change vs. the previous year for every major line item on the P&L and B/S
	 * 7. Give some headings to each major account line item. And to each section of the P&L and B/S
	 * 8. Add any additional financial metrics and ratios that could be useful to analyze this start-up 
	 * 9. Produce a cash flow statement  as an added challenge
	 * 10. The stored procedure must have comprehensive comments explaining the purpose of each block of code
	 * -----------------------------------------
	 * 
	 * *********************************************************************************************************************************/

/* -------------------------------------------------------------------------------------
	Build Report of P&L Statments
   ------------------------------------------------------------------------------------- */
	   
-- BUILDING BASEMANT TABLE FOR ANALYZE
--	DEFINE BASE TABLE 
DELIMITER $$

-- EXISTING PROCEDURE CHECK AND DROP
DROP PROCEDURE IF EXISTS team_10_trio_2_account_report$$

-- CREATE PROCEDURE START 
/* *****************************************************************************************
 * PROCEDURE NAME: team_10_trio_2_account_report
 * INPUTS:
 * 	1. fn_year: INT DEFAULT = 2016; 
 *		2. type_of_report: CHAR(1) [Y: Annual Report | M: Monthly Report | Q: Quater Report for PNL | DEFALUT: Y]
 ******************************************************************************************* */
CREATE PROCEDURE team_10_trio_2_account_report( IN fn_year INT, IN type_of_report CHAR(1)) 
BEGIN -- Begin 

-- Declare Global Variables
SET @line_break = '----------------------------'; -- For result grid 
SET @report_pnl = 'Profit and Loss Report'; -- Report Title
SET @fn_year = IF(IFNULL(fn_year, 2016) BETWEEN 2014 AND 2020, fn_year, 2016);
SET @last_year = @fn_year - 1;
SET @report_type = IF(IFNULL(type_of_report, 'Y') IN ('Y', 'M', 'Q'), type_of_report, 'Y');

-- Drop Temp Table 
DROP TABLE IF EXISTS ychoung_tmp;

-- Create Temp Table
CREATE TABLE ychoung_tmp (
	`f_type` TINYINT COMMENT 'Usage filed type',
	`entry_year` INT COMMENT 'Year of entry dates',
	`entry_month` CHAR(7) COMMENT 'Year and month of entry_dates',
	`entry_quater` CHAR(7) COMMENT 'Year and quater of entry_dates',
	`entry_date` DATETIME COMMENT 'Entry date',
	`journal_entry_id` INT DEFAULT 0 COMMENT 'KEY for journal_entry',
	`journal_entry` VARCHAR(255) COMMENT 'Transaction names', 
	`line_item` INT COMMENT 'SEQUENCE NUMBER OF ENTRY',
	`description` VARCHAR(100) COMMENT 'Entry descrition',
	`account` VARCHAR(100) COMMENT 'account information',
	`statement` VARCHAR(50) COMMENT 'statements categories',
	`debit_is_positive` TINYINT COMMENT '[0: debit is negative | 1: debit is Positive ] for PNL',
	`is_balance_sheet_section` TINYINT COMMENT '[0: PNL Statements | 1: B/S statements ] ',
	`debit` DOUBLE COMMENT 'debit',
	`credit` DOUBLE COMMENT 'credit',
	`assets` DOUBLE COMMENT 'ASSETS',
	`liabilities` DOUBLE COMMENT 'LIABILITIES',
	`equity` DOUBLE COMMENT 'EQUITY',
	`comp_no` TINYINT COMMENT 'PRINTING ORDER',
	`components` VARCHAR(50) COMMENT 'Components of PNL Reports Filed',
	`M00` DOUBLE COMMENT 'Monthly_report Last year Dec',
	`M01` DOUBLE COMMENT 'Monthly_report jan',
	`M02` DOUBLE COMMENT 'Monthly_report feb',
	`M03` DOUBLE COMMENT 'Monthly_report mar',
	`M04` DOUBLE COMMENT 'Monthly_report apr',
	`M05` DOUBLE COMMENT 'Monthly_report may',
	`M06` DOUBLE COMMENT 'Monthly_report jun',
	`M07` DOUBLE COMMENT 'Monthly_report jul',
	`M08` DOUBLE COMMENT 'Monthly_report aug',
	`M09` DOUBLE COMMENT 'Monthly_report sep',
	`M10` DOUBLE COMMENT 'Monthly_report oct',
	`M11` DOUBLE COMMENT 'Monthly_report nov',
	`M12` DOUBLE COMMENT 'Monthly_report dec',
	`Q0` DOUBLE COMMENT 'Quater_report Last year Q4',
	`Q1` DOUBLE COMMENT 'Quater_report Q1',
	`Q2` DOUBLE COMMENT 'Quater_report Q2',
	`Q3` DOUBLE COMMENT 'Quater_report Q3',
	`Q4` DOUBLE COMMENT 'Quater_report Q4',
	KEY idx_enry_date (`f_type`, `entry_year`, `entry_quater`, `entry_month`, `entry_date`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT 'Basement table for ';

-- Insert into base date for building report
INSERT 
  INTO	ychoung_tmp(
			`f_type`, entry_year, entry_month, entry_quater, entry_date, journal_entry_id, journal_entry, line_item, `description`,
			`account`, `statement`, `debit_is_positive`, `is_balance_sheet_section`, debit, credit, assets, liabilities, equity
		)
SELECT	0 AS f_type
		,DATE_FORMAT(b.entry_date, '%Y') AS entry_year 
		,DATE_FORMAT(b.entry_date, '%Y-%m') AS entry_month
		,CASE 
			WHEN MONTH(b.entry_date) BETWEEN 1 AND 3 THEN CONCAT(DATE_FORMAT(b.entry_date, '%Y-'), 'Q1')
			WHEN MONTH(b.entry_date) BETWEEN 4 AND 6 THEN CONCAT(DATE_FORMAT(b.entry_date, '%Y-'), 'Q2')
			WHEN MONTH(b.entry_date) BETWEEN 7 AND 9 THEN CONCAT(DATE_FORMAT(b.entry_date, '%Y-'), 'Q3')
			WHEN MONTH(b.entry_date) BETWEEN 10 AND 12 THEN CONCAT(DATE_FORMAT(b.entry_date, '%Y-'), 'Q4')
			END AS entry_quater
		,b.entry_date
		,a.journal_entry_id
		,b.journal_entry
		,a.line_item
		,a.description
		,c.`account`
		,IF(d.statement_section != '', d.statement_section, e.statement_section) AS statement
		,d.debit_is_positive
		,d.is_balance_sheet_section
		,IFNULL(a.debit, 0) AS debit
		,IFNULL(a.credit, 0) AS credit
		,ROUND(
			CASE 
				WHEN IF(d.statement_section != '', d.statement_section, e.statement_section) IN ('CURRENT ASSETS','FIXED ASSETS') AND credit IS NULL 
					THEN IFNULL(debit, 0) 
				WHEN IF(d.statement_section != '', d.statement_section, e.statement_section) IN ('CURRENT ASSETS','FIXED ASSETS') AND debit IS NULL 
					THEN IFNULL(credit, 0) * -1 
				ELSE 0 
			END, 2 ) AS ASSETS
		,ROUND(
			CASE 
				WHEN IF(d.statement_section != '', d.statement_section, e.statement_section) IN ('CURRENT LIABILITIES') AND credit IS NULL 
					THEN IFNULL(debit, 0) * -1 
				WHEN IF(d.statement_section != '', d.statement_section, e.statement_section) IN ('CURRENT LIABILITIES') AND debit IS NULL 
					THEN IFNULL(credit, 0) 
				ELSE 0 
			END, 2) AS LIABILITIES
		,ROUND(
			CASE 
				WHEN IF(d.statement_section != '', d.statement_section, e.statement_section) IN ( 'REVENUE', 'OTHER INCOME', 'COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX', 'EQUITY' ) AND credit IS NULL 
					THEN IFNULL(debit, 0) * -1 
				WHEN IF(d.statement_section != '', d.statement_section, e.statement_section) IN ( 'REVENUE', 'OTHER INCOME', 'COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX', 'EQUITY' ) AND debit IS NULL 
					THEN IFNULL(credit, 0) 
				ELSE 0 
			END, 2 ) AS EQUITY
  FROM	journal_entry_line_item AS a
  JOIN	journal_entry AS b
    ON	a.journal_entry_id = b.journal_entry_id
  JOIN	`account` AS c
    ON	a.account_id = c.account_id
  JOIN	statement_section AS d
    ON	c.profit_loss_section_id = d.statement_section_id
  JOIN	statement_section AS e
    ON	c.balance_sheet_section_id = e.statement_section_id
 WHERE	b.cancelled = 0
 			AND b.debit_credit_balanced = 1
			AND b.closing_type = 0
 ORDER
 	 BY	entry_date;

-- Insert into Main Components of PNL Report
INSERT 
  INTO	ychoung_tmp(`f_type`, comp_no, components) 
SELECT	1 AS f_type, 0 ,@report_pnl AS components
		UNION ALL
		SELECT	1, 1, 'PERIOD'
		UNION ALL
		SELECT 	1, 2, @line_break
		UNION ALL
		SELECT	1, 3, 'TOTAL REVENUE' 
		UNION ALL 
		SELECT	1, 4, 'REVENUE'
		UNION ALL
		SELECT	1, 5, 'OTHER INCOME'
		UNION ALL
		SELECT	1, 6, @line_break
		UNION ALL
		SELECT	1, 7, 'COST OF GOODS AND SERVICES'
		UNION ALL
		SELECT	1, 8, 'GROSS PROFIT MARGIN'
		UNION ALL
		SELECT	1, 9, 'GROSS PROFIT MARGIN %'
		UNION ALL
		SELECT	1, 10, @line_break
		UNION ALL
		SELECT	1, 11, 'OEXP'
		UNION ALL
		SELECT	1, 12, 'OTHER EXPENSES'
		UNION ALL
		SELECT	1, 13, 'SELLING EXPENSES'
		UNION ALL
		SELECT	1, 14, @line_break
		UNION ALL
		SELECT	1, 15, 'EBITDA MARGIN'
		UNION ALL
		SELECT	1, 16, 'EBITDA %'
		UNION ALL
		SELECT	1, 17, @line_break
		UNION ALL
		SELECT	1, 18, 'Depreciation & Ammortization'
		UNION ALL
		SELECT	1, 19, 'EBIT'
		UNION ALL
		SELECT	1, 20, 'EBIT %'
		UNION ALL
		SELECT	1, 21, @line_break
		UNION ALL
		SELECT	1, 22, 'INCOME TAX'
		UNION ALL
		SELECT	1, 23, 'NET INCOME'
		UNION ALL
		SELECT	1, 24, 'NET INCOME %'
		UNION ALL
		SELECT	1, 25, @line_break
	;

/* -------------------------------------------------------------------------------------
	  	Build Report of PNL Report
   ------------------------------------------------------------------------------------- */
   -- report_type Variable Check
	IF @report_type = 'M' THEN
		/* --------------------------------------------------------------------------------------------------------------------------
			MONTHLY REPORT FOR PNL: START
		-----------------------------------------------------------------------------------------------------------------------------*/
		-- Insert Monthly PNL data from financial year and last month of last year. 
		INSERT	
		  INTO	ychoung_tmp (f_type, statement, M01, M02, M03, M04, M05, M06, M07, M08, M09, M10, M11, M12, M00)
		SELECT	a.*
					,b.amount
		  FROM	(
				SELECT	2
						,statement
						,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
							WHEN RIGHT(entry_month, 2) = '01' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
							WHEN RIGHT(entry_month, 2) = '01' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
							END 
						), 2) AS JAN
						,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
							WHEN RIGHT(entry_month, 2) = '02' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
							WHEN RIGHT(entry_month, 2) = '02' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
							END 
						), 2) AS FEB
						,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
							WHEN RIGHT(entry_month, 2) = '03' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
							WHEN RIGHT(entry_month, 2) = '03' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
							END 
						), 2) AS MAR
						,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
							WHEN RIGHT(entry_month, 2) = '04' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
							WHEN RIGHT(entry_month, 2) = '04' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
							END 
						), 2) AS APL
						,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
							WHEN RIGHT(entry_month, 2) = '05' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
							WHEN RIGHT(entry_month, 2) = '05' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
							END 
						), 2) AS MAY
						,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
							WHEN RIGHT(entry_month, 2) = '06' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
							WHEN RIGHT(entry_month, 2) = '06' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
							END 
						), 2) AS JUN
						,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
							WHEN RIGHT(entry_month, 2) = '07' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
							WHEN RIGHT(entry_month, 2) = '07' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
							END 
						), 2) AS JUL
						,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
							WHEN RIGHT(entry_month, 2) = '08' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
							WHEN RIGHT(entry_month, 2) = '08' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
							END 
						), 2) AS AUG
						,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
							WHEN RIGHT(entry_month, 2) = '09' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
							WHEN RIGHT(entry_month, 2) = '09' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
							END 
						), 2) AS SEP
						,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
							WHEN RIGHT(entry_month, 2) = '10' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
							WHEN RIGHT(entry_month, 2) = '10' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
							END 
						), 2) AS `OCT`
						,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
							WHEN RIGHT(entry_month, 2) = '11' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
							WHEN RIGHT(entry_month, 2) = '11' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
							END 
						), 2) AS NOV
						,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
							WHEN RIGHT(entry_month, 2) = '12' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
							WHEN RIGHT(entry_month, 2) = '12' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
							END 
						), 2) AS `DEC`
					FROM	ychoung_tmp
					WHERE	entry_year = @fn_year 
					GROUP
						BY	statement
				) AS a
		  LEFT
		  JOIN	( -- Last year last month. for MoM Growth of Jan
		  			SELECT	statement
								,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
									WHEN RIGHT(entry_month, 2) = '12' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
				               WHEN RIGHT(entry_month, 2) = '12' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
				            END 
								), 2) AS amount
					  FROM	ychoung_tmp
					 WHERE	entry_year = @last_year 
					 GROUP
					 	 BY	statement
		  			) AS b
		  	 ON	a.statement = b.statement
		;
		 	 
		
		-- BUILDING REPORT ---------------------------------------------------------------------------------------------------- 
		SELECT	TITLE.components
					-- JAN Report
					,CASE 
						WHEN M01 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(M01, 0),2)
						ELSE IFNULL(M01, 0) END AS JAN
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'MoM Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(M01 - M00, 2)
						ELSE ROUND((M01 - M00)/ABS(M00)*100,2)END, 0) AS `JAN Growth`
					-- FEB Report
					,CASE 
						WHEN M02 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(M02, 0),2)
						ELSE IFNULL(M02, 0) END AS FEB
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'MoM Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(M02 - M01, 2)
						ELSE ROUND((M02 - M01)/ABS(M01)*100,2)END, 0) AS `FEB Growth`
					-- MAR Report
					,CASE 
						WHEN M03 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(M03, 0),2)
						ELSE IFNULL(M03, 0) END AS MAR
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'MoM Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(M03 - M02, 2)
						ELSE ROUND((M03 - M02)/ABS(M02)*100,2)END, 0) AS `MAR Growth`
					-- APR Report
					,CASE 
						WHEN M04 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(M04, 0),2)
						ELSE IFNULL(M04, 0) END AS APR
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'MoM Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(M04 - M03, 2)
						ELSE ROUND((M04 - M03)/ABS(M03)*100,2)END, 0) AS `APR Growth`
					-- MAY Report
					,CASE 
						WHEN M05 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(M05, 0),2)
						ELSE IFNULL(M05, 0) END AS MAY
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'MoM Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(M05 - M04, 2)
						ELSE ROUND((M05 - M04)/ABS(M04)*100,2)END, 0) AS `MAY Growth`
					-- JUN Report
					,CASE 
						WHEN M06 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(M06, 0),2)
						ELSE IFNULL(M06, 0) END AS JUN
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'MoM Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(M06 - M05, 2)
						ELSE ROUND((M06 - M05)/ABS(M05)*100,2)END, 0) AS `JUN Growth`
					-- JUL Report
					,CASE 
						WHEN M07 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(M07, 0),2)
						ELSE IFNULL(M07, 0) END AS JUL
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'MoM Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(M07 - M05, 2)
						ELSE ROUND((M07 - M06)/ABS(M06)*100,2)END, 0) AS `JUL Growth`
					-- AUG Report
					,CASE 
						WHEN M08 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(M08, 0),2)
						ELSE IFNULL(M08, 0) END AS AUG
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'MoM Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(M08 - M05, 2)
						ELSE ROUND((M08 - M07)/ABS(M07)*100,2)END, 0) AS `AUG Growth`
					-- SEP Report 
					,CASE 
						WHEN M09 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(M09, 0),2)
						ELSE IFNULL(M09, 0) END AS SEP
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'MoM Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(M09 - M05, 2)
						ELSE ROUND((M09 - M08)/ABS(M08)*100,2)END, 0) AS `SEP Growth`
					-- OCT Report
					,CASE 
						WHEN M10 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(M10, 0),2)
						ELSE IFNULL(M10, 0) END AS `OCT`
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'MoM Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(M10 - M05, 2)
						ELSE ROUND((M10 - M09)/ABS(M09)*100,2)END, 0) AS `OCT Growth`
					-- NOV Report
					,CASE 
						WHEN M11 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(M11, 0),2)
						ELSE IFNULL(M11, 0) END AS NOV
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'MoM Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(M11 - M05, 2)
						ELSE ROUND((M11 - M10)/ABS(M10)*100,2)END, 0) AS `NOV Growth`
					-- DEC Report
					,CASE 
						WHEN M12 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(M12, 0),2)
						ELSE IFNULL(M12, 0) END AS `DEC`
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'MoM Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(M12 - M05, 2)
						ELSE ROUND((M12 - M11)/ABS(M11)*100,2)END, 0) AS `DEC Growth`
		  FROM	( -- BASE COMPONENTS OF PNL REPORT
					SELECT	components
								,comp_no
					  FROM	ychoung_tmp
					 WHERE	f_type = 1
				) AS TITLE
		  LEFT
		  JOIN	( -- THIS YEAR MONTHLY REPORT ADN LAST YEAR LAST MONTH(M00)
		  			SELECT	statement, M00, M01, M02, M03, M04, M05, M06, M07, M08, M09, M10, M11, M12
		  			  FROM	ychoung_tmp
		  			 WHERE	f_type = 2
		  			 UNION ALL
					SELECT	@line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break
					 UNION ALL
					SELECT	'PERIOD', @fn_year, '', '', '', '', '', '', '', '', '', '', '', ''
					 UNION ALL
					SELECT	@report_pnl, '', '', '', '', '', '', '', '', '', '', '', '', ''
					 UNION ALL
					SELECT	'TOTAL REVENUE'
								,ROUND(SUM(M00), 2)
								,ROUND(SUM(M01), 2)
								,ROUND(SUM(M02), 2)
								,ROUND(SUM(M03), 2)
								,ROUND(SUM(M04), 2)
								,ROUND(SUM(M05), 2)
								,ROUND(SUM(M06), 2)
								,ROUND(SUM(M07), 2)
								,ROUND(SUM(M08), 2)
								,ROUND(SUM(M09), 2)
								,ROUND(SUM(M10), 2)
								,ROUND(SUM(M11), 2)
								,ROUND(SUM(M12), 2)
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 			AND statement IN ('REVENUE','OTHER INCOME')
					 UNION ALL
					SELECT	'GROSS PROFIT MARGIN'
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M00, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M00, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M01, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M01, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M02, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M02, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M03, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M03, 0) * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M04, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M04, 0) * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M05, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M05, 0) * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M06, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M06, 0) * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M07, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M07, 0) * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M08, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M08, 0) * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M09, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M09, 0) * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M10, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M10, 0) * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M11, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M11, 0) * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M12, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M12, 0) * -1
										ELSE 0 END)
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'GROSS PROFIT MARGIN %'
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M00, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M00, 0)  * -1
										ELSE 0 END)
								 / SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M00, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M01, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M01, 0)  * -1
										ELSE 0 END)
								 / SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M01, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M02, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M02, 0)  * -1
										ELSE 0 END)
								 / SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M02, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M03, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M03, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M03, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M04, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M04, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M04, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M05, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M05, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M05, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M06, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M06, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M06, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M07, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M07, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M07, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M08, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M08, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M08, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M09, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M09, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M09, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M10, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M10, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M10, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M11, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M11, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M11, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M12, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(M12, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M12, 0)  
										ELSE 0 END) * 100
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'OEXP'
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M00, 0) 
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M01, 0) 
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M02, 0) 
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M03, 0)
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M04, 0)
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M05, 0)
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M06, 0)
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M07, 0)
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M08, 0)
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M09, 0)
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M10, 0)
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M11, 0)
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M12, 0)
										ELSE 0 END)
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'EBITDA MARGIN'
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M00, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M00, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M01, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M01, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M02, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M02, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M03, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M03, 0) * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M04, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M04, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M05, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M05, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M06, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M06, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M07, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M07, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M08, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M08, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M09, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M09, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M10, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M10, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M11, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M11, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M12, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M12, 0)  * -1
										ELSE 0 END)
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'EBITDA %'
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M00, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M00, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M00, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M01, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M01, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M01, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M02, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M02, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M02, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M03, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M03, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M03, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M04, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M04, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M04, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M05, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M05, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M05, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M06, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M06, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M06, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M07, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M07, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M07, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M08, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M08, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M08, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M09, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M09, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M09, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M10, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M10, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M10, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M11, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M11, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M11, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M12, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M12, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M12, 0)  
										ELSE 0 END) * 100
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'Depreciation & Ammortization',0 ,0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
					 UNION ALL
					SELECT	'EBIT'
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M00, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M00, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M01, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M01, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M02, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M02, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M03, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M03, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M04, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M04, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M05, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M05, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M06, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M06, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M07, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M07, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M08, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M08, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M09, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M09, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M10, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M10, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M11, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M11, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M12, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M12, 0)  * -1
										ELSE 0 END) - 0
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'EBIT %'
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M00, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M00, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M00, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M01, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M01, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M01, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M02, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M02, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M02, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M03, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M03, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M03, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M04, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M04, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M04, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M05, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M05, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M05, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M06, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M06, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M06, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M07, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M07, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M07, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M08, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M08, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M08, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M09, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M09, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M09, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M10, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M10, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M10, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M11, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M11, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M11, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M12, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(M12, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M12, 0)  
										ELSE 0 END) * 100
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'NET INCOME'
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M00, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M00, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M01, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M01, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M02, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M02, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M03, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M03, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M04, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M04, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M05, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M05, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M06, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M06, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M07, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M07, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M08, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M08, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M09, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M09, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M10, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M10, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M11, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M11, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M12, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M12, 0) * -1
										ELSE 0 END) - 0
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'NET INCOME %'
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M00, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M01, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M00, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M01, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M01, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M01, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M02, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M02, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M02, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M03, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M03, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M03, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M04, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M04, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M04, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M05, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M05, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M05, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M06, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M06, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M06, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M07, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M07, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M07, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M08, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M08, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M08, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M09, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M09, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M09, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M10, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M10, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M10, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M11, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M11, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M11, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M12, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(M12, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(M12, 0)  
										ELSE 0 END) * 100
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
		  			) AS Q
		  	 ON	TITLE.components = Q.statement
		 ORDER
		 	 BY	comp_no
		  	 ;
		
		 /* --------------------------------------------------------------------------------------------------------------------------
		
			END OF MONTHLY REPORT FOR PNL
		
		-----------------------------------------------------------------------------------------------------------------------------*/	 
	ELSEIF @report_type = 'Q' THEN
		/* --------------------------------------------------------------------------------------------------------------------------
		
			QUATERLY REPORT FOR PNL: START
		
		-----------------------------------------------------------------------------------------------------------------------------*/
		INSERT	-- Insert Quaterly Data
		  INTO	ychoung_tmp (f_type, statement, Q1, Q2, Q3, Q4, Q0)
		SELECT	a.*
					,b.amount
		  FROM	(
					SELECT	2
								,statement
								,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
									WHEN RIGHT(entry_quater, 2) = 'Q1' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
			                  WHEN RIGHT(entry_quater, 2) = 'Q1' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
			               END 
								), 2) AS Q1
								,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
									WHEN RIGHT(entry_quater, 2) = 'Q2' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
			                  WHEN RIGHT(entry_quater, 2) = 'Q2' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
			               END 
								), 2) AS Q2
								,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
									WHEN RIGHT(entry_quater, 2) = 'Q3' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
			                  WHEN RIGHT(entry_quater, 2) = 'Q3' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
			               END 
								), 2) AS Q3
								,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
									WHEN RIGHT(entry_quater, 2) = 'Q4' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
			                  WHEN RIGHT(entry_quater, 2) = 'Q4' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
			               END 
								), 2) AS Q4
					  FROM	ychoung_tmp
					 WHERE	entry_year = @fn_year
					 			AND f_type = 0
					 			AND is_balance_sheet_section = 0
					 GROUP
					 	 BY	statement
					) AS a
		  LEFT
		  JOIN	(
		  			SELECT	statement
								,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
									WHEN RIGHT(entry_quater, 2) = 'Q4' AND debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
			                  WHEN RIGHT(entry_quater, 2) = 'Q4' AND debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
			               END 
								), 2) AS amount
					  FROM	ychoung_tmp
					 WHERE	entry_year = @last_year
					 			AND f_type = 0
					 			AND is_balance_sheet_section = 0
					 GROUP
					 	 BY	statement
		  			) AS b
			 ON	a.statement = b.statement		  		 	 
			;
		 
		-- BUILDING REPORT ---------------------------------------------------------------------------------------------------- 
		SELECT	TITLE.components
					,CASE 
						WHEN Q1 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(Q1, 0),2)
						ELSE IFNULL(Q1, 0) END AS Q1
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'QoQ Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(Q1 - Q0, 2)
						ELSE ROUND((Q1 - Q0)/ABS(Q0)*100,2)END, 0) AS `Q1 Growth`
					,CASE 
						WHEN Q2 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(Q2, 0),2)
						ELSE IFNULL(Q2, 0) END AS Q2
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'QoQ Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(Q2 - Q1, 2)
						ELSE ROUND((Q2 - Q1)/ABS(Q1)*100,2)END, 0) AS `Q2 Growth`
					,CASE 
						WHEN Q3 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(Q3, 0),2)
						ELSE IFNULL(Q3, 0) END AS Q3
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'QoQ Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(Q3 - Q2, 2)
						ELSE ROUND((Q3 - Q2)/ABS(Q2)*100,2)END, 0) AS `Q3 Growth`
					,CASE 
						WHEN Q4 NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(Q4, 0),2)
						ELSE IFNULL(Q4, 0) END AS Q4
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'QoQ Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(Q4 - Q3, 2)
						ELSE ROUND((Q4 - Q3)/ABS(Q3)*100,2)END, 0) AS `Q4 Growth`
		  FROM	(
					SELECT	components, comp_no
					  FROM	ychoung_tmp
					 WHERE	f_type = 1
				) AS TITLE
		  LEFT
		  JOIN	(
		  			SELECT	statement, Q0, Q1, Q2, Q3, Q4
		  			  FROM	ychoung_tmp
		  			 WHERE	f_type = 2
		  			 UNION ALL
					SELECT	@line_break, @line_break, @line_break, @line_break, @line_break, @line_break
					 UNION ALL
					SELECT	'PERIOD', @fn_year, '', '', '', ''
					 UNION ALL
					SELECT	@report_pnl, '', '', '', '', ''
					 UNION ALL
					SELECT	'TOTAL REVENUE'
								,ROUND(SUM(Q0), 2)
								,ROUND(SUM(Q1), 2)
								,ROUND(SUM(Q2), 2)
								,ROUND(SUM(Q3), 2)
								,ROUND(SUM(Q4), 2)
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 			AND statement IN ('REVENUE','OTHER INCOME')
					 UNION ALL
					SELECT	'GROSS PROFIT MARGIN'
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q0, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(Q0, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q1, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(Q1, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q2, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(Q2, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q3, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(Q3, 0) * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q4, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(Q4, 0) * -1
										ELSE 0 END)
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'GROSS PROFIT MARGIN %'
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q0, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(Q0, 0)  * -1
										ELSE 0 END)
								 / SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q0, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q1, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(Q1, 0)  * -1
										ELSE 0 END)
								 / SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q1, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q2, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(Q2, 0)  * -1
										ELSE 0 END)
								 / SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q2, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q3, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(Q3, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q3, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q4, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES') THEN IFNULL(Q4, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q4, 0)  
										ELSE 0 END) * 100
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'OEXP'
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q0, 0) 
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q1, 0) 
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q2, 0) 
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q3, 0)
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q4, 0)
										ELSE 0 END)
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'EBITDA MARGIN'
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q0, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q1, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q1, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q1, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q2, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q2, 0)  * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q3, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q3, 0) * -1
										ELSE 0 END)
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q4, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q4, 0)  * -1
										ELSE 0 END)
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'EBITDA %'
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q0, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q1, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q0, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q1, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q1, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q1, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q2, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q2, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q2, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q3, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q3, 0) * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q3, 0)  
										ELSE 0 END) * 100
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q4, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q4, 0)  * -1
										ELSE 0 END)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q4, 0)  
										ELSE 0 END) * 100
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'Depreciation & Ammortization',0 ,0, 0, 0, 0
					 UNION ALL
					SELECT	'EBIT'
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q0, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q0, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q1, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q1, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q2, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q2, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q3, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q3, 0)  * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q4, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q4, 0)  * -1
										ELSE 0 END) - 0
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'EBIT %'
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q0, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q0, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q0, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q1, 0)  
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q1, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q1, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q2, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q2, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q2, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q3, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q3, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q3, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q4, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES') THEN IFNULL(Q4, 0)  * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q4, 0)  
										ELSE 0 END) * 100
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'NET INCOME'
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q0, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(Q0, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q1, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(Q1, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q2, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(Q2, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q3, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(Q3, 0) * -1
										ELSE 0 END) - 0
								,SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q4, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(Q4, 0) * -1
										ELSE 0 END) - 0
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
					 UNION ALL
					SELECT	'NET INCOME %'
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q0, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(Q0, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q0, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q1, 0) 
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(Q1, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q1, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q2, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(Q2, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q2, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q3, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(Q3, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q3, 0)  
										ELSE 0 END) * 100
								,(SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q4, 0)
										WHEN statement IN ('COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX') THEN IFNULL(Q4, 0) * -1
										ELSE 0 END) - 0)
								/ SUM(CASE 
										WHEN statement IN ('REVENUE','OTHER INCOME') THEN IFNULL(Q4, 0)  
										ELSE 0 END) * 100
					  FROM	ychoung_tmp
					 WHERE	f_type = 2
		  			) AS Q
		  	 ON	TITLE.components = Q.statement
		 ORDER
		 	 BY	comp_no
		  	 ;
		/* --------------------------------------------------------------------------------------------------------------------------
		
			QUATERLY REPORT FOR PNL: END
		
		-----------------------------------------------------------------------------------------------------------------------------*/
	ELSE 
		/* --------------------------------------------------------------------------------------------------------------------------
		
			Annual REPORT FOR PNL: START
		
		-----------------------------------------------------------------------------------------------------------------------------*/
		SELECT	TITLE.components
					,CASE 
						WHEN T1.AMOUNT NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(T1.AMOUNT, 0),2)
						ELSE IFNULL(T1.AMOUNT, 0) END AS AMOUNT
					,CASE 
						WHEN T2.AMOUNT NOT IN ('', @line_break, @fn_year, @last_year) THEN FORMAT(IFNULL(T2.AMOUNT, 0),2)
						ELSE IFNULL(T2.AMOUNT, 0) END AS AMOUNT
					,IFNULL(CASE 
						WHEN TITLE.components = @report_pnl THEN ''
						WHEN TITLE.components = 'PERIOD' THEN 'YoY Growth (%)'
						WHEN TITLE.components = @line_break THEN @line_break
						WHEN RIGHT(TITLE.components, 1) = '%' THEN ROUND(T1.AMOUNT - T2.AMOUNT, 2)
						ELSE ROUND((T1.AMOUNT - T2.AMOUNT)/ABS(T2.AMOUNT)*100,2)END, 0) AS GROWTH
		  FROM	(
					SELECT	components, comp_no
					  FROM	ychoung_tmp
					 WHERE	f_type = 1
				) AS TITLE
		  LEFT
		  JOIN	(
					SELECT	statement
								,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
									WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
			                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
			               END 
								), 2) AS AMOUNT
					  FROM	ychoung_tmp
					 WHERE	entry_year = @fn_year
					 			AND is_balance_sheet_section = 0
					 			AND f_type = 0
					 GROUP
					 	 BY	statement
					UNION ALL
					SELECT	@line_break, @line_break
					UNION ALL
					SELECT	'PERIOD', @fn_year
					UNION ALL
					SELECT	@report_pnl, ''
					UNION ALL
					SELECT	'TOTAL REVENUE',
								(SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								)
					UNION ALL
					SELECT	'GROSS PROFIT MARGIN',
								(SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								)
					UNION ALL
					SELECT	'GROSS PROFIT MARGIN %',
								ROUND(((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								)) / ((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								)) * 100, 2)
					UNION ALL
					SELECT	'OEXP',
								(SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								)
					UNION ALL
					SELECT	'EBITDA MARGIN',
								(SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								)
					UNION ALL
					SELECT	'EBITDA %',
								ROUND(((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								)) / ((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								)) * 100, 2)
					UNION ALL
					SELECT	'Depreciation & Ammortization', 0
					UNION ALL
					SELECT	'EBIT',
								(SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								) - 0
					UNION ALL
					SELECT	'EBIT %',
								ROUND(((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								) - 0) / ((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								)) * 100, 2)
					UNION ALL
					SELECT	'NET INCOME',
								ROUND((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								) - IFNULL((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('INCOME TAX')
								), 0), 2)
					UNION ALL
					SELECT	'NET INCOME %',
								ROUND(((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								) - IFNULL((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('INCOME TAX')
								), 0))/ ((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @fn_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								)) * 100, 2)
					) AS T1
			 ON	TITLE.components = T1.statement
		  LEFT
		  JOIN	(
					SELECT	statement
								,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
									WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
			                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
			               END 
								), 2) AS AMOUNT
					  FROM	ychoung_tmp
					 WHERE	entry_year = @last_year
								AND f_type = 0
					 			AND is_balance_sheet_section = 0
					 GROUP
					 	 BY	statement
					UNION ALL
					SELECT	@line_break, @line_break
					UNION ALL
					SELECT	'PERIOD', @last_year
					UNION ALL
					SELECT	@report_pnl, ''
					UNION ALL
					SELECT	'TOTAL REVENUE',
								(SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								)
					UNION ALL
					SELECT	'GROSS PROFIT MARGIN',
								(SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								)
					UNION ALL
					SELECT	'GROSS PROFIT MARGIN %',
								ROUND(((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								)) / ((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								)) * 100, 2)
					UNION ALL
					SELECT	'OEXP',
								(SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								)
					UNION ALL
					SELECT	'EBITDA MARGIN',
								(SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								)
					UNION ALL
					SELECT	'EBITDA %',
								ROUND(((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								)) / ((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								)) * 100, 2)
					UNION ALL
					SELECT	'Depreciation & Ammortization', 0
					UNION ALL
					SELECT	'EBIT',
								(SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								) - 0
					UNION ALL
					SELECT	'EBIT %',
								ROUND(((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								) - 0) / ((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								)) * 100, 2)
					UNION ALL
					SELECT	'NET INCOME',
								ROUND((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								) - IFNULL((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('INCOME TAX')
								), 0), 2)
					UNION ALL
					SELECT	'NET INCOME %',
								ROUND(((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('COST OF GOODS AND SERVICES')
								) - (SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('OTHER EXPENSES','SELLING EXPENSES')
								) - IFNULL((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('INCOME TAX')
								), 0))/ ((SELECT	ROUND(SUM(CASE 
												WHEN debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) 
						                  WHEN debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0)
						               END 
											), 2)
								  FROM	ychoung_tmp
								 WHERE	entry_year = @last_year
								 			AND f_type = 0
								 			AND is_balance_sheet_section = 0
								 			AND statement IN ('REVENUE','OTHER INCOME')
								)) * 100, 2)
					) AS T2
			 ON	TITLE.components = T2.statement
		 ORDER
		 	 BY	comp_no
		;
		/* --------------------------------------------------------------------------------------------------------------------------
		
			Annual REPORT FOR PNL: END
		
		-----------------------------------------------------------------------------------------------------------------------------*/
	END IF;
	
	
/* -------------------------------------------------------------------------------------
	  	Build Report of Balance Sheet Type 1. Total Transaction level Balance
   ------------------------------------------------------------------------------------- */
	-- 1. REPORT TITLE LINE
	SELECT	'Balance Sheet (Transaction Level Balance)' AS Jounal_Entry, '' AS Line_item, '' AS `Description`, '' AS `Acccount`, '' AS Assets, '' AS Liabilities, '' AS Equity, '' AS BALANCE
	UNION ALL
	-- 2. REPORT FINALNCIAL YEAR
	SELECT	@fn_year, '','','','','','',''
	UNION ALL 
	-- LINE BREAK
	SELECT	@line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break
	UNION ALL 
	/*
	 3. REPORT LABEL 
		Journal Entry - Transaction title 
		Number - Sequence number of each transaction
		Description - Detail Information of each Transaction
		Account - Account Information of each Transaction
		Assets - B/S Assets Include Current Assets, Fixed Assets Statements
		Liabilities - B/S Liabilities Statements include CURRENT LIABILITIES
		Equity - B/S and P&L Statements include COST OF GOODS AND SERVICES, REVENUE, EQUITY, SELLING EXPENSES, OTHER EXPENSES, OTHER INCOME, INCOME TAX
		BALANCE - Assets - (Liabilities + Equity) 
	*/
	SELECT	'Journal Entry', 'Number', 'Decription', 'Account', 'Assets', 'Liabilities', 'Equity', 'BALANCE'
	UNION ALL 
	-- LINE BREAK
	SELECT	@line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break
	UNION ALL 
	-- 4. ENTIRE TRANSACTION BALANCE STATUS
	SELECT	journal_entry
				,line_item
				,DESCRIPTION
				,ACCOUNT
				,FORMAT(assets, 2)
				,FORMAT(liabilities, 2)
				,FORMAT(equity, 2)
				,''-- SUM(ASSETS - (LIABILITIES + EQUITY)) OVER(PARTITION BY journal_entry) 
				-- BASE TABLE FOR THIS YEAR B/S
	  FROM	ychoung_tmp
	 WHERE	entry_year = @fn_year
	UNION ALL
	-- LINE BREAK
	SELECT	@line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break
	UNION ALL
	-- 5. FINANCIAL YEAR TOTAL REPORT LINE
	SELECT	CONCAT('TOTAL (', @fn_year, ')')
				,''
				,'BALANCE OF YEAR: ASSETS - (LIABILITIES - EQUITY)'
				,''
				,FORMAT(SUM(ASSETS), 2) AS ASSETS
				,FORMAT(SUM(LIABILITIES), 2) AS LIABILITIES
				,FORMAT(SUM(EQUITY), 2) AS EQUITY
				,FORMAT(SUM(ASSETS) - (SUM(LIABILITIES) + SUM(EQUITY)), 2) 
	  FROM	ychoung_tmp
	 WHERE	entry_year = @fn_year
	UNION ALL
	-- 6. FINANCIAL LAST YEAR TOTAL REPORT LINE
	SELECT	CONCAT('LAST YEAR TOTAL (', @last_year, ')')
				,''
				,'BALANCE OF LAST YEAR: ASSETS - (LIABILITIES - EQUITY)'
				,''
				,FORMAT(SUM(ASSETS), 2) AS ASSETS
				,FORMAT(SUM(LIABILITIES), 2) AS LIABILITIES
				,FORMAT(SUM(EQUITY), 2) AS EQUITY
				,FORMAT(SUM(ASSETS) - (SUM(LIABILITIES) + SUM(EQUITY)), 2) 
	  FROM	ychoung_tmp
	 WHERE	entry_year = @last_year
	UNION ALL
	-- 7. YEAR OF YEAR GROWTH REPORT LINE
	SELECT	'YoY Growth'
				,''
				,''
				,''
				,ROUND(
					(
						(
							SELECT SUM(ASSETS) 
							FROM ychoung_tmp
							WHERE entry_year = @fn_year
						) / (
							SELECT SUM(ASSETS) 
							FROM ychoung_tmp
							WHERE entry_year = @last_year
						) - 1
					) * 100.0, 2
				)
				,ROUND(
					(
						(
							SELECT SUM(LIABILITIES) 
							FROM ychoung_tmp
							WHERE entry_year = @fn_year
						) / (
							SELECT SUM(LIABILITIES) 
							FROM ychoung_tmp
							WHERE entry_year = @last_year
						) - 1
					) * 100.0, 2
				)
				,ROUND(
					(
						(
							SELECT SUM(EQUITY) 
							FROM ychoung_tmp
							WHERE entry_year = @fn_year
						) / (
							SELECT SUM(EQUITY) 
							FROM ychoung_tmp
							WHERE entry_year = @last_year
						) - 1
					) * 100.0, 2
				)
				,''
	UNION ALL
	-- LINE BREAK
	SELECT	@line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break, @line_break
	;
	
	
	/********************************************************************************
	 * BALANCE SHEET TYPE 2. Accounting Standard
	 ******************************************************************************** */
	SELECT	'Balance Sheet' AS CATEGORY, '(Accounting Standard Format)' AS `account`,'' AS `This Year`,'' AS `Last Year`, '' AS `YoY Growth`
	UNION ALL
	SELECT	'Annual Balance', '', 'Assets', 'Liabilities', 'Equity'
	UNION ALL
	SELECT	@line_break, '', @line_break,  @line_break,  @line_break 
	UNION ALL
	SELECT	CONCAT('THIS YEAR TOTAL (', @fn_year, ')')
				,''
				,FORMAT(SUM(ASSETS), 2) AS ASSETS
				,FORMAT(SUM(LIABILITIES), 2) AS LIABILITIES
				,FORMAT(SUM(EQUITY), 2) AS EQUITY
	  FROM	ychoung_tmp
	 WHERE	entry_year = @fn_year
	UNION ALL
	-- 6. FINANCIAL LAST YEAR TOTAL REPORT LINE
	SELECT	CONCAT('LAST YEAR TOTAL (', @last_year, ')')
				,''
				,FORMAT(SUM(ASSETS), 2) AS ASSETS
				,FORMAT(SUM(LIABILITIES), 2) AS LIABILITIES
				,FORMAT(SUM(EQUITY), 2) AS EQUITY
	  FROM	ychoung_tmp
	 WHERE	entry_year = @last_year
	UNION ALL
	-- 7. YEAR OF YEAR GROWTH REPORT LINE
	SELECT	'YoY Growth (%)'
				,''
				,ROUND(
					(
						((
							SELECT SUM(ASSETS) 
							FROM ychoung_tmp
							WHERE entry_year = @fn_year
						) - (
							SELECT SUM(ASSETS) 
							FROM ychoung_tmp
							WHERE entry_year = @last_year
						)) / (SELECT ABS(SUM(ASSETS)) 
							FROM ychoung_tmp
							WHERE entry_year = @last_year)
					) * 100.0, 2
				)
				,ROUND(
					(
						((
							SELECT SUM(LIABILITIES) 
							FROM ychoung_tmp
							WHERE entry_year = @fn_year
						) - (
							SELECT SUM(LIABILITIES) 
							FROM ychoung_tmp
							WHERE entry_year = @last_year
						)) / (SELECT ABS(SUM(LIABILITIES)) 
							FROM ychoung_tmp
							WHERE entry_year = @last_year)
					) * 100.0, 2
				)
				,ROUND(
					(
						((
							SELECT SUM(EQUITY) 
							FROM ychoung_tmp
							WHERE entry_year = @fn_year
						) - (
							SELECT SUM(EQUITY) 
							FROM ychoung_tmp
							WHERE entry_year = @last_year
						)) / (SELECT ABS(SUM(EQUITY)) 
							FROM ychoung_tmp
							WHERE entry_year = @last_year)
					) * 100.0, 2
				)
	UNION ALL
	SELECT	'', '', '', '', '' 
	UNION ALL
	SELECT	'Detail Account Information Report', '', '', '', ''
	UNION ALL
	SELECT	'CATEGORY', 'Account', CONCAT('This Year (', @fn_year, ')'), CONCAT('Last Year (', @last_year, ')'), 'YoY Growth (%)'
	UNION ALL
	SELECT	@line_break, @line_break, @line_break, @line_break, @line_break
	UNION ALL
	SELECT	A.CATEGORY
				,'TOTAL'
				,FORMAT(A.AMOUNT, 2)
				,FORMAT(B.AMOUNT, 2)
				,ROUND((A.AMOUNT - B.AMOUNT) / ABS(B.AMOUNT) * 100, 2) AS YoY_Growth
	  FROM	(
				SELECT	'CURRENT ASSETS' AS CATEGORY, '' AS `account`
							,(SELECT SUM(debit - credit) 
								FROM ychoung_tmp 
								WHERE entry_year = @fn_year
				 						AND statement IN ('CURRENT ASSETS', 'FIXED ASSETS')
							) AS AMOUNT
				) AS a
	  LEFT
	  JOIN	(
				SELECT	'CURRENT ASSETS' AS CATEGORY, '' AS `account`
							,(SELECT SUM(debit - credit) 
								FROM ychoung_tmp 
								WHERE entry_year = @last_year
				 						AND statement IN ('CURRENT ASSETS', 'FIXED ASSETS')
							) AS AMOUNT
				) AS b
		 ON	a.CATEGORY = b.CATEGORY
	UNION ALL
	SELECT	''
				,IF(T_ACCOUNT IS NULL, L_ACCOUNT, T_ACCOUNT) 
				,FORMAT(IFNULL(T_AMOUNT, 0), 2)
				,FORMAT(IFNULL(L_AMOUNT, 0), 2)
				,ROUND(IFNULL((IFNULL(T_AMOUNT, 0) - IFNULL(L_AMOUNT, 0))/ABS(IFNULL(L_AMOUNT, 0)) * 100, 0),2)
	  FROM	(
				SELECT	a.account AS T_ACCOUNT
							,a.AMOUNT AS T_AMOUNT
							,b.account AS L_ACCOUNT
							,b.AMOUNT AS L_AMOUNT
				  FROM	(
							SELECT	account
										,SUM(debit - credit) AS AMOUNT
							  FROM	ychoung_tmp
							 WHERE	entry_year = @fn_year
							 			AND statement IN ('CURRENT ASSETS', 'FIXED ASSETS')
							 GROUP
							 	 BY	account
							) AS a
				   LEFT
				   JOIN	(
							SELECT	account
										,SUM(debit - credit) AS AMOUNT
							  FROM	ychoung_tmp
							 WHERE	entry_year = @last_year
							 			AND statement IN ('CURRENT ASSETS', 'FIXED ASSETS')
							 GROUP
							 	 BY	account
							) AS b
					  ON	a.account = b.account
				UNION ALL 
				SELECT	a.account AS T_ACCOUNT
							,a.AMOUNT AS T_AMOUNT
							,b.account AS L_ACCOUNT
							,b.AMOUNT AS L_AMOUNT
				  FROM	(
							SELECT	account
										,SUM(debit - credit) AS AMOUNT
							  FROM	ychoung_tmp
							 WHERE	entry_year = @fn_year
							 			AND statement IN ('CURRENT ASSETS', 'FIXED ASSETS')
							 GROUP
							 	 BY	account
							) AS a
				   RIGHT
				   JOIN	(
							SELECT	account
										,SUM(debit - credit) AS AMOUNT
							  FROM	ychoung_tmp
							 WHERE	entry_year = @last_year
							 			AND statement IN ('CURRENT ASSETS', 'FIXED ASSETS')
							 GROUP
							 	 BY	account
							) AS b
					  ON	a.account = b.account
				  WHERE	a.account IS NULL
				) AS aa
	UNION ALL
	SELECT	@line_break, @line_break, @line_break, @line_break, @line_break
	UNION ALL
	SELECT	A.CATEGORY
				,'TOTAL'
				,FORMAT(A.AMOUNT, 2)
				,FORMAT(B.AMOUNT, 2)
				,ROUND((A.AMOUNT - B.AMOUNT) / ABS(B.AMOUNT) * 100, 2) AS YoY_Growth
	  FROM	(
				SELECT	'CURRENT LIABILITIES' AS CATEGORY, '' AS `account`
							,(SELECT SUM(credit - debit)
								FROM ychoung_tmp 
								WHERE entry_year = @fn_year
				 						AND statement IN ('CURRENT LIABILITIES')
							) AS AMOUNT
				) AS a
	  LEFT
	  JOIN	(
				SELECT	'CURRENT LIABILITIES' AS CATEGORY, '' AS `account`
							,(SELECT SUM(credit - debit) 
								FROM ychoung_tmp 
								WHERE entry_year = @last_year
				 						AND statement IN ('CURRENT LIABILITIES')
							) AS AMOUNT
				) AS b
		 ON	a.CATEGORY = b.CATEGORY
	UNION ALL
	SELECT	''
				,IF(T_ACCOUNT IS NULL, L_ACCOUNT, T_ACCOUNT) 
				,FORMAT(IFNULL(T_AMOUNT, 0), 2)
				,FORMAT(IFNULL(L_AMOUNT, 0), 2)
				,ROUND(IFNULL((IFNULL(T_AMOUNT, 0) - IFNULL(L_AMOUNT, 0))/ABS(IFNULL(L_AMOUNT, 0)) * 100, 0),2)
	  FROM	(
				SELECT	a.account AS T_ACCOUNT
							,a.AMOUNT AS T_AMOUNT
							,b.account AS L_ACCOUNT
							,b.AMOUNT AS L_AMOUNT
				  FROM	(
							SELECT	account
										,SUM(credit - debit) AS AMOUNT
							  FROM	ychoung_tmp
							 WHERE	entry_year = @fn_year
							 			AND statement IN ('CURRENT LIABILITIES')
							 GROUP
							 	 BY	account
							) AS a
				   LEFT
				   JOIN	(
							SELECT	account
										,SUM(credit - debit) AS AMOUNT
							  FROM	ychoung_tmp
							 WHERE	entry_year = @last_year
							 			AND statement IN ('CURRENT LIABILITIES')
							 GROUP
							 	 BY	account
							) AS b
					  ON	a.account = b.account
				UNION ALL 
				SELECT	a.account AS T_ACCOUNT
							,a.AMOUNT AS T_AMOUNT
							,b.account AS L_ACCOUNT
							,b.AMOUNT AS L_AMOUNT
				  FROM	(
							SELECT	account
										,SUM(credit - debit) AS AMOUNT
							  FROM	ychoung_tmp
							 WHERE	entry_year = @fn_year
							 			AND statement IN ('CURRENT LIABILITIES')
							 GROUP
							 	 BY	account
							) AS a
				   RIGHT
				   JOIN	(
							SELECT	account
										,SUM(credit - debit) AS AMOUNT
							  FROM	ychoung_tmp
							 WHERE	entry_year = @last_year
							 			AND statement IN ('CURRENT LIABILITIES')
							 GROUP
							 	 BY	account
							) AS b
					  ON	a.account = b.account
				  WHERE	a.account IS NULL
				) AS aa
	 	 
	UNION ALL
	SELECT	@line_break, @line_break, @line_break, @line_break, @line_break
	UNION ALL
	SELECT	A.CATEGORY
				,'TOTAL'
				,FORMAT(A.AMOUNT, 2)
				,FORMAT(B.AMOUNT, 2)
				,ROUND((A.AMOUNT - B.AMOUNT) / ABS(B.AMOUNT) * 100, 2) AS YoY_Growth
	  FROM	(
				SELECT	'EQUITY' AS CATEGORY, '' AS `account`
							,(SELECT SUM(credit - debit)
								FROM ychoung_tmp 
								WHERE entry_year = @fn_year
				 						AND statement IN ( 'REVENUE', 'OTHER INCOME', 'COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX', 'EQUITY')
							) AS AMOUNT
				) AS a
	  LEFT
	  JOIN	(
				SELECT	'EQUITY' AS CATEGORY, '' AS `account`
							,(SELECT SUM(credit - debit)
								FROM ychoung_tmp 
								WHERE entry_year = @last_year
				 						AND statement IN ( 'REVENUE', 'OTHER INCOME', 'COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX', 'EQUITY')
							) AS AMOUNT
				) AS b
		 ON	a.CATEGORY = b.CATEGORY
	UNION ALL
	SELECT	''
				,IF(T_ACCOUNT IS NULL, L_ACCOUNT, T_ACCOUNT) 
				,FORMAT(IFNULL(T_AMOUNT, 0), 2)
				,FORMAT(IFNULL(L_AMOUNT, 0), 2)
				,ROUND(IFNULL((IFNULL(T_AMOUNT, 0) - IFNULL(L_AMOUNT, 0))/ABS(IFNULL(L_AMOUNT, 0)) * 100, 0),2)
	  FROM	(
				SELECT	a.account AS T_ACCOUNT
							,a.AMOUNT AS T_AMOUNT
							,b.account AS L_ACCOUNT
							,b.AMOUNT AS L_AMOUNT
				  FROM	(
							SELECT	account
										,SUM(credit - debit) AS AMOUNT
							  FROM	ychoung_tmp
							 WHERE	entry_year = @fn_year
							 			AND statement IN ( 'REVENUE', 'OTHER INCOME', 'COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX', 'EQUITY')
							 GROUP
							 	 BY	account
							) AS a
				   LEFT
				   JOIN	(
							SELECT	account
										,SUM(credit - debit) AS AMOUNT
							  FROM	ychoung_tmp
							 WHERE	entry_year = @last_year
							 			AND statement IN ( 'REVENUE', 'OTHER INCOME', 'COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX', 'EQUITY')
							 GROUP
							 	 BY	account
							) AS b
					  ON	a.account = b.account
				UNION ALL 
				SELECT	a.account AS T_ACCOUNT
							,a.AMOUNT AS T_AMOUNT
							,b.account AS L_ACCOUNT
							,b.AMOUNT AS L_AMOUNT
				  FROM	(
							SELECT	account
										,SUM(credit - debit) AS AMOUNT
							  FROM	ychoung_tmp
							 WHERE	entry_year = @fn_year
							 			AND statement IN ( 'REVENUE', 'OTHER INCOME', 'COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX', 'EQUITY')
							 GROUP
							 	 BY	account
							) AS a
				   RIGHT
				   JOIN	(
							SELECT	account
										,SUM(credit - debit) AS AMOUNT
							  FROM	ychoung_tmp
							 WHERE	entry_year = @last_year
							 			AND statement IN ( 'REVENUE', 'OTHER INCOME', 'COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX', 'EQUITY')
							 GROUP
							 	 BY	account
							) AS b
					  ON	a.account = b.account
				  WHERE	a.account IS NULL
				) AS aa
	;
	
	
END$$
DELIMITER ;

/* *****************************************
	 PROCEDURE: team_10_trio_2_account_report
	 INPUT:
		1. fn_year: INT DEFAULT = 2016; 
		2. type_of_report: CHAR(1) [Y: Annual Report | M: Monthly Report | Q: Quater Report for PNL | DEFALUT: Y]
	 OUTPUT:
		TABLE 1. P&L Statements Report Financial This term over Last with YoY Growth Rate
		TABLE 2. B/S Report of Financial YEAR and Total of LAST YEAR with YoY Grouwth Rate
 * ***************************************** */
CALL team_10_trio_2_account_report(2018, 'Q');

