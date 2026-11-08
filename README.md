# Foreshore Holdings — Business Requirements Document

**Audience:** investors  
**Product:** daily field-collection savings and loans (esusu / ajo), run from a phone instead of a notebook.

---

## 1. The opportunity

Millions of Nigerians already save through esusu/ajo: an agent walks a route every day, collects a fixed amount, and the company later pays out savings, loans, and withdrawals. The model works. The books do not.

Collections still live on paper, in agents’ heads, and in end-of-day cash counts that cannot be checked. That is leak, dispute, and a ceiling on how many customers one operator can run.

Foreshore digitizes the **same** business — not a bank app, not a new savings product. It makes the existing daily-collection machine trustworthy and scalable.

---

## 2. The problem

| Today | What it costs |
|---|---|
| Notebooks and WhatsApp | Lost cards, disputed balances, no audit trail |
| Cash counted at night | Shortages found too late; agents and office argue |
| Loans on a spreadsheet | Interest miscalculated; who owes what is unclear |
| Withdrawals by memory | Customers overpaid or delayed; charge rules skipped |
| One closed day is still editable | History can be rewritten after the fact |

Investors should treat this as **operational risk sitting on a cash business**, not as a missing feature.

---

## 3. What Foreshore does

Two roles, one ledger.

**In the field (agent)**  
Sees today’s route. Records each collection in seconds. Works when the network drops and catches up later. At close of day, declares cash on hand.

**In the office (admin / management)**  
Compares declared cash vs what the system says was collected. Signs off and **locks the day**. Approves loans. Pays withdrawals. Sees cash position and customer history.

The product is the **source of truth for money that already moved in cash**.

---

## 4. How the money works (the model we encode)

These are the business rules, not software details:

- Customers save a **usual daily amount**. Agents collect it on a named route.
- A collection day is open until the office signs it off. After sign-off, that day **cannot be changed**.
- If declared cash ≠ system total, the day is flagged as a **mismatch** before anyone locks it.
- **Loans:** 20% flat for the month (e.g. ₦300,000 borrowed → ₦360,000 to repay). Overdue is visible; we do not quietly rewrite the contract.
- **Withdrawals:** the charge is **one day’s usual contribution** — simple, explainable at the counter.

That is the product moat at this stage: rules that match how the street already operates, enforced every day.

---

## 5. Who it is for

| Who | Job to be done |
|---|---|
| Field agents | Finish the route with a complete, honest day |
| Branch / ops admin | Reconcile cash, lock the day, process loans and payouts |
| Management | See collections, loans outstanding, and cash without waiting for a spreadsheet |
| The operator (Foreshore) | Grow customer count without growing “notebook risk” at the same rate |

Customers do not need an app for v1. They keep saving the way they do today. The company gets the ledger.

---

## 6. What “done” looks like for a pilot

A live day, end to end:

1. Agent logs in → today’s names → collect (or change the amount) → even offline.
2. Agent declares cash. Mismatch shows in red.
3. Office reconciles, signs off, day is frozen.
4. Office can approve a loan (repay amount calculated, not typed from memory).
5. Office can pay a withdrawal with the charge applied.
6. Management can see totals and a customer’s statement.

If that loop runs every working day, the notebook is retired.

---

## 7. What this is not (yet)

Out of scope for this phase, on purpose:

- Customer WhatsApp / SMS statements  
- Credit scoring / automated risk  
- Bank or card rails (this is still a cash-collection business)  
- Full regulatory stack  

Those are expansion, not the reason to fund the first year. The first year is **control of daily cash**.

---

## 8. Why it is investable

- **Known demand.** Esusu/ajo is not a behaviour we have to create. We replace a broken back office.
- **Clear unit of value.** One agent-day, fully collected, declared, and locked.
- **Loss prevention.** Mismatch + immutable closed days is cheaper than hiring more supervisors.
- **Credit on top of savings.** Loans and withdrawals sit on a real contribution history, not a form.
- **Path to scale.** Same process, more routes — without multiplying paper.

---

## 9. Success for investors

Pilot is working when:

- Agents stop using parallel notebooks for the live route  
- Every working day is signed off (or explicitly mismatched) the same day  
- Loan and withdrawal amounts match the stated rules, every time  
- Management can answer “how much cash, how much owed” without calling the field  

That is the business Foreshore is building: **daily collection, with a ledger you can take to an investor, an auditor, or a bank.**
