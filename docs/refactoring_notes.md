# Portfolio refactoring notes

This repository consolidates two linked academic projects into one portfolio case study while preserving the original analytical intent.

## Changes made

1. **Credentials removed.** MongoDB Atlas username/connection placeholders are not included in executable portfolio code.
2. **Local reproducibility added.** The public notebook reads repository-local JSON/CSV snapshots instead of requiring MongoDB.
3. **Column names standardized.** Portfolio CSVs use snake_case.
4. **Dates standardized.** Dates are stored in ISO `YYYY-MM-DD` format.
5. **Complaint/account linkage repaired.** The processed clustering file used `CUSTOMER_ID`; the portfolio version maps this deterministically to `account_id`.
6. **ZIP codes treated as text.** This preserves leading zeros and avoids treating postal codes as numeric measures.
7. **SQL schema cleaned.** The trailing comma in the original complaints table definition was removed and keys/types were aligned with the actual data.
8. **Scenario 502 linked to transactions.** High-outflow alerts now keep the actual transaction ID instead of inserting `NULL`.
9. **Circular rule clarified.** The original SQL used an unused third transaction alias. The portfolio version implements the two-way pattern that was actually used in the visualisation workflow.
10. **No random state imputation.** The visualisation experiment assigned random states when account geography was missing. The portfolio processing leaves unsupported geography unknown.
11. **Dashboard metric semantics documented.** `1,770` represents alert-event observations. Circular matches are directional and both transaction legs are represented.
12. **Optional rounded-amount rule separated.** Scenario 507 is retained as an optional SQL file because it was part of the SQL coursework but not part of the final Tableau story.

## Why the original reports are not published

The coursework PDFs/notebooks contain student identifiers, installation logs, intermediate experiments and development history. The public repository instead presents the cleaned final methodology, code, data snapshots and visualisation artifacts.
