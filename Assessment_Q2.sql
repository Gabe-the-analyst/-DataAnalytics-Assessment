WITH successful_savings AS (
    -- Step 1: Filter savings transactions to include only those that were successful
    -- We select the transaction ID, the owner (customer) ID, and the date of the transaction
    -- The transaction_status is converted to lowercase for case-insensitive matching
    SELECT 
        id,                       -- Unique identifier for each transaction
        owner_id,                 -- Customer who made the transaction
        transaction_date          -- Date when the transaction occurred
    FROM savings_savingsaccount
    WHERE LOWER(transaction_status) IN ('success', 'successful')  -- Only include successful deposits
),

active_customers AS (
    -- Step 2: Identify customers whose accounts are currently active and valid
    -- Exclude any customers whose accounts are deleted, disabled, or marked inactive by themselves or admin
    -- Select their customer ID along with first and last names for potential reference
    SELECT 
        id AS customer_id,        -- Unique customer identifier, renamed for clarity
        first_name,               -- Customer's first name
        last_name                 -- Customer's last name
    FROM users_customuser
    WHERE is_account_deleted = 0         -- Exclude deleted accounts
      AND is_account_disabled = 0        -- Exclude disabled accounts
      AND is_disabled_by_owner = 0       -- Exclude accounts disabled by the owner themselves
      AND is_account_deleted_by_owner = 0  -- Exclude accounts deleted by the owner themselves
),

monthly_txns_per_customer AS (
    -- Step 3: Calculate how many successful transactions each active customer makes every month
    -- Join successful savings transactions with active customers to filter only valid users
    -- Group by customer and month (formatted as 'YYYY-MM') to get monthly transaction counts
    SELECT
        ss.owner_id AS customer_id,                -- Customer ID from successful savings transactions
        DATE_FORMAT(ss.transaction_date, '%Y-%m') AS transaction_month,  -- Extract year and month for grouping
        COUNT(*) AS txn_count                       -- Number of transactions the customer made that month
    FROM successful_savings ss
    JOIN active_customers ac ON ss.owner_id = ac.customer_id
    GROUP BY ss.owner_id, DATE_FORMAT(ss.transaction_date, '%Y-%m')   -- Group by customer and month
),

avg_txns_per_customer AS (
    -- Step 4: Compute average monthly transactions per customer
    -- This gives a single metric per customer representing their transaction frequency over time
    SELECT
        customer_id,                       -- Customer ID
        AVG(txn_count) AS avg_monthly_txn -- Average number of transactions per month for that customer
    FROM monthly_txns_per_customer
    GROUP BY customer_id                 -- Group by customer to get their average monthly txn count
)

-- Step 5: Categorize customers based on their average monthly transaction frequency
-- Create three frequency categories: High, Medium, and Low
-- Count how many customers fall into each category
-- Calculate the average transactions per month for each category, rounded to 1 decimal place
SELECT
    CASE
        WHEN avg_monthly_txn >= 10 THEN 'High Frequency'             -- 10 or more txns per month
        WHEN avg_monthly_txn BETWEEN 3 AND 9 THEN 'Medium Frequency' -- Between 3 and 9 txns per month
        ELSE 'Low Frequency'                                         -- Less than or equal to 2 txns per month
    END AS frequency_category,
    COUNT(*) AS customer_count,                                       -- Number of customers in each category
    ROUND(AVG(avg_monthly_txn), 1) AS avg_transactions_per_month     -- Average monthly transactions for the group
FROM avg_txns_per_customer
GROUP BY frequency_category                                         -- Group results by frequency category
ORDER BY
    CASE frequency_category                                         -- Order results so High frequency shows first
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
        WHEN 'Low Frequency' THEN 3
    END;
