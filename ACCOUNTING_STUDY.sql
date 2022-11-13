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
	 /* ***************************************
	 	 STEP 1. Define components of P&L statements and B/S Report
	 	 Q1. What are the main components of these reports?
	  * ****************************************/
	#_-------------------------------------------------------------------------------
    -- P&L
    -- -------------------------------------------------------------------------------
	-- TOTAL REVENUES: Sales revenue, other revenues, other Income, Service Revenue (PRICE X QUANTITY)
    -- DIRECT COST: Cost of goods sold, Cost of services 
    -- GROSS OPERATING MARGIN (Contribution Margin): TOTAL REVENUE - DIRECT COST
    -- GROSS OPERATING MARGIN %: GROSS OPERATION MARGIN / TOTAL REVENUES
    -- Operating Expenses: Employees, Rent, Utilities, - Cost for running business 
    -- EBITDA: Eearnings Before Interest, Tax, Depreciation, Amortization : GROSS OPERAING MARGIN - OPERATING EXPENSES
    -- EBITDA %: (EBITDA / TOTAL REVENUES) Efficiency 
    -- DEPRECIATION & AMORTIZATION: Equipments 
    -- EBIT: Eearnings Before Interest, Tax - (EBITDA - DEPRECIATION & AMORTIZATION)
    -- EBIT %: (EBIT / TOTAL REVENUES)
    -- Interest & Tax
		-- TAX: It Based from EBIT
        -- Interest Gain: Earning from investment
        -- Interest Expense: Loan interest cost
    -- Net Income: EBIT - Interest & TAX
    -- Net Income %: (Net Income / TOTAL REVENUES)
    
    #--------------------------------------------------------------------------------
    -- B/S 
    -- ---------------------------------------------------------------------------------
    -- ASSETS: CASH, Accounts Receivalbes(AR), T-Bills(Treadury Bill), Inventory, (Long-term Assets) Property Plant and Equipment, Long-governmental Bonds, Goodwill
    -- Liabilities: Accounts Payable, Loans
    -- Shareholders Equity: Common Stock, Net Income
    
    #----------------------------------------------------------------------------------
    -- YoY Growth: (THIS YEAR - LAST YEAR) / ABS(LAST YEAR)
    -- YoY Growth: (THIS YEAR / LAST YEAR) - 1
	 
     /* ***************************************
	 	 STEP 1. Define components of P&L statements and B/S Report
	 	 Q1. What are the main components of these reports?
	  * ****************************************/
	 
	-- For P&L Statements
	-- Need to transactions data 
     
     
     /* ***************************************
	 	 STEP 2. EXPLORE DATA to build report
	 	 Q1. Where is data stored? which table has it?
	 	 Q2. 
	  * ****************************************/
	 
	-- Debit & Credit are here
	SELECT	*
	  FROM	journal_entry_line_item
	 LIMIT	100;
	 
	SELECT	DISTINCT `description`
	  FROM	journal_entry_line_item
	 LIMIT	100;
	  
	-- Statement section are here is_balane_sheet_section 0 | 1 
	SELECT	*
	  FROM	statement_section
	 LIMIT	100;
		
	-- Journal Entry table is looks like transaction 
	-- entry_date 
	SELECT	*
	  FROM	journal_entry
	 LIMIT	100;
	-- Both journal_entry_line_item and journal_entry table has relation through journal_entry_id
	
	-- Check for cancelled and closing type data
	SELECT	DISTINCT cancelled, closing_type
				,COUNT(*)
	  FROM	journal_entry
	 GROUP
	 	 BY	cancelled, closing_type;
	
	-- Check and define target Data.
	SELECT	DATE_FORMAT(entry_date, '%Y-%m') -- Explore data by MONTHLY 
				,COUNT(*)
	  FROM	journal_entry
	 WHERE	cancelled = 0
			AND closing_type = 0
	 GROUP
	 	 BY	DATE_FORMAT(entry_date, '%Y-%m');
    
    -- What is 2026 year data?
	SELECT	*
	  FROM	journal_entry
	 WHERE	DATE_FORMAT(entry_date, '%Y-%m') = 2026;
	
	-- account table has balance_sheet_section_id and profit_loss_section_id for joining Statement Section
	SELECT	*
	  FROM	`account`
	 LIMIT	100;
	  
      
      
	 /* ***************************************
	 	 STEP 3 Build a basement data table
	 	 Q1. What tables do you need to join?
	 	 Q2. What columns do you need to filter?
	  * ****************************************/	  
	 -- journal_entry_line_item 
	 -- jounral_entry
	 -- account
	 -- statement_section
	 
	 -- Define final base data 
     SELECT	*
       -- BASE TABLES to join
	   FROM	journal_entry_line_item AS base
	   LEFT
	   JOIN	journal_entry AS a
	     ON	base.journal_entry_id = a.journal_entry_id
	   LEFT
	   JOIN	`account` AS b
	     ON	base.account_id = b.account_id
	   LEFT
	   JOIN	statement_section AS P_ST
	     ON	b.profit_loss_section_id = P_ST.statement_section_id
	   LEFT
	   JOIN	statement_section AS B_ST
	     ON	b.balance_sheet_section_id = B_ST.statement_section_id
	  -- Filter data for analyze
	  WHERE	debit_credit_balanced = 1
			AND cancelled = 0
			AND closing_type = 0
            AND DATE_FORMAT(entry_date, '%Y') = 2016 -- define data from 2016 based on entry date
	  LIMIT	100;
                
      
	   /* ***************************************
	 	 STEP 4 Build P&L Statements 
	 	 Q1. What data shoud to show on this report?
	 	 Q2. How to calculate them? 
	  * ****************************************/
	
    

	-- Check Statements for PNL report
	 SELECT	P_ST.statement_section
			,P_ST.debit_is_positive -- Check for debit is positive. IF it equal 1 then debit is POSITIVE
			,COUNT(*)
			,SUM(debit)
			,SUM(credit)
	 -- BASE TABLES to join
	   FROM	journal_entry_line_item AS base
	   LEFT
	   JOIN	journal_entry AS a
	     ON	base.journal_entry_id = a.journal_entry_id
	   LEFT
	   JOIN	`account` AS b
	     ON	base.account_id = b.account_id
	   LEFT
	   JOIN	statement_section AS P_ST
	     ON	b.profit_loss_section_id = P_ST.statement_section_id
	 WHERE	P_ST.statement_section != '' -- We don't need to Balance sheet statements
			AND debit_credit_balanced = 1
			AND cancelled = 0
			AND closing_type = 0
			AND DATE_FORMAT(entry_date, '%Y') = 2016
	 GROUP
	 	 BY	P_ST.statement_section
			,P_ST.debit_is_positive;
         
	-- FINALIZE PNL 
	 SELECT	P_ST.statement_section
			,ROUND(SUM(CASE -- Make a Total Amount Column, merging debits and credits.
					WHEN P_ST.debit_is_positive = 1 THEN IFNULL(debit, 0) - IFNULL(credit, 0) -- If debit is positive, credit is negative.
                    WHEN P_ST.debit_is_positive = 0 THEN IFNULL(credit, 0) - IFNULL(debit, 0) -- If debit is negative, credit is positive.
                    END 
				), 2) AS AMOUNT
	 -- BASE TABLES to join
	   FROM	journal_entry_line_item AS base
	   LEFT
	   JOIN	journal_entry AS a
	     ON	base.journal_entry_id = a.journal_entry_id
	   LEFT
	   JOIN	`account` AS b
	     ON	base.account_id = b.account_id
	   LEFT
	   JOIN	statement_section AS P_ST
	     ON	b.profit_loss_section_id = P_ST.statement_section_id
	 WHERE	P_ST.statement_section != '' -- We don't need to Balance sheet statements
			AND debit_credit_balanced = 1
			AND cancelled = 0
			AND closing_type = 0
			AND DATE_FORMAT(entry_date, '%Y') = 2016
	 GROUP
	 	 BY	P_ST.statement_section;
         
		/* ***************************************
	 	 STEP 5 Build B/S Statements 
	 	 Q1. What data shoud to show on this report?
	 	 Q2. How to calculate them? 
	  * ****************************************/
	  
      
  -- Check statements for PNL AND B/S
  -- Two types of Statements are  diveded becuase with left join statement_section table twice
  SELECT	P_ST.statement_section
			,B_ST.statement_section 
			,COUNT(*)
	  FROM	journal_entry_line_item AS base
	   LEFT
	   JOIN	journal_entry AS a
	     ON	base.journal_entry_id = a.journal_entry_id
	   LEFT
	   JOIN	`account` AS b
	     ON	base.account_id = b.account_id
	   LEFT
	   JOIN	statement_section AS P_ST
	     ON	b.profit_loss_section_id = P_ST.statement_section_id
	   LEFT
	   JOIN	statement_section AS B_ST
	     ON	b.balance_sheet_section_id = B_ST.statement_section_id
	 WHERE	debit_credit_balanced = 1
			AND cancelled = 0
			AND closing_type = 0
			AND DATE_FORMAT(entry_date, '%Y') = 2016
	  GROUP
	  	 BY	P_ST.statement_section
			,B_ST.statement_section
	;
    
