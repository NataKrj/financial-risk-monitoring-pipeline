"""Build the processed dashboard input files from the repository data snapshots.

This script intentionally:
- uses only repository-local files;
- does not require MongoDB credentials;
- does not randomly impute missing geography;
- reproduces the six alert categories used in the Tableau story.
"""

from pathlib import Path
import pandas as pd
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

accounts = pd.read_csv(DATA / "raw" / "accounts.csv")
transactions = pd.read_csv(DATA / "raw" / "transactions.csv")
complaints = pd.read_csv(DATA / "processed" / "complaints_clustered.csv")

rows = []

def add(df, code, name, description):
    for _, r in df.iterrows():
        rows.append({
            "scenario_code": code,
            "scenario_name": name,
            "tx_id": int(r["tx_id"]),
            "related_tx_id": pd.NA,
            "account_id": int(r["sender_account_id"]),
            "counterparty_account_id": int(r["receiver_account_id"]),
            "tx_amount": float(r["tx_amount"]),
            "transaction_ts": r["transaction_ts"],
            "alert_description": description,
        })

add(transactions[transactions.tx_amount > 10000],
    "SCENARIO_501", "Transaction >10,000",
    "Transaction amount greater than 10,000.")

totals = transactions.groupby("sender_account_id").tx_amount.sum()
high = totals[totals > 50000].index
add(transactions[transactions.sender_account_id.isin(high)],
    "SCENARIO_502", "High Outflow by Account",
    "Sender account total outflow exceeds 50,000.")

pairs = transactions.merge(
    transactions,
    left_on="receiver_account_id",
    right_on="sender_account_id",
    suffixes=("_1", "_2"),
)
pairs = pairs[pairs.sender_account_id_1 == pairs.receiver_account_id_2]

for _, r in pairs.iterrows():
    rows.append({
        "scenario_code": "SCENARIO_503",
        "scenario_name": "Circular Scheme",
        "tx_id": int(r.tx_id_1),
        "related_tx_id": int(r.tx_id_2),
        "account_id": int(r.sender_account_id_1),
        "counterparty_account_id": int(r.receiver_account_id_1),
        "tx_amount": float(r.tx_amount_1),
        "transaction_ts": r.transaction_ts_1,
        "alert_description": "Two-way circular transaction pattern detected.",
    })
    rows.append({
        "scenario_code": "SCENARIO_503",
        "scenario_name": "Circular Scheme",
        "tx_id": int(r.tx_id_2),
        "related_tx_id": int(r.tx_id_1),
        "account_id": int(r.sender_account_id_2),
        "counterparty_account_id": int(r.receiver_account_id_2),
        "tx_amount": float(r.tx_amount_2),
        "transaction_ts": r.transaction_ts_2,
        "alert_description": "Two-way circular transaction pattern detected.",
    })

add(transactions[transactions.is_fraud.astype(str).str.lower().isin(["true", "1"])],
    "SCENARIO_504", "Fraud",
    "Transaction is marked as fraudulent in the source dataset.")

add(transactions[transactions.tx_amount > 1_000_000],
    "SCENARIO_505", "Large Transaction > 1M",
    "Transaction amount greater than 1,000,000.")

balance = transactions.merge(
    accounts[["account_id", "init_balance"]],
    left_on="sender_account_id",
    right_on="account_id",
    how="inner",
)
balance = balance[np.isclose(balance.tx_amount, balance.init_balance)]
add(balance, "SCENARIO_506", "Full withdrawal",
    "Transaction amount matches the sender's initial account balance.")

alerts = pd.DataFrame(rows)
alerts.insert(0, "alert_event_id", range(1, len(alerts) + 1))
alerts.to_csv(DATA / "processed" / "transaction_scenarios.csv", index=False)

complaint_counts = complaints.groupby("account_id").size().rename("complaint_count")
alert_counts = alerts.groupby("account_id").size().rename("alert_count")
client = pd.concat([complaint_counts, alert_counts], axis=1).fillna(0).astype(int).reset_index()
client["total_issues"] = client.complaint_count + client.alert_count

def band(n):
    if n <= 1:
        return "Low"
    if n <= 4:
        return "Medium"
    if n <= 7:
        return "High"
    return "Prohibited / very high"

client["risk_band"] = client.total_issues.map(band)
client.to_csv(DATA / "processed" / "client_risk.csv", index=False)

kpis = pd.DataFrame([{
    "total_transactions": len(transactions),
    "total_clients": len(accounts),
    "total_compliance_issues": len(complaints),
    "total_alert_observations": len(alerts),
}])
kpis.to_csv(DATA / "processed" / "dashboard_kpis.csv", index=False)

print(kpis.to_string(index=False))
print("\nAlert observations by scenario:")
print(alerts.scenario_name.value_counts().to_string())
