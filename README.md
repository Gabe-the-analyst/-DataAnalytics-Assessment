Process Steps and Challenges - Cowrywise Assessment

This document contains a detailed summary of my step-by-step explanations and identified challenges for each question from the assessment. I appreciate the time taken to consider my submission

Question 1: Write a query to find customers with at least one funded savings plan AND one funded investment plan, sorted by total deposits.

Step 1: Identify Customers with Savings Plans
I started by looking into the plans_plan table to identify customers who have at least one regular savings plan. To do this, I filtered using is_regular_savings = 1. I grouped the results by owner_id and counted the number of savings plans each customer has.

Step 2: Identify Customers with Investment Plans
Similarly, I filtered the same plans_plan table using is_a_fund = 1 to find customers with investment plans (fund-based). Again, I grouped by owner_id and counted how many investment plans each customer had.

Step 3: Calculate Total Deposits Per Customer
Next, I moved to the savings_savingsaccount table and summed up the confirmed_amount for each customer. One challenge here was that the values were stored in kobo, not naira — so I had to divide the total by 100.0 to convert it to naira. This made the final output easier to read and more accurate for business purposes.

Step 4: Join Everything Together
After preparing the savings, investment, and deposit information separately, I joined them all together using the owner_id to make sure we only included customers who have all three: at least one savings plan, one investment plan, and deposit records.

I also joined this result with the users_customuser table to retrieve user details like names and statuses.

One challenge here was that the name was stored in two different fields — first_name and last_name. To get a proper full name, I had to concatenate the two fields using CONCAT.

Step 5: Filter Out Inactive or Deleted Users
This was another important part. I had to make sure that we only included customers whose accounts are:

- Not deleted (is_account_deleted = 0)

- Not disabled by the system (is_account_disabled = 0)

- Not disabled or deleted by the user themselves

- Adding all these checks was necessary to avoid including inactive or invalid accounts in the final result.

Step 6: Sorting and Performance Optimization
Finally, I sorted the result by total deposits in descending order, so the customers who have deposited the most appear first. This aligns with the business goal of focusing on high-value users. To reduce the size of the result and improve query performance, I added a LIMIT 50 clause. Thus, the query only returns the top 50 high-value customers who meet all the conditions.

Challenges Encountered and How I Solved Them:

Name Concatenation:
Customer names were split into first_name and last_name, so I had to use a function to combine them into one readable full name.

Filtering Inactive Users:
Several account status fields had to be considered (is_account_deleted, is_account_disabled, etc.). Missing one could lead to including blocked or fake accounts, so I added all necessary filters to ensure data quality.

Kobo to Naira Conversion:
The deposit values were in kobo, which is not useful for analysis. I had to divide the total by 100.0 to get the amount in Naira.

Performance Consideration:
Without the LIMIT, the query might return hundreds of rows, especially in a live production database. I added LIMIT 50 to keep the result small and fast.

Question 2: Calculate the average number of transactions per customer per month and categorize them: "High Frequency" (≥10 transactions/month), "Medium Frequency" (3-9 transactions/month), "Low Frequency" (≤2 transactions/month)

Step 1: Identify Customers with Savings Plans
I started by looking into the plans_plan table to find customers who have at least one regular savings plan. To do this, I filtered the rows where is_regular_savings equals 1. Then, I grouped the results by owner_id (the customer) and used the COUNT() function to find out how many savings plans each customer owns.

Step 2: Identify Customers with Investment Plans
Next, I checked the same plans_plan table for customers who have investment plans. These are plans where the is_a_fund flag equals 1. Again, I grouped by owner_id and used COUNT() to find out how many investment plans each customer has.

Step 3: Calculate Total Deposits Per Customer
Then, I went to the savings_savingsaccount table to calculate how much money each customer has deposited. I summed the confirmed_amount column, which records deposit amounts, using the SUM() function grouped by owner_id. However, the amounts were stored in kobo (smallest currency unit), so I divided the total by 100.0 to convert it to naira, making the numbers easier to understand.

Step 4: Combine Savings, Investments, and Deposits Data
After gathering the savings, investment, and deposit data separately, I joined all these results together on owner_id. This way, I included only customers who have at least one savings plan, one investment plan, and deposit records. I also joined this with the users_customuser table to get customer details like their names and status.

Step 5: Create Full Customer Names
The customer’s full name was stored in two fields: first_name and last_name. To display a proper full name, I combined these two fields using the CONCAT() function, which joins text fields together.

Step 6: Filter Out Inactive or Deleted Customers
It was important to exclude customers who were inactive. I filtered out customers whose accounts were deleted (is_account_deleted = 1), disabled by the system (is_account_disabled = 1), or disabled by themselves. Adding these conditions helped ensure the final list only contained active, valid customers.

