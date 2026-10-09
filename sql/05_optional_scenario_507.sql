-- Optional rule from the original SQL coursework.
-- It was not part of the final Tableau story.

INSERT INTO alerts (
    scenario_code, scenario_name, tx_id, account_id,
    counterparty_account_id, alert_description
)
SELECT
    'SCENARIO_507',
    'Large rounded transaction',
    tx_id,
    sender_account_id,
    receiver_account_id,
    'Transaction amount is greater than 10,000 and divisible by 10.'
FROM transactions
WHERE tx_amount > 10000
  AND MOD(tx_amount, 10) = 0;
