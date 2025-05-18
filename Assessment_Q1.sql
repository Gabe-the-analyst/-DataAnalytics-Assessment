-- Step 1: Get all customers who have at least one funded savings plan
WITH savings_plans AS (
    SELECT
        owner_id,                     -- ID of the customer who owns the plan
        COUNT(*) AS savings_count     -- Count how many savings plans they have
    FROM plans_plan
    WHERE is_regular_savings = 1      -- Filter only regular savings plans
    GROUP BY owner_id
),

-- Step 2: Get all customers who have at least one funded investment plan
investment_plans AS (
    SELECT
        owner_id,                      -- ID of the customer who owns the plan
        COUNT(*) AS investment_count   -- Count how many investment plans they have
    FROM plans_plan
    WHERE is_a_fund = 1               -- Filter only investment/fund-based plans
    GROUP BY owner_id
),

-- Step 3: Calculate total deposits for each customer (convert from kobo to naira)
total_deposits AS (
    SELECT
        owner_id,
        ROUND(SUM(confirmed_amount) / 100.0, 0) AS total_deposits -- Sum of all deposits, divided by 100 to convert from kobo to naira, then rounded to nearest whole number
    FROM savings_savingsaccount
    GROUP BY owner_id
)

-- Step 4: Combine everything and retrieve full customer details
SELECT
    u.id AS owner_id,                                            -- Customer ID
    CONCAT(u.first_name, ' ', u.last_name) AS name,              -- Full name (first + last)
    sp.savings_count,                                            -- Number of savings plans
    ip.investment_count,                                         -- Number of investment plans
    td.total_deposits                                            -- Total deposits in naira, rounded to nearest whole number
FROM savings_plans sp
JOIN investment_plans ip ON sp.owner_id = ip.owner_id           -- Join savings and investment plans on customer ID
JOIN total_deposits td ON sp.owner_id = td.owner_id             -- Join with deposit totals
JOIN users_customuser u ON sp.owner_id = u.id                   -- Get customer info
WHERE
    -- Filter out any accounts that are deleted or disabled
    u.is_account_deleted = 0
    AND u.is_account_disabled = 0
    AND u.is_disabled_by_owner = 0
    AND u.is_account_deleted_by_owner = 0
ORDER BY td.total_deposits DESC                                  -- Sort by highest depositor
LIMIT 50;