Step 7: Sort and Limit the Result
Finally, I sorted the results by the total deposit amount in descending order, so customers who deposited the most would appear first. To improve performance and keep the output manageable, I limited the list to the top 50 customers.

Question 3: Find all active accounts (savings or investments) with no transactions in the last 1 year (365 days).

Step 1: Find the Latest Successful Transaction per Plan
I started by looking into the savings_savingsaccount table to find the most recent successful deposit for each savings or investment plan. To do this, I filtered transactions by checking if their transaction_status was either "success" or "successful", using the LOWER() function to make this check case-insensitive. Then, I grouped the transactions by plan_id and used the MAX() function on transaction_date to get the latest transaction date for each plan.

Step 2: Combine Plans with Their Last Activity Date
Next, I took all plans from the plans_plan table and joined them with the results from Step 1 to get the last successful transaction date per plan. I used a LEFT JOIN so that plans without any transactions would still be included. For those plans without any successful transactions, I used the COALESCE() function to use the plan’s creation date (created_on) as their last activity date instead. I also created a new column to classify each plan’s type based on boolean flags — if is_regular_savings equals 1, the type is "Savings"; if is_a_fund equals 1, it’s "Investment"; otherwise, "Other."

Step 3: Find Inactive Plans Over One Year
Finally, I calculated how many days have passed since the plan’s last activity by subtracting the last_activity_date from today’s date using the DATEDIFF() function. I filtered to find only plans that have been inactive for more than 365 days (one year). To prioritize the results, I ordered the plans by their inactivity days in descending order, showing the most inactive plans first. I also limited the output to the top 50 to keep the list manageable.

Challenges Encountered and How I Solved Them:

Case-Insensitive Transaction Status Matching:
The transaction status field could be written in different ways, like "Success", "success", or "SUCCESS". To avoid missing any successful transactions, I applied LOWER() to convert the status text to lowercase before comparison.

Calculating Inactivity in Days:
To find out how long a plan had been inactive, I used the DATEDIFF() function. This function counts the number of days between two dates, which was perfect for this scenario.

Limiting Results and Sorting:
Because there could be thousands of inactive plans, I limited the results to the top 50 and sorted them by inactivity days to show the worst offenders first. This helps the ops team focus their efforts efficiently.


Question 4: For each customer, assuming the profit_per_transaction is 0.1% of the transaction value, calculate: Account tenure (months since signup), Total transactions, Estimated CLV (Assume: CLV = (total_transactions / tenure) * 12 * avg_profit_per_transaction), and Order by estimated CLV from highest to lowest.


Step 1: Get All Successful Transactions
I began by filtering the savings_savingsaccount table to get only transactions marked as successful. This means I looked for rows where transaction_status is either 'success' or 'successful', ignoring case differences. I selected the owner_id (the customer) and the amount of each transaction because these are needed to calculate totals and averages.

Step 2: Summarize Transactions by Customer
Next, I grouped these successful transactions by customer (owner_id). For each customer, I counted how many successful transactions they had using COUNT(*). I also summed up the transaction amounts with SUM(amount) to get the total money transacted. Then, I found the average transaction amount using AVG(amount). These three values give a good picture of each customer's transaction activity.

Step 3: Calculate Customer Tenure in Months and Exclude Inactive Users
I then turned to the users_customuser table to find out how long each customer has been with the company. I took their date_joined and calculated the number of full months between that date and today using the TIMESTAMPDIFF(MONTH, date_joined, CURRENT_DATE) function. This gives the tenure in months. I also created a full name for each customer by combining first_name and last_name with CONCAT(). I also excluded users who have deleted or disabled accounts by themselves or system.

Step 4: Calculate Estimated Customer Lifetime Value (CLV)
To estimate the CLV, I joined the tenure data with the transaction summary on the customer ID. I used the formula given: first, I calculated the average number of transactions per month by dividing total transactions by tenure in months. To avoid dividing by zero (in case a customer has zero months tenure), I used the GREATEST() function to treat zero tenure as one month. Then I multiplied the monthly transaction rate by 12 to get the yearly transaction count. I multiplied this by the average transaction value times 0.001, assuming the amounts are stored in kobo and this factor converts to naira. Finally, I rounded the CLV to the nearest whole number for clarity.

Step 5: Present and Sort Results
Lastly, I selected the customer ID, name, tenure in months, total transactions, and estimated CLV. The results were ordered by the estimated CLV in descending order to show the highest value customers first. I limited the output to the top 50 customers for focus and performance.

Challenges and How I Addressed Them:

Division by Zero Risk:
Some customers could have joined very recently, giving zero months of tenure. Dividing by zero would cause an error, so I used GREATEST(tenure_months, 1) to treat zero tenure as 1 month and avoid errors.


