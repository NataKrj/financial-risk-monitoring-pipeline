-- Run from the repository root with psql.
-- The portfolio data files use ISO dates to avoid locale-dependent parsing.

\copy accounts (account_id, customer_id, init_balance, is_fraud, tx_behavior_id)
FROM 'data/raw/accounts.csv'
WITH (FORMAT csv, HEADER true);

\copy transactions (tx_id, sender_account_id, receiver_account_id, tx_amount, transaction_ts, is_fraud)
FROM 'data/raw/transactions.csv'
WITH (FORMAT csv, HEADER true);

\copy complaints (
    complaint_id, account_id, customer_id, date_received, issue, sub_issue,
    company, state, zip_code, combined_issue, processed_issue,
    initial_cluster, final_cluster, cluster_theme, complaint_theme
)
FROM 'data/processed/complaints_clustered.csv'
WITH (FORMAT csv, HEADER true);
