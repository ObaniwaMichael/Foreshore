"""Cloudflare Python Worker spike: POST /auth/login and POST /contributions/sync."""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import time
import uuid
from datetime import datetime, timezone
from typing import Optional

import bcrypt
from fastapi import Depends, FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from workers import asgi

ACCESS_TOKEN_EXPIRE_HOURS = 72
DEFAULT_SECRET = "foreshore-dev-secret-change-me"

app = FastAPI(title="Foreshore Holdings API", version="1.0.0-worker-spike")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class LoginIn(BaseModel):
    phone: str
    password: str


class ContributionIn(BaseModel):
    customer_id: str
    amount: int = Field(gt=0)
    sync_id: Optional[str] = None
    collected_at: Optional[datetime] = None


class SyncIn(BaseModel):
    items: list[ContributionIn]


def env_of(request: Request):
    return request.scope["env"]


def db_of(request: Request):
    return env_of(request).DB


def secret_of(request: Request) -> str:
    env = env_of(request)
    try:
        value = env.FORESHORE_SECRET
    except Exception:
        value = None
    return value or DEFAULT_SECRET


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _b64url_decode(data: str) -> bytes:
    pad = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(data + pad)


def create_token(user_id: str, role: str, secret: str) -> str:
    header = _b64url(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
    payload = _b64url(
        json.dumps(
            {
                "sub": user_id,
                "role": role,
                "exp": int(time.time()) + ACCESS_TOKEN_EXPIRE_HOURS * 3600,
            },
            separators=(",", ":"),
        ).encode()
    )
    signing = f"{header}.{payload}".encode()
    sig = hmac.new(secret.encode("utf-8"), signing, hashlib.sha256).digest()
    return f"{header}.{payload}.{_b64url(sig)}"


def decode_token(token: str, secret: str) -> dict:
    try:
        header_b64, payload_b64, sig_b64 = token.split(".")
        signing = f"{header_b64}.{payload_b64}".encode()
        expected = hmac.new(secret.encode("utf-8"), signing, hashlib.sha256).digest()
        if not hmac.compare_digest(expected, _b64url_decode(sig_b64)):
            raise ValueError("bad signature")
        payload = json.loads(_b64url_decode(payload_b64))
        if int(payload.get("exp", 0)) < int(time.time()):
            raise ValueError("expired")
        return payload
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Invalid token") from exc


def verify_password(password: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(password.encode("utf-8"), hashed.encode("utf-8"))
    except Exception:
        return False


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def iso(dt: datetime) -> str:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).isoformat()


async def require_agent_or_admin(
    request: Request,
    authorization: Optional[str] = Header(default=None),
) -> dict:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Not authenticated")
    payload = decode_token(authorization.split(" ", 1)[1], secret_of(request))
    user_id = payload.get("sub")
    row = await db_of(request).prepare("SELECT * FROM users WHERE id = ?").bind(user_id).first()
    if row is None:
        raise HTTPException(status_code=401, detail="User not found")
    if row.role not in ("agent", "admin"):
        raise HTTPException(status_code=403, detail="Forbidden")
    return {"id": row.id, "role": row.role, "name": row.name}


def contribution_out(row, customer_name: Optional[str] = None) -> dict:
    collected = row.collected_at
    if not isinstance(collected, str):
        collected = str(collected)
    return {
        "id": row.id,
        "customer_id": row.customer_id,
        "agent_id": row.agent_id,
        "amount": row.amount,
        "collected_at": collected,
        "sync_id": row.sync_id,
        "customer_name": customer_name,
    }


@app.post("/auth/login")
async def login(body: LoginIn, request: Request):
    user = await db_of(request).prepare("SELECT * FROM users WHERE phone = ?").bind(body.phone).first()
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid phone or password")
    token = create_token(user.id, user.role, secret_of(request))
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "name": user.name,
            "phone": user.phone,
            "role": user.role,
        },
    }


