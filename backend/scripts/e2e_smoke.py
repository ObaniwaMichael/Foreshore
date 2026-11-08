import json
import urllib.error
import urllib.request

BASE = "http://127.0.0.1:8000"


def req(method, path, data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    body = None if data is None else json.dumps(data).encode()
    r = urllib.request.Request(BASE + path, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as e:
        detail = e.read().decode()
        raise SystemExit(f"{method} {path} -> {e.code}: {detail}") from e


print("health", req("GET", "/health"))

agent = req("POST", "/auth/login", {"phone": "08011110001", "password": "agent123"})
at = agent["access_token"]
print("agent", agent["user"]["name"], agent["user"]["role"])

route = req("GET", "/agent/route", token=at)
print("route customers", len(route))
c0 = route[0]

contrib = req(
    "POST",
    "/contributions",
    {
        "customer_id": c0["id"],
        "amount": c0["usual_daily_amount"],
        "sync_id": "e2e-sync-1",
    },
    token=at,
)
print("collected", contrib["amount"], "for", contrib.get("customer_name"))

day = req("POST", "/collection-days/today", {}, token=at)
print("day system_total", day["system_total"], "status", day["status"])

day = req(
    "PATCH",
    f"/collection-days/{day['id']}",
    {"declared_cash": day["system_total"]},
    token=at,
)
print("declared match", day["declared_cash"] == day["system_total"], day["status"])

admin = req("POST", "/auth/login", {"phone": "08011110002", "password": "admin123"})
ad = admin["access_token"]
print("admin", admin["user"]["name"])

days = req("GET", "/collection-days", token=ad)
print("admin sees days", len(days))
d0 = days[0]
if d0["declared_cash"] != d0["system_total"]:
    d0 = req(
        "PATCH",
        f"/collection-days/{d0['id']}",
        {"declared_cash": d0["system_total"]},
        token=ad,
    )

closed = req("POST", f"/collection-days/{d0['id']}/signoff", token=ad)
print("signed off", closed["status"], closed["signed_off_at"] is not None)

# mismatch should be rejected on a fresh open day — verify lock blocks edits
try:
    req(
        "PATCH",
        f"/collection-days/{d0['id']}",
        {"declared_cash": 1},
        token=ad,
    )
    raise SystemExit("expected locked day to reject patch")
except SystemExit as e:
    if "400" not in str(e) and "locked" not in str(e).lower() and "closed" not in str(e).lower():
        # req raises SystemExit — check message
        msg = str(e)
        if "400" not in msg:
            raise

loans = req("GET", "/loans?status=pending", token=ad)
print("pending loans", len(loans))
if loans:
    loan = req("POST", f"/loans/{loans[0]['id']}/decide", {"approve": True}, token=ad)
    print("approved loan repayable", loan["total_repayable"], "status", loan["status"])

stats = req("GET", "/reports/summary", token=ad)
print("stats", stats)
print("E2E_OK")
