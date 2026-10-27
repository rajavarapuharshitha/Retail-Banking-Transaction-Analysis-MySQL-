CREATE DATABASE retail_banking;
USE retail_banking;

-- Branches Table
CREATE TABLE branches (
    branch_id VARCHAR(10) PRIMARY KEY,
    branch_name VARCHAR(100),
    city VARCHAR(50),
    state VARCHAR(30),
    region VARCHAR(30),
    opening_date DATE,
    employee_count INT
);

-- Customers Table
CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    date_of_birth DATE,
    gender VARCHAR(20),
    city VARCHAR(50),
    state VARCHAR(30),
    customer_since DATE,
    kyc_status VARCHAR(20),
    segment VARCHAR(30),
    annual_income DECIMAL(12,2),
    credit_score INT,
    is_active VARCHAR(3)
);

-- Accounts Table (Connected to customers & branches)
CREATE TABLE accounts (
    account_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    branch_id VARCHAR(10),
    account_type VARCHAR(30),
    open_date DATE,
    close_date DATE,
    current_balance DECIMAL(15,2),
    interest_rate DECIMAL(5,2),
    overdraft_limit DECIMAL(12,2),
    status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

-- Loans Table
CREATE TABLE loans (
    loan_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    branch_id VARCHAR(10),
    loan_type VARCHAR(30),
    principal_amount DECIMAL(15,2),
    interest_rate DECIMAL(5,2),
    tenure_months INT,
    disbursement_date DATE,
    maturity_date DATE,
    emi_amount DECIMAL(12,2),
    outstanding_balance DECIMAL(15,2),
    loan_status VARCHAR(30),
    purpose VARCHAR(30),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

-- Cards Table
CREATE TABLE cards (
    card_id VARCHAR(20) PRIMARY KEY,
    account_id VARCHAR(20),
    card_type VARCHAR(20),
    issue_date DATE,
    expiry_date DATE,
    credit_limit DECIMAL(12,2),
    outstanding_balance DECIMAL(12,2),
    reward_points INT,
    is_active VARCHAR(3),
    network VARCHAR(20),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Transactions Table
CREATE TABLE transactions (
    transaction_id VARCHAR(20) PRIMARY KEY,
    account_id VARCHAR(20),
    transaction_date DATE,
    transaction_time TIME,
    transaction_type VARCHAR(30),
    amount DECIMAL(15,2),
    channel VARCHAR(30),
    description VARCHAR(50),
    balance_after DECIMAL(15,2),
    status VARCHAR(20),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

-- Loan Payments Table
CREATE TABLE loan_payments (
    payment_id VARCHAR(20) PRIMARY KEY,
    loan_id VARCHAR(20),
    payment_date DATE,
    scheduled_amount DECIMAL(12,2),
    paid_amount DECIMAL(12,2),
    principal_paid DECIMAL(12,2),
    interest_paid DECIMAL(12,2),
    penalty DECIMAL(12,2),
    days_late INT,
    payment_method VARCHAR(30),
    status VARCHAR(30),
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
);

SELECT COUNT(*) FROM customers;      -- Expected: 500 rows[cite: 1]
SELECT COUNT(*) FROM accounts;       -- Expected: 700 rows[cite: 1]
SELECT COUNT(*) FROM branches;       -- Expected: 40 rows[cite: 1]
SELECT COUNT(*) FROM loans;          -- Expected: 300 rows[cite: 1]
SELECT COUNT(*) FROM loan_payments;  -- Expected: 2,000 rows[cite: 1]
SELECT COUNT(*) FROM cards;          -- Expected: 600 rows[cite: 1]
SELECT COUNT(*) FROM transactions;   -- Expected: 5,000 rows[cite: 1]

SELECT COUNT(*) AS total_customers FROM customers;

SELECT COUNT(*) AS total_accounts FROM accounts;

SELECT COUNT(*) AS total_branches From branches;

SELECT COUNT(*) AS total_loans From loans;

SELECT DISTINCT account_type FROM accounts;

SELECT COUNT(*) AS active_customers FROM customers WHERE is_active = 'Yes';

SELECT SUM(amount) AS total_completed_amount 
FROM transactions 
WHERE status = 'Completed';

SELECT SUM(outstanding_balance) AS total_outstanding_loan 
FROM loans;

SELECT 
    segment,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(annual_income), 2) AS avg_annual_income,
    ROUND(AVG(credit_score), 2) AS avg_credit_score
FROM customers
GROUP BY segment
ORDER BY avg_annual_income DESC;


SELECT 
    b.branch_name,
    b.city,
    COUNT(a.account_id) AS total_accounts,
    ROUND(SUM(a.current_balance), 2) AS total_branch_balance,
    ROUND(AVG(a.current_balance), 2) AS avg_account_balance
FROM branches b
JOIN accounts a ON b.branch_id = a.branch_id
GROUP BY b.branch_id, b.branch_name, b.city
ORDER BY total_branch_balance DESC;

SELECT 
    channel,
    COUNT(transaction_id) AS total_transactions,
    ROUND(SUM(amount), 2) AS total_transaction_amount,
    ROUND(AVG(amount), 2) AS avg_transaction_amount
FROM transactions
WHERE status = 'Completed'
GROUP BY channel
ORDER BY total_transaction_amount DESC;

WITH RankedLoans AS (
    SELECT 
        loan_id,
        customer_id,
        loan_type,
        outstanding_balance,
        loan_status,
        DENSE_RANK() OVER (PARTITION BY loan_type ORDER BY outstanding_balance DESC) AS rnk
    FROM loans
)
SELECT 
    loan_id,
    customer_id,
    loan_type,
    outstanding_balance,
    loan_status
FROM RankedLoans
WHERE rnk <= 3;

SELECT 
    card_type,
    network,
    COUNT(card_id) AS total_cards,
    ROUND(AVG(credit_limit), 2) AS avg_credit_limit,
    ROUND(AVG(outstanding_balance), 2) AS avg_outstanding_balance,
    SUM(reward_points) AS total_reward_points
FROM cards
WHERE is_active = 'Yes'
GROUP BY card_type, network
ORDER BY avg_outstanding_balance DESC;

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.segment,
    COUNT(DISTINCT a.account_id) AS num_accounts,
    COUNT(DISTINCT cr.card_id) AS num_cards,
    COUNT(DISTINCT l.loan_id) AS num_loans
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
JOIN cards cr ON a.account_id = cr.account_id
JOIN loans l ON c.customer_id = l.customer_id
GROUP BY c.customer_id, customer_name, c.segment
HAVING num_accounts > 0 AND num_cards > 0 AND num_loans > 0;