-- Finalize data table for B/S 
SELECT	a.journal_entry
		,base.line_item
		,b.account
        -- Merge TWO TYPES of statements in one column
		,CASE 
			WHEN P_ST.statement_section != '' THEN P_ST.statement_section
			ELSE B_ST.statement_section 
		END AS statement
        ,base.debit
        ,base.credit
  FROM	journal_entry_line_item AS base
   LEFT
   JOIN	journal_entry AS a
	 ON	base.journal_entry_id = a.journal_entry_id
   LEFT
   JOIN	`account` AS b
	 ON	base.account_id = b.account_id
   LEFT
   JOIN	statement_section AS P_ST
	 ON	b.profit_loss_section_id = P_ST.statement_section_id
   LEFT
   JOIN	statement_section AS B_ST
	 ON	b.balance_sheet_section_id = B_ST.statement_section_id
 WHERE	debit_credit_balanced = 1
		AND cancelled = 0
		AND closing_type = 0
		AND DATE_FORMAT(entry_date, '%Y') = 2016
;
      
	-- This is for 2016 B/S report by each entry.
	SELECT	BASE.journal_entry
			,BASE.line_item
            ,BASE.account
			,ROUND(CASE 
					WHEN statement IN ('CURRENT ASSETS', 'FIXED ASSETS') AND credit IS NULL THEN IFNULL(debit, 0)
					WHEN statement IN ('CURRENT ASSETS', 'FIXED ASSETS') AND debit IS NULL THEN IFNULL(credit, 0) * -1
					ELSE 0
					END, 2) AS ASSETS
			,ROUND(CASE 
					WHEN statement IN ('CURRENT LIABILITIES') AND credit IS NULL THEN IFNULL(debit, 0) * -1
					WHEN statement IN ('CURRENT LIABILITIES') AND debit IS NULL THEN IFNULL(credit, 0)
					ELSE 0
					END, 2) AS LIABILITIES
			,ROUND(CASE 
					WHEN statement IN ('REVENUE', 'OTHER INCOME', 'COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX', 'EQUITY') AND credit IS NULL THEN IFNULL(debit, 0) * -1
					WHEN statement IN ('REVENUE', 'OTHER INCOME', 'COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX', 'EQUITY') AND debit IS NULL THEN IFNULL(credit, 0)
					ELSE 0
					END, 2) AS EQUITY
	  FROM	(
			 SELECT	a.journal_entry
					,base.line_item
					,b.account
					,CASE 
						WHEN P_ST.statement_section != '' THEN P_ST.statement_section
						ELSE B_ST.statement_section 
					END AS statement
					,base.debit
					,base.credit
			  FROM	journal_entry_line_item AS base
			   LEFT
			   JOIN	journal_entry AS a
				 ON	base.journal_entry_id = a.journal_entry_id
			   LEFT
			   JOIN	`account` AS b
				 ON	base.account_id = b.account_id
			   LEFT
			   JOIN	statement_section AS P_ST
				 ON	b.profit_loss_section_id = P_ST.statement_section_id
			   LEFT
			   JOIN	statement_section AS B_ST
				 ON	b.balance_sheet_section_id = B_ST.statement_section_id
			 WHERE	debit_credit_balanced = 1
					AND cancelled = 0
					AND closing_type = 0
					AND DATE_FORMAT(entry_date, '%Y') = 2016
			) AS BASE
	  ;
	
    -- This is Total Balanece Sheet for 2016 year
	SELECT	'TOTAL'
			,''
            ,''
			,ROUND(SUM(CASE 
					WHEN statement IN ('CURRENT ASSETS', 'FIXED ASSETS') AND credit IS NULL THEN IFNULL(debit, 0)
					WHEN statement IN ('CURRENT ASSETS', 'FIXED ASSETS') AND debit IS NULL THEN IFNULL(credit, 0) * -1
					ELSE 0
					END), 2) AS ASSETS
			,ROUND(SUM(CASE 
					WHEN statement IN ('CURRENT LIABILITIES') AND credit IS NULL THEN IFNULL(debit, 0) * -1
					WHEN statement IN ('CURRENT LIABILITIES') AND debit IS NULL THEN IFNULL(credit, 0)
					ELSE 0
					END), 2) AS LIABILITIES
			,ROUND(SUM(CASE 
					WHEN statement IN ('REVENUE', 'OTHER INCOME', 'COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX', 'EQUITY') AND credit IS NULL THEN IFNULL(debit, 0) * -1
					WHEN statement IN ('REVENUE', 'OTHER INCOME', 'COST OF GOODS AND SERVICES', 'OTHER EXPENSES', 'SELLING EXPENSES', 'INCOME TAX', 'EQUITY') AND debit IS NULL THEN IFNULL(credit, 0)
					ELSE 0
					END), 2) AS EQUITY
	  FROM	(
			 SELECT	a.journal_entry
					,base.line_item
					,b.account
					,CASE 
						WHEN P_ST.statement_section != '' THEN P_ST.statement_section
						ELSE B_ST.statement_section 
					END AS statement
					,base.debit
					,base.credit
			  FROM	journal_entry_line_item AS base
			   LEFT
			   JOIN	journal_entry AS a
				 ON	base.journal_entry_id = a.journal_entry_id
			   LEFT
			   JOIN	`account` AS b
				 ON	base.account_id = b.account_id
			   LEFT
			   JOIN	statement_section AS P_ST
				 ON	b.profit_loss_section_id = P_ST.statement_section_id
			   LEFT
			   JOIN	statement_section AS B_ST
				 ON	b.balance_sheet_section_id = B_ST.statement_section_id
			 WHERE	debit_credit_balanced = 1
					AND cancelled = 0
					AND closing_type = 0
					AND DATE_FORMAT(entry_date, '%Y') = 2016
			) AS BASE
	  ;
      
      
      
      
	  /* ***************************************
	 	 STEP 6 Build STORED PROCEDURE
	  * ****************************************/
