-- Analytical views used for dashboard-style reporting

CREATE OR REPLACE VIEW vw_dashboard_kpis AS
SELECT
    (SELECT COUNT(*) FROM transactions) AS total_transactions,
    (SELECT COUNT(*) FROM accounts) AS total_clients,
    (SELECT COUNT(*) FROM complaints) AS total_compliance_issues,
    (SELECT COUNT(*) FROM alerts) AS total_alert_observations;

CREATE OR REPLACE VIEW vw_alerts_by_year_scenario AS
SELECT
    EXTRACT(YEAR FROM t.transaction_ts)::INTEGER AS year,
    a.scenario_name,
    COUNT(*) AS alert_count
FROM alerts a
JOIN transactions t ON t.tx_id = a.tx_id
GROUP BY 1, 2
ORDER BY 1, 2;

CREATE OR REPLACE VIEW vw_complaints_by_year_theme AS
SELECT
    EXTRACT(YEAR FROM date_received)::INTEGER AS year,
    complaint_theme,
    COUNT(*) AS complaint_count
FROM complaints
GROUP BY 1, 2
ORDER BY 1, 2;

CREATE OR REPLACE VIEW vw_monthly_alerts_and_complaints AS
WITH alert_monthly AS (
    SELECT
        EXTRACT(YEAR FROM t.transaction_ts)::INTEGER AS year,
        EXTRACT(MONTH FROM t.transaction_ts)::INTEGER AS month,
        COUNT(*) AS alert_count
    FROM alerts a
    JOIN transactions t ON t.tx_id = a.tx_id
    GROUP BY 1, 2
),
complaint_monthly AS (
    SELECT
        EXTRACT(YEAR FROM date_received)::INTEGER AS year,
        EXTRACT(MONTH FROM date_received)::INTEGER AS month,
        COUNT(*) AS complaint_count
    FROM complaints
    GROUP BY 1, 2
)
SELECT
    COALESCE(a.year, c.year) AS year,
    COALESCE(a.month, c.month) AS month,
    COALESCE(a.alert_count, 0) AS alert_count,
    COALESCE(c.complaint_count, 0) AS complaint_count,
    COALESCE(a.alert_count, 0) + COALESCE(c.complaint_count, 0) AS total_issues
FROM alert_monthly a
FULL OUTER JOIN complaint_monthly c
  ON a.year = c.year AND a.month = c.month
ORDER BY 1, 2;

CREATE OR REPLACE VIEW vw_client_risk AS
WITH complaint_counts AS (
    SELECT account_id, COUNT(*) AS complaint_count
    FROM complaints
    GROUP BY account_id
),
alert_counts AS (
    SELECT account_id, COUNT(*) AS alert_count
    FROM alerts
    GROUP BY account_id
),
combined AS (
    SELECT
        COALESCE(c.account_id, a.account_id) AS account_id,
        COALESCE(c.complaint_count, 0) AS complaint_count,
        COALESCE(a.alert_count, 0) AS alert_count
    FROM complaint_counts c
    FULL OUTER JOIN alert_counts a USING (account_id)
)
SELECT
    *,
    complaint_count + alert_count AS total_issues,
    CASE
        WHEN complaint_count + alert_count <= 1 THEN 'Low'
        WHEN complaint_count + alert_count <= 4 THEN 'Medium'
        WHEN complaint_count + alert_count <= 7 THEN 'High'
        ELSE 'Prohibited / very high'
    END AS risk_band
FROM combined;
