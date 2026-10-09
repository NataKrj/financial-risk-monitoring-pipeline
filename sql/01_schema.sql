-- PostgreSQL schema for the portfolio refactor
-- Financial Risk Monitoring Pipeline

DROP TABLE IF EXISTS alerts CASCADE;
DROP TABLE IF EXISTS complaints CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;

CREATE TABLE accounts (
    account_id        INTEGER PRIMARY KEY,
    customer_id       VARCHAR(50) NOT NULL UNIQUE,
    init_balance      NUMERIC(18,2),
    is_fraud          BOOLEAN NOT NULL DEFAULT FALSE,
    tx_behavior_id    INTEGER
);

CREATE TABLE transactions (
    tx_id                 BIGINT PRIMARY KEY,
    sender_account_id     INTEGER NOT NULL REFERENCES accounts(account_id),
    receiver_account_id   INTEGER NOT NULL REFERENCES accounts(account_id),
    tx_amount             NUMERIC(18,2) NOT NULL,
    transaction_ts        TIMESTAMP NOT NULL,
    is_fraud              BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE complaints (
    complaint_id       BIGINT PRIMARY KEY,
    account_id         INTEGER NOT NULL REFERENCES accounts(account_id),
    customer_id        VARCHAR(50) NOT NULL,
    date_received      DATE NOT NULL,
    issue              TEXT NOT NULL,
    sub_issue          TEXT,
    company            TEXT,
    state              VARCHAR(2),
    zip_code           VARCHAR(10),
    combined_issue     TEXT,
    processed_issue    TEXT,
    initial_cluster    INTEGER,
    final_cluster      INTEGER,
    cluster_theme      TEXT,
    complaint_theme    TEXT
);

CREATE TABLE alerts (
    alert_event_id            BIGSERIAL PRIMARY KEY,
    scenario_code             VARCHAR(20) NOT NULL,
    scenario_name             TEXT NOT NULL,
    tx_id                     BIGINT NOT NULL REFERENCES transactions(tx_id),
    related_tx_id             BIGINT REFERENCES transactions(tx_id),
    account_id                INTEGER NOT NULL REFERENCES accounts(account_id),
    counterparty_account_id   INTEGER REFERENCES accounts(account_id),
    alert_description         TEXT NOT NULL
);

CREATE INDEX idx_transactions_sender ON transactions(sender_account_id);
CREATE INDEX idx_transactions_receiver ON transactions(receiver_account_id);
CREATE INDEX idx_transactions_ts ON transactions(transaction_ts);
CREATE INDEX idx_complaints_account ON complaints(account_id);
CREATE INDEX idx_complaints_date ON complaints(date_received);
CREATE INDEX idx_alerts_account ON alerts(account_id);
CREATE INDEX idx_alerts_scenario ON alerts(scenario_code);