-- BEFORE CREATE PROCEDURE.
/* ------------------------- CHANGING DELIMITER $$ ----------------------------------------------------------------------------*/
-- THIS IS VERY IMPORTANT
-- CHANGE DELIMITER FROM ; to $$ because in procedure code block, we need to write SQL codes with semi-colon (;) for each block. 
-- So, We need to teach server, Semi-colon is not END OF PROCEDURE's QUERY.
-- Change DELIMITER TO $$ and Bulid Procedure and recover to DELIMITER ;

-- JUST TRY WITH BELOW FOUR LINES.
DELIMITER $$ 
SELECT 1000 - 999, 'DELIMITER IS CHANGE'$$ -- THIS WILL WORK.
SELECT 1000 - 999, 'DELIMITER IS CHANGE'; -- THIS WILL NOT WORK.
DELIMITER ; 


-- RUN FROM HERE
-- MAKE STORED PROCEDURE FOR SIMPLE PNL 
DELIMITER $$ 
-- EXISTING PROCEDURE CHECK AND DROP 
/*
	CHECK YOUR PROCEDURE NAME!!! Change procedure name yourHulbID to REAL YOUR ID!!!
*/
DROP PROCEDURE IF EXISTS team_10_test_procedure_yourHultID $$
-- CREATE PROCEDURE START 
CREATE PROCEDURE team_10_test_procedure_yourHultID( IN fn_year INT) -- Input Valriable for Financial Year
BEGIN -- Begin 
	
    -- AFTER BEGIN SYNTAX, JUST PUT IN YOUR QUERY to run.
    -- START OF QUERY BLOCK No.1 ----------------------------------------------------------------------------------------
	SELECT	a.journal_entry
			,base.line_item
			,b.account
			,CASE 
				WHEN P_ST.statement_section != '' THEN P_ST.statement_section
				ELSE B_ST.statement_section 
			END AS statement
			,base.debit
			,base.credit
	  FROM	journal_entry_line_item AS base
	   LEFT
	   JOIN	journal_entry AS a
		 ON	base.journal_entry_id = a.journal_entry_id
	   LEFT
	   JOIN	`account` AS b
		 ON	base.account_id = b.account_id
	   LEFT
	   JOIN	statement_section AS P_ST
		 ON	b.profit_loss_section_id = P_ST.statement_section_id
	   LEFT
	   JOIN	statement_section AS B_ST
		 ON	b.balance_sheet_section_id = B_ST.statement_section_id
	 WHERE	debit_credit_balanced = 1
			AND cancelled = 0
			AND closing_type = 0
			AND DATE_FORMAT(entry_date, '%Y') = 2016; 
	-- END OF QUERY BLOCK No.1 -----------------------------------------------------------------------------
            
