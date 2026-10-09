# Data model

The portfolio schema has four main entities:

- **accounts** — customer account snapshot and initial balance;
- **transactions** — sender/receiver transaction records;
- **complaints** — customer complaint records enriched with clustering output;
- **alerts** — scenario-based transaction-monitoring observations.

Relationships:

- one account can send many transactions;
- one account can receive many transactions;
- one account can have many complaints;
- one transaction can trigger multiple monitoring scenarios;
- circular-pattern alerts may reference a related transaction.

`original_erd.png` is the ERD exported during the original project. The cleaned PostgreSQL implementation in `sql/01_schema.sql` refines several data types (for example ZIP codes are stored as text).
