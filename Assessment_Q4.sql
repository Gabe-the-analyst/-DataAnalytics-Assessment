WITH successful_txns AS (
    -- Step 1: Retrieve all successful savings transactions from accounts
    -- Filter by transaction status (case-insensitive check for success)
    -- This captures only completed, successful transactions for analysis
    SELECT 
        owner_id,          -- Customer who made the transaction
        amount             -- Amount transacted (smallest currency unit)
    FROM savings_savingsaccount
    WHERE LOWER(transaction_status) IN ('success', 'successful')
),

txn_summary AS (
    -- Step 2: Aggregate transaction data per customer
    -- Calculate total count, sum, and average transaction amount
    -- These metrics represent transaction behavior for each user
    SELECT 
        owner_id,                     -- Customer ID
        COUNT(*) AS total_transactions,      -- Number of successful transactions
        SUM(amount) AS total_transaction_value,  -- Total amount transacted
        AVG(amount) AS avg_transaction_value      -- Average amount per transaction
    FROM successful_txns
    GROUP BY owner_id
),

tenure_data AS (
    -- Step 3: Retrieve active customers and compute tenure
    -- Exclude users who have deleted or disabled accounts by themselves or system
    -- Tenure calculated as months since joining to today, helps normalize transaction activity
    SELECT 
        id AS customer_id,            -- User ID
        CONCAT(first_name, ' ', last_name) AS name,   -- User full name
        TIMESTAMPDIFF(MONTH, date_joined, CURRENT_DATE) AS tenure_months  -- Customer tenure in months
    FROM users_customuser
    WHERE is_account_deleted = 0          -- Exclude deleted accounts
      AND is_account_disabled = 0         -- Exclude disabled accounts
      AND is_disabled_by_owner = 0        -- Exclude accounts disabled by owner
      AND is_account_deleted_by_owner = 0 -- Exclude accounts deleted by owner
),

clv_calc AS (
    -- Step 4: Calculate estimated Customer Lifetime Value (CLV)
    -- Formula: (average transactions per month * 12) * (average transaction value)
    -- Multiply average transaction value by 0.001 to convert from smaller units (e.g., kobo to naira)
    -- Use GREATEST to avoid division by zero for tenure = 0 (minimum tenure of 1 month)
    -- Round the final CLV to nearest integer
    SELECT 
        t.customer_id,
        t.name,
        td.total_transactions,
        GREATEST(t.tenure_months, 1) AS tenure_months,  -- Avoid divide by zero
        ROUND(
            (td.total_transactions / GREATEST(t.tenure_months, 1)) * 12 * (td.avg_transaction_value * 0.001),
            0
        ) AS estimated_clv
    FROM tenure_data t
    JOIN txn_summary td ON t.customer_id = td.owner_id
)

-- Final step: Return top 50 customers by estimated CLV in descending order
SELECT *
FROM clv_calc
ORDER BY estimated_clv DESC
LIMIT 50;
