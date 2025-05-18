WITH last_txn_per_plan AS (
    -- Step 1: Identify the latest successful deposit transaction date for each plan
    -- We focus only on transactions marked as 'success' or 'successful' (case-insensitive)
    -- For each plan, find the maximum transaction_date to get the most recent successful deposit date
    SELECT 
        plan_id,                                -- Unique identifier for each savings plan
        MAX(transaction_date) AS last_transaction_date  -- Latest date of a successful transaction for that plan
    FROM savings_savingsaccount
    WHERE LOWER(transaction_status) IN ('success', 'successful')  -- Only successful transactions count
    GROUP BY plan_id                        -- Group transactions by each plan to find their max date
),

plans_with_last_txn AS (
    -- Step 2: Combine each plan with its latest transaction date (if any)
    -- Use LEFT JOIN to ensure all plans are included, even those without any transaction
    -- COALESCE returns last_transaction_date if available; otherwise, falls back to plan creation date
    -- This gives us the last known activity date on the plan, whether deposit or plan creation
    -- Also classify the plans into types based on boolean flags
    SELECT
        p.id AS plan_id,                       -- Plan identifier (corrected column name)
        p.owner_id,                           -- Owner (customer) of the plan
        CASE
            WHEN p.is_regular_savings = 1 THEN 'Savings'       -- Label as 'Savings' if regular savings plan
            WHEN p.is_a_fund = 1 THEN 'Investment'             -- Label as 'Investment' if fund-based plan
            ELSE 'Other'                                        -- Otherwise, classify as 'Other'
        END AS plan_type,
        l.last_transaction_date,              -- Most recent successful transaction date (nullable)
        COALESCE(l.last_transaction_date, p.created_on) AS last_activity_date  -- Last active date, fallback to plan creation date if no transaction
    FROM plans_plan p
    LEFT JOIN last_txn_per_plan l ON p.id = l.plan_id
    -- Optional filter can be added here to restrict to active plans, e.g., WHERE p.is_active = 1
)

-- Step 3: Select plans that have been inactive for more than 365 days
-- Inactivity is calculated as the number of days since the last_activity_date until today
-- Filter to only show those plans with inactivity_days greater than 365 (1 year)
-- Results are ordered by inactivity_days descending so the most inactive plans appear first
-- Limit the output to top 50 plans meeting this criteria
SELECT
    plan_id,                             -- Plan identifier
    owner_id,                            -- Owner of the plan
    plan_type,                          -- Type of plan (Savings, Investment, Other)
    last_transaction_date,              -- Date of last successful deposit (if any)
    DATEDIFF(CURRENT_DATE, last_activity_date) AS inactivity_days  -- Number of days inactive since last activity
FROM plans_with_last_txn
WHERE DATEDIFF(CURRENT_DATE, last_activity_date) > 365
ORDER BY inactivity_days DESC
LIMIT 50;