END$$
DELIMITER ;
-- RUN UNTIL HERE 

-- Is it works? 
CALL team_10_test_procedure_yourHultID(2016); -- We can see the B/S for 2016 year. 

-- Try to change input variable 2017
CALL team_10_test_procedure_yourHultID(2017); 
-- Is it working? 
-- Still 2016. because! We did not use INPUT VARIABLE (fn_year)
-- Like PROCEDURE, many other PROGRAM LANGUAGES have FUNCTION. 
-- LIKE THIS. 
/* ------------------------------------------------------------------
function  vendorMachine(money int, myItem String){ -- Like verdor machine, you can put in to your function, 3$(money) and Coke(myItem), THEN function will start running and 
	YOUR CODES; 
    return productOfYours;  -- return your drink. 
} 

CREATE PROCEDURE vendor_machine(IN MONEY INT, IN MY_ITEM VARCHAR(20), OUT PRODUCT_OF_YOURS VARCHAR(20) -- SAME in Procedure. put in your money and item, it return something.
BEGIN

END$$

---------------------------------------------------------------------------------*/

-- So! We need to use input variable in your procedure.


-- RUN FROM HERE
DELIMITER $$ 
-- EXISTING PROCEDURE CHECK AND DROP 
DROP PROCEDURE IF EXISTS team_10_test_procedure_yourHultID $$
-- CREATE PROCEDURE START 
CREATE PROCEDURE team_10_test_procedure_yourHultID( IN fn_year INT) -- Input Valriable for Financial Year!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!fn_year is input
BEGIN -- Begin 
	
    -- AFTER BEGIN SYNTAX, JUST PUT IN YOUR QUERY to run.
    -- START OF QUERY BLOCK No.1 ----------------------------------------------------------------------------------------
	SELECT	a.journal_entry
			,base.line_item
			,b.account
			,CASE 
				WHEN P_ST.statement_section != '' THEN P_ST.statement_section
				ELSE B_ST.statement_section 
			END AS statement
			,base.debit
			,base.credit
	  FROM	journal_entry_line_item AS base
	   LEFT
	   JOIN	journal_entry AS a
		 ON	base.journal_entry_id = a.journal_entry_id
	   LEFT
	   JOIN	`account` AS b
		 ON	base.account_id = b.account_id
	   LEFT
	   JOIN	statement_section AS P_ST
		 ON	b.profit_loss_section_id = P_ST.statement_section_id
	   LEFT
	   JOIN	statement_section AS B_ST
		 ON	b.balance_sheet_section_id = B_ST.statement_section_id
	 WHERE	debit_credit_balanced = 1
			AND cancelled = 0
			AND closing_type = 0
			AND DATE_FORMAT(entry_date, '%Y') = fn_year; -- USE input variable here!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
	-- END OF QUERY BLOCK No.1 -----------------------------------------------------------------------------
            
END$$
DELIMITER ;
-- RUN UNTIL HERE 

-- Check this out!
CALL team_10_test_procedure_yourHultID(2017); 
-- Is it work?