@app.post("/contributions/sync")
async def sync_contributions(
    body: SyncIn,
    request: Request,
    user: dict = Depends(require_agent_or_admin),
):
    db = db_of(request)
    now = utcnow()
    created: list[dict] = []
    statements = []
    seen_sync: dict[str, dict] = {}

    for item in body.items:
        cust = await db.prepare("SELECT * FROM customers WHERE id = ?").bind(item.customer_id).first()
        if cust is None:
            raise HTTPException(status_code=404, detail="Customer not found")
        if user["role"] == "agent" and cust.agent_id != user["id"]:
            raise HTTPException(status_code=403, detail="Not your customer")

        if item.sync_id:
            if item.sync_id in seen_sync:
                created.append(seen_sync[item.sync_id])
                continue
            existing = (
                await db.prepare("SELECT * FROM contributions WHERE sync_id = ?")
                .bind(item.sync_id)
                .first()
            )
            if existing is not None:
                out = contribution_out(existing, cust.name)
                seen_sync[item.sync_id] = out
                created.append(out)
                continue

        collected_at = item.collected_at or now
        if collected_at.tzinfo is None:
            collected_at = collected_at.replace(tzinfo=timezone.utc)
        business_date = collected_at.astimezone(timezone.utc).date().isoformat()

        day = (
            await db.prepare(
                "SELECT * FROM collection_days WHERE agent_id = ? AND business_date = ?"
            )
            .bind(cust.agent_id, business_date)
            .first()
        )
        if day is not None and day.status == "closed":
            raise HTTPException(
                status_code=400,
                detail="Day is closed; corrections require an adjustment entry",
            )

        row_id = str(uuid.uuid4())
        collected_iso = iso(collected_at)
        out = {
            "id": row_id,
            "customer_id": cust.id,
            "agent_id": cust.agent_id,
            "amount": item.amount,
            "collected_at": collected_iso,
            "sync_id": item.sync_id,
            "customer_name": cust.name,
        }
        if item.sync_id:
            seen_sync[item.sync_id] = out
        created.append(out)

        statements.append(
            db.prepare(
                """
                INSERT INTO contributions (
                    id, customer_id, agent_id, amount, collected_at, sync_id, business_date, locked
                ) VALUES (?, ?, ?, ?, ?, ?, ?, 0)
                """
            ).bind(
                row_id,
                cust.id,
                cust.agent_id,
                item.amount,
                collected_iso,
                item.sync_id,
                business_date,
            )
        )

        statements.append(
            db.prepare(
                """
                INSERT INTO audit_events (
                    id, actor_id, action, entity_type, entity_id, detail, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
                """
            ).bind(
                str(uuid.uuid4()),
                user["id"],
                "create",
                "contribution",
                row_id,
                str(item.amount),
                iso(now),
            )
        )

        statements.append(
            db.prepare(
                """
                INSERT INTO collection_days (
                    id, agent_id, business_date, declared_cash, system_total, status,
                    signed_off_at, signed_off_by
                ) VALUES (?, ?, ?, NULL, 0, 'open', NULL, NULL)
                ON CONFLICT(agent_id, business_date) DO NOTHING
                """
            ).bind(str(uuid.uuid4()), cust.agent_id, business_date)
        )
        statements.append(
            db.prepare(
                """
                UPDATE collection_days
                SET system_total = (
                    SELECT COALESCE(SUM(amount), 0) FROM contributions
                    WHERE agent_id = ? AND business_date = ?
                ),
                status = CASE
                    WHEN status = 'closed' THEN status
                    WHEN declared_cash IS NOT NULL AND declared_cash != (
                        SELECT COALESCE(SUM(amount), 0) FROM contributions
                        WHERE agent_id = ? AND business_date = ?
                    ) THEN 'mismatched'
                    ELSE 'open'
                END
                WHERE agent_id = ? AND business_date = ?
                """
            ).bind(
                cust.agent_id,
                business_date,
                cust.agent_id,
                business_date,
                cust.agent_id,
                business_date,
            )
        )

    if statements:
        await db.batch(statements)

    return {"created": created}


Default = asgi.entrypoint(app)
