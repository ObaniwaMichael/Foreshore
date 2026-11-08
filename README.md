# Foreshore Holdings — Flutter MVP

Digitizes the daily field-collection (esusu/ajo) savings & loan model from the BRD and investor walkthrough.

## What's included

| Piece | Path | Role |
|---|---|---|
| API + ledger | `backend/` | FastAPI, SQLite by default (Postgres via `DATABASE_URL`) |
| Shared Dart package | `packages/foreshore_core` | Models, ₦ money helpers, API client |
| Agent app | `apps/agent` | Route, collect, onboard, day summary + offline queue |
| Admin app | `apps/admin` | EOD reconciliation, loans, withdrawals, reports |

## Demo logins (seeded on first API start)

| Role | Phone | Password |
|---|---|---|
| Agent | `08011110001` | `agent123` |
| Admin | `08011110002` | `admin123` |
| Management | `08011110003` | `mgmt123` |

Seed data includes 8 customers on the agent's route, ~2 weeks of contribution history, and one pending ₦300,000 loan request.

## Business rule defaults

- Withdrawal charge = **one day's usual contribution**
- Loan interest = **20% flat** for the month; overdue loans are flagged only
- Closed collection days are **immutable** (sign-off locks entries)

## Run locally

### 1. Backend

```powershell
cd backend
python -m pip install -r requirements.txt
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

API docs: http://localhost:8000/docs

Optional Postgres:

```powershell
$env:DATABASE_URL = "postgresql+psycopg://user:pass@localhost:5432/foreshore"
```

### 2. Agent app

```powershell
cd apps/agent
flutter pub get
flutter run -d windows
# or Android emulator (API defaults to 10.0.2.2:8000)
flutter run -d android --dart-define=API_BASE=http://10.0.2.2:8000
```

### 3. Admin app

```powershell
cd apps/admin
flutter pub get
flutter run -d chrome
# or
flutter run -d windows
```

Override API URL anywhere:

```powershell
flutter run --dart-define=API_BASE=http://192.168.x.x:8000
```

## Pilot path (walkthrough)

1. Agent signs in → sees today's route → one-tap collect (or edit amount)
2. Works offline: failed posts queue locally; cloud icon syncs when online
3. Agent opens **Day** → declares cash on hand (mismatch flagged in red)
4. Admin signs in → **Reconcile** → compares declared vs system → **Sign off & lock**
5. Admin **Loans** → approve Chioma's ₦300k request (repayable auto-calculated)
6. Admin **Withdrawals** / **Reports** for payouts and cash position

## Backup note

With SQLite, copy `backend/foreshore.db` daily. With Postgres, schedule `pg_dump`. The BRD requires daily backups of ledger and customer data (NFR-5).

## Deferred (Phase 4)

Customer WhatsApp/SMS statements, automated loan risk scoring, bank/payment gateways, regulatory tooling.
