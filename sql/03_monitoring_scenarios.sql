-- Scenario-based monitoring rules used by the Tableau dashboard.
-- alerts is treated as an event/observation table, not a table of unique investigations.

TRUNCATE TABLE alerts RESTART IDENTITY;

-- SCENARIO_501: Transaction > 10,000
INSERT INTO alerts (
    scenario_code, scenario_name, tx_id, account_id,
    counterparty_account_id, alert_description
)
SELECT
    'SCENARIO_501',
    'Transaction >10,000',
    tx_id,
    sender_account_id,
    receiver_account_id,
    'Transaction amount greater than 10,000.'
FROM transactions
WHERE tx_amount > 10000;

-- SCENARIO_502: High total outflow by account
WITH high_outflow_accounts AS (
    SELECT sender_account_id
    FROM transactions
    GROUP BY sender_account_id
    HAVING SUM(tx_amount) > 50000
)
INSERT INTO alerts (
    scenario_code, scenario_name, tx_id, account_id,
    counterparty_account_id, alert_description
)
SELECT
    'SCENARIO_502',
    'High Outflow by Account',
    t.tx_id,
    t.sender_account_id,
    t.receiver_account_id,
    'Sender account total outflow exceeds 50,000.'
FROM transactions t
JOIN high_outflow_accounts h
  ON h.sender_account_id = t.sender_account_id;

-- SCENARIO_503: Directed two-way circular pattern.
-- The Tableau story represents both legs of every directed match.
WITH directed_pairs AS (
    SELECT
        t1.tx_id AS tx1_id,
        t2.tx_id AS tx2_id,
        t1.sender_account_id AS a1,
        t1.receiver_account_id AS a2
    FROM transactions t1
    JOIN transactions t2
      ON t1.receiver_account_id = t2.sender_account_id
     AND t1.sender_account_id = t2.receiver_account_id
     AND t1.tx_id <> t2.tx_id
),
legs AS (
    SELECT
        tx1_id AS tx_id,
        tx2_id AS related_tx_id,
        a1 AS account_id,
        a2 AS counterparty_account_id
    FROM directed_pairs
    UNION ALL
    SELECT
        tx2_id,
        tx1_id,
        a2,
        a1
    FROM directed_pairs
)
INSERT INTO alerts (
    scenario_code, scenario_name, tx_id, related_tx_id,
    account_id, counterparty_account_id, alert_description
)
SELECT
    'SCENARIO_503',
    'Circular Scheme',
    tx_id,
    related_tx_id,
    account_id,
    counterparty_account_id,
    'Two-way circular transaction pattern detected.'
FROM legs;

-- SCENARIO_504: Source fraud indicator
INSERT INTO alerts (
    scenario_code, scenario_name, tx_id, account_id,
    counterparty_account_id, alert_description
)
SELECT
    'SCENARIO_504',
    'Fraud',
    tx_id,
    sender_account_id,
    receiver_account_id,
    'Transaction is marked as fraudulent in the source dataset.'
FROM transactions
WHERE is_fraud = TRUE;

-- SCENARIO_505: Transaction > 1,000,000
INSERT INTO alerts (
    scenario_code, scenario_name, tx_id, account_id,
    counterparty_account_id, alert_description
)
SELECT
    'SCENARIO_505',
    'Large Transaction > 1M',
    tx_id,
    sender_account_id,
    receiver_account_id,
    'Transaction amount greater than 1,000,000.'
FROM transactions
WHERE tx_amount > 1000000;

-- SCENARIO_506: Transaction matches sender's initial balance
INSERT INTO alerts (
    scenario_code, scenario_name, tx_id, account_id,
    counterparty_account_id, alert_description
)
SELECT
    'SCENARIO_506',
    'Full withdrawal',
    t.tx_id,
    t.sender_account_id,
    t.receiver_account_id,
    'Transaction amount matches the sender''s initial account balance.'
FROM transactions t
JOIN accounts a
  ON a.account_id = t.sender_account_id
WHERE t.tx_amount = a.init_balance;
