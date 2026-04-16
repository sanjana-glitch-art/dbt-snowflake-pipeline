# build_mau — dbt + Snowflake Project

## Project Overview

This project implements a dbt pipeline connected to Snowflake that transforms raw session data into an analytics-ready summary table. It includes ephemeral transform models, a table-materialized analytics model, a snapshot for SCD tracking, and data quality tests.

---

## Tech Stack

- **dbt** v1.11.8
- **Snowflake** (adapter v1.11.4)
- **Python** 3.11.0
- **Warehouse:** FLAMINGO_QUERY_WH
- **Database:** USER_DB_FLAMINGO

---

## Project Structure

```
build_mau/
├── models/
│   ├── transform/
│   │   ├── user_session_channel_cleaned.sql   # Ephemeral CTE model
│   │   └── session_timestamp_cleaned.sql      # Ephemeral CTE model
│   ├── analytics/
│   │   └── session_summary.sql                # Table model (final output)
│   ├── sources.yml                            # Source definitions (RAW schema)
│   └── schema.yml                            # Data tests
├── snapshots/
│   └── snapshot_session_summary.sql           # SCD snapshot
├── dbt_project.yml
└── profiles.yml  (stored in ~/.dbt/)
```

---

## Setup Instructions

### 1. Prerequisites

- Python 3.11+
- Snowflake account with appropriate credentials

### 2. Create and activate a virtual environment

```powershell
python -m venv dbt_env --without-pip
dbt_env\Scripts\Activate.ps1
python -m ensurepip --upgrade
```

### 3. Install dbt-snowflake

```powershell
python -m pip install dbt-snowflake
```

### 4. Initialize the project

```powershell
dbt init build_mau
```

Configure with your Snowflake credentials when prompted.

### 5. Validate connection

```powershell
cd build_mau
dbt debug
```

---

## Models

### Transform Layer (`ephemeral`)

These models are built as CTEs (not materialized as tables in Snowflake) — configured via `dbt_project.yml`.

**`user_session_channel_cleaned.sql`**
```sql
SELECT userId, sessionId, channel
FROM {{ source("raw", "user_session_channel") }}
WHERE sessionId IS NOT NULL
```

**`session_timestamp_cleaned.sql`**
```sql
SELECT sessionId, ts
FROM {{ source("raw", "session_timestamp") }}
WHERE sessionId IS NOT NULL
```

### Analytics Layer (`table`)

**`session_summary.sql`**
```sql
SELECT u.*, s.ts
FROM {{ ref("user_session_channel_cleaned") }} u
JOIN {{ ref("session_timestamp_cleaned") }} s
ON u.sessionId = s.sessionId
```

---

## Snapshot

Tracks historical changes to `session_summary` using a timestamp strategy.

**`snapshot_session_summary.sql`**
```sql
{% snapshot snapshot_session_summary %}
{{
  config(
    target_schema='snapshot',
    unique_key='sessionId',
    strategy='timestamp',
    updated_at='ts',
    invalidate_hard_deletes=True
  )
}}
SELECT * FROM {{ ref('session_summary') }}
{% endsnapshot %}
```

---

## Data Tests

Two tests are applied to the `sessionId` field of `session_summary` in `schema.yml`:

| Test | Description |
|------|-------------|
| `unique` | Ensures no duplicate session IDs |
| `not_null` | Ensures every row has a session ID |

---

## Running the Project

```powershell
# Build all models
dbt run

# Run snapshot
dbt snapshot

# Run data tests
dbt test
```

### Expected Output

```
dbt run   → PASS=1  WARN=0  ERROR=0  TOTAL=1
dbt snapshot → PASS=1  WARN=0  ERROR=0  TOTAL=1
dbt test  → PASS=2  WARN=0  ERROR=0  TOTAL=2
```

---

## dbt_project.yml (Materialization Config)

```yaml
models:
  build_mau:
    transform:
      +materialized: ephemeral
    analytics:
      +materialized: table
```
