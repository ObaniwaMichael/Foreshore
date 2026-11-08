"""Foreshore Holdings API — savings & loan operations."""

from __future__ import annotations

import os
import uuid
from datetime import date, datetime, timedelta, timezone
from enum import Enum
from typing import Annotated, Optional

from fastapi import Depends, FastAPI, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel, Field
from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    create_engine,
    func,
    select,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, relationship, sessionmaker

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

SECRET_KEY = os.getenv("FORESHORE_SECRET", "foreshore-dev-secret-change-me")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_HOURS = 72
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./foreshore.db")
LOAN_RATE = 0.20

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer(auto_error=False)

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


class Base(DeclarativeBase):
    pass


def new_id() -> str:
    return str(uuid.uuid4())


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def today_str() -> str:
    return date.today().isoformat()


# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------


class Role(str, Enum):
    agent = "agent"
    admin = "admin"
    management = "management"


class DayStatus(str, Enum):
    open = "open"
    mismatched = "mismatched"
    closed = "closed"


class LoanStatus(str, Enum):
    pending = "pending"
    active = "active"
    declined = "declined"
    repaid = "repaid"
    overdue = "overdue"


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    name: Mapped[str] = mapped_column(String(120))
    phone: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    role: Mapped[str] = mapped_column(String(32))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Customer(Base):
    __tablename__ = "customers"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    card_id: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(120))
    phone: Mapped[str] = mapped_column(String(32))
    address: Mapped[str] = mapped_column(Text, default="")
    agent_id: Mapped[str] = mapped_column(ForeignKey("users.id"))
    usual_daily_amount: Mapped[int] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class Contribution(Base):
    __tablename__ = "contributions"
    __table_args__ = (UniqueConstraint("sync_id", name="uq_sync_id"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    customer_id: Mapped[str] = mapped_column(ForeignKey("customers.id"), index=True)
    agent_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    amount: Mapped[int] = mapped_column(Integer)
    collected_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    sync_id: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    business_date: Mapped[str] = mapped_column(String(10), index=True)
    locked: Mapped[bool] = mapped_column(Boolean, default=False)


class CollectionDay(Base):
    __tablename__ = "collection_days"
    __table_args__ = (UniqueConstraint("agent_id", "business_date", name="uq_agent_day"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    agent_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    business_date: Mapped[str] = mapped_column(String(10), index=True)
    declared_cash: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    system_total: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(32), default=DayStatus.open.value)
    signed_off_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    signed_off_by: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)


class Withdrawal(Base):
    __tablename__ = "withdrawals"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    customer_id: Mapped[str] = mapped_column(ForeignKey("customers.id"), index=True)
    gross: Mapped[int] = mapped_column(Integer)
    charge: Mapped[int] = mapped_column(Integer)
    net: Mapped[int] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    created_by: Mapped[str] = mapped_column(ForeignKey("users.id"))


class Loan(Base):
    __tablename__ = "loans"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    customer_id: Mapped[str] = mapped_column(ForeignKey("customers.id"), index=True)
    principal: Mapped[int] = mapped_column(Integer)
    interest_rate: Mapped[float] = mapped_column(Float, default=LOAN_RATE)
    interest_amount: Mapped[int] = mapped_column(Integer)
    total_repayable: Mapped[int] = mapped_column(Integer)
    outstanding: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(32), default=LoanStatus.pending.value)
    requested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    disbursed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    due_date: Mapped[str] = mapped_column(String(10))
    decided_by: Mapped[Optional[str]] = mapped_column(String(36), nullable=True)


class LoanRepayment(Base):
    __tablename__ = "loan_repayments"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    loan_id: Mapped[str] = mapped_column(ForeignKey("loans.id"), index=True)
    amount: Mapped[int] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    created_by: Mapped[str] = mapped_column(ForeignKey("users.id"))


class AuditEvent(Base):
    __tablename__ = "audit_events"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_id)
    actor_id: Mapped[str] = mapped_column(String(36))
    action: Mapped[str] = mapped_column(String(64))
    entity_type: Mapped[str] = mapped_column(String(64))
    entity_id: Mapped[str] = mapped_column(String(36))
    detail: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------


class LoginIn(BaseModel):
    phone: str
    password: str


class CustomerIn(BaseModel):
    name: str
    phone: str
    address: str = ""
    usual_daily_amount: int = Field(gt=0)


class ContributionIn(BaseModel):
    customer_id: str
    amount: int = Field(gt=0)
    sync_id: Optional[str] = None
    collected_at: Optional[datetime] = None


class SyncIn(BaseModel):
    items: list[ContributionIn]


class DeclaredCashIn(BaseModel):
    declared_cash: Optional[int] = None


class DayPatch(BaseModel):
    declared_cash: int


class WithdrawalIn(BaseModel):
    customer_id: str
    amount: Optional[int] = None


class LoanIn(BaseModel):
    customer_id: str
    principal: int = Field(gt=0)


class LoanDecideIn(BaseModel):
    approve: bool


class RepayIn(BaseModel):
    amount: int = Field(gt=0)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    return pwd_context.verify(password, hashed)


def create_token(user: User) -> str:
    payload = {
        "sub": user.id,
        "role": user.role,
        "exp": utcnow() + timedelta(hours=ACCESS_TOKEN_EXPIRE_HOURS),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def audit(db: Session, actor_id: str, action: str, entity_type: str, entity_id: str, detail: str = ""):
    db.add(
        AuditEvent(
            id=new_id(),
            actor_id=actor_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            detail=detail,
        )
    )


def get_current_user(
    creds: Annotated[Optional[HTTPAuthorizationCredentials], Depends(security)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    if creds is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = jwt.decode(creds.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
    except JWTError as exc:
        raise HTTPException(status_code=401, detail="Invalid token") from exc
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user


def require_roles(*roles: str):
    def _dep(user: Annotated[User, Depends(get_current_user)]) -> User:
        if user.role not in roles:
            raise HTTPException(status_code=403, detail="Forbidden")
        return user

    return _dep


def savings_balance(db: Session, customer_id: str) -> int:
    contrib = db.scalar(
        select(func.coalesce(func.sum(Contribution.amount), 0)).where(
            Contribution.customer_id == customer_id
        )
    ) or 0
    withdrawn = db.scalar(
        select(func.coalesce(func.sum(Withdrawal.gross), 0)).where(
            Withdrawal.customer_id == customer_id
        )
    ) or 0
    return int(contrib) - int(withdrawn)


def tenure_days(db: Session, customer_id: str) -> int:
    first = db.scalar(
        select(func.min(Contribution.collected_at)).where(Contribution.customer_id == customer_id)
    )
    if not first:
        cust = db.get(Customer, customer_id)
        if not cust:
            return 0
        first = cust.created_at
    if first.tzinfo is None:
        first = first.replace(tzinfo=timezone.utc)
    return max(0, (utcnow() - first).days)


def daily_average(db: Session, customer_id: str) -> int:
    total = db.scalar(
        select(func.coalesce(func.sum(Contribution.amount), 0)).where(
            Contribution.customer_id == customer_id
        )
    ) or 0
    days = db.scalar(
        select(func.count(func.distinct(Contribution.business_date))).where(
            Contribution.customer_id == customer_id
        )
    ) or 0
    if days == 0:
        return 0
    return int(total) // int(days)


def customer_out(db: Session, c: Customer, business_date: Optional[str] = None) -> dict:
    bd = business_date or today_str()
    collected = (
        db.scalar(
            select(func.count()).where(
                Contribution.customer_id == c.id,
                Contribution.business_date == bd,
            )
        )
        or 0
    ) > 0
    return {
        "id": c.id,
        "card_id": c.card_id,
        "name": c.name,
        "phone": c.phone,
        "address": c.address,
        "agent_id": c.agent_id,
        "usual_daily_amount": c.usual_daily_amount,
        "savings_balance": savings_balance(db, c.id),
        "tenure_days": tenure_days(db, c.id),
        "collected_today": collected,
    }


def contribution_out(db: Session, row: Contribution) -> dict:
    cust = db.get(Customer, row.customer_id)
    return {
        "id": row.id,
        "customer_id": row.customer_id,
        "agent_id": row.agent_id,
        "amount": row.amount,
        "collected_at": row.collected_at.isoformat(),
        "sync_id": row.sync_id,
        "customer_name": cust.name if cust else None,
    }


def refresh_day_total(db: Session, day: CollectionDay) -> None:
    total = db.scalar(
        select(func.coalesce(func.sum(Contribution.amount), 0)).where(
            Contribution.agent_id == day.agent_id,
            Contribution.business_date == day.business_date,
        )
    ) or 0
    day.system_total = int(total)
    if day.status == DayStatus.closed.value:
        return
    if day.declared_cash is not None and day.declared_cash != day.system_total:
        day.status = DayStatus.mismatched.value
    else:
        day.status = DayStatus.open.value


def day_out(db: Session, day: CollectionDay) -> dict:
    agent = db.get(User, day.agent_id)
    refresh_day_total(db, day)
    return {
        "id": day.id,
        "agent_id": day.agent_id,
        "agent_name": agent.name if agent else "",
        "business_date": day.business_date,
        "system_total": day.system_total,
        "declared_cash": day.declared_cash,
        "status": day.status,
        "signed_off_at": day.signed_off_at.isoformat() if day.signed_off_at else None,
    }


def loan_out(db: Session, loan: Loan) -> dict:
    # Flag overdue
    if loan.status == LoanStatus.active.value and loan.due_date < today_str() and loan.outstanding > 0:
        loan.status = LoanStatus.overdue.value
    cust = db.get(Customer, loan.customer_id)
    return {
        "id": loan.id,
        "customer_id": loan.customer_id,
        "customer_name": cust.name if cust else "",
        "principal": loan.principal,
        "interest_rate": loan.interest_rate,
        "interest_amount": loan.interest_amount,
        "total_repayable": loan.total_repayable,
        "outstanding": loan.outstanding,
        "disbursed_at": loan.disbursed_at.isoformat() if loan.disbursed_at else None,
        "due_date": loan.due_date,
        "status": loan.status,
        "tenure_days": tenure_days(db, loan.customer_id),
        "daily_average": daily_average(db, loan.customer_id),
    }


def next_card_id(db: Session) -> str:
    count = db.scalar(select(func.count()).select_from(Customer)) or 0
    return f"FH-{(count + 1):05d}"


def ensure_day(db: Session, agent_id: str, business_date: Optional[str] = None) -> CollectionDay:
    bd = business_date or today_str()
    day = db.scalar(
        select(CollectionDay).where(
            CollectionDay.agent_id == agent_id,
            CollectionDay.business_date == bd,
        )
    )
    if not day:
        day = CollectionDay(
            id=new_id(),
            agent_id=agent_id,
            business_date=bd,
            system_total=0,
            status=DayStatus.open.value,
        )
        db.add(day)
        db.flush()
    return day


def assert_day_open(db: Session, agent_id: str, business_date: str) -> CollectionDay:
    day = ensure_day(db, agent_id, business_date)
    if day.status == DayStatus.closed.value:
        raise HTTPException(status_code=400, detail="Day is closed; corrections require an adjustment entry")
    return day


# ---------------------------------------------------------------------------
# App + seed
# ---------------------------------------------------------------------------

app = FastAPI(title="Foreshore Holdings API", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def seed_if_empty(db: Session) -> None:
    if db.scalar(select(func.count()).select_from(User)):
        return

    agent = User(
        id=new_id(),
        name="Tunde Adebayo",
        phone="08011110001",
        password_hash=hash_password("agent123"),
        role=Role.agent.value,
    )
    admin = User(
        id=new_id(),
        name="Ada Okonkwo",
        phone="08011110002",
        password_hash=hash_password("admin123"),
        role=Role.admin.value,
    )
    mgmt = User(
        id=new_id(),
        name="Bossman",
        phone="08011110003",
        password_hash=hash_password("mgmt123"),
        role=Role.management.value,
    )
    db.add_all([agent, admin, mgmt])
    db.flush()

    demo_customers = [
        ("Chioma Nwosu", "08020010001", "12 Market Road", 1000),
        ("Ibrahim Musa", "08020010002", "45 Bode Thomas", 2000),
        ("Funke Adeyemi", "08020010003", "8 Marina Close", 1500),
        ("Emeka Obi", "08020010004", "3 Aba Street", 1000),
        ("Aisha Bello", "08020010005", "19 Ikeja Way", 500),
        ("Yusuf Garba", "08020010006", "7 Sabo Lane", 1000),
        ("Ngozi Eze", "08020010007", "22 Enugu Road", 2500),
        ("Segun Bakare", "08020010008", "5 Surulere Ave", 1000),
    ]
    customers: list[Customer] = []
    for i, (name, phone, address, amt) in enumerate(demo_customers, start=1):
        c = Customer(
            id=new_id(),
            card_id=f"FH-{i:05d}",
            name=name,
            phone=phone,
            address=address,
            agent_id=agent.id,
            usual_daily_amount=amt,
        )
        customers.append(c)
        db.add(c)
    db.flush()

    # Seed historical contributions for tenure / balance (last 14 days, skip today)
    for offset in range(14, 0, -1):
        d = date.today() - timedelta(days=offset)
        if d.weekday() >= 6:  # skip Sundays lightly
            continue
        bd = d.isoformat()
        for c in customers:
            # ~80% attendance
            if (hash(c.id + bd) % 10) < 2:
                continue
            db.add(
                Contribution(
                    id=new_id(),
                    customer_id=c.id,
                    agent_id=agent.id,
                    amount=c.usual_daily_amount,
                    collected_at=datetime(d.year, d.month, d.day, 10, 0, tzinfo=timezone.utc),
                    business_date=bd,
                    locked=True,
                )
            )

    # One pending loan request for demo
    sample = customers[0]
    interest = int(round(300_000 * LOAN_RATE))
    db.add(
        Loan(
            id=new_id(),
            customer_id=sample.id,
            principal=300_000,
            interest_rate=LOAN_RATE,
            interest_amount=interest,
            total_repayable=300_000 + interest,
            outstanding=300_000 + interest,
            status=LoanStatus.pending.value,
            due_date=(date.today() + timedelta(days=30)).isoformat(),
        )
    )
    db.commit()


@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed_if_empty(db)
    finally:
        db.close()


@app.get("/health")
def health():
    return {"ok": True, "service": "foreshore-api"}


@app.post("/auth/login")
def login(body: LoginIn, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.phone == body.phone))
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid phone or password")
    token = create_token(user)
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


@app.get("/customers")
def list_customers(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    q = select(Customer)
    if user.role == Role.agent.value:
        q = q.where(Customer.agent_id == user.id)
    rows = db.scalars(q.order_by(Customer.name)).all()
    return [customer_out(db, c) for c in rows]


@app.post("/customers")
def create_customer(
    body: CustomerIn,
    user: User = Depends(require_roles(Role.agent.value, Role.admin.value)),
    db: Session = Depends(get_db),
):
    agent_id = user.id if user.role == Role.agent.value else user.id
    if user.role == Role.admin.value:
        # Admin onboarding assigns to first agent for MVP simplicity if needed —
        # prefer creating as agent. Use current user when agent.
        agent = db.scalar(select(User).where(User.role == Role.agent.value))
        agent_id = agent.id if agent else user.id
    if user.role == Role.agent.value:
        agent_id = user.id

    c = Customer(
        id=new_id(),
        card_id=next_card_id(db),
        name=body.name,
        phone=body.phone,
        address=body.address,
        agent_id=agent_id,
        usual_daily_amount=body.usual_daily_amount,
    )
    db.add(c)
    audit(db, user.id, "create", "customer", c.id, c.name)
    db.commit()
    db.refresh(c)
    return customer_out(db, c)


@app.get("/agent/route")
def agent_route(
    agent_id: Optional[str] = None,
    date: Optional[str] = None,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    aid = agent_id or user.id
    if user.role == Role.agent.value:
        aid = user.id
    bd = date or today_str()
    ensure_day(db, aid, bd)
    db.commit()
    rows = db.scalars(select(Customer).where(Customer.agent_id == aid).order_by(Customer.name)).all()
    return [customer_out(db, c, bd) for c in rows]


def _create_contribution(db: Session, user: User, body: ContributionIn) -> Contribution:
    cust = db.get(Customer, body.customer_id)
    if not cust:
        raise HTTPException(status_code=404, detail="Customer not found")
    if user.role == Role.agent.value and cust.agent_id != user.id:
        raise HTTPException(status_code=403, detail="Not your customer")

    collected_at = body.collected_at or utcnow()
    if collected_at.tzinfo is None:
        collected_at = collected_at.replace(tzinfo=timezone.utc)
    business_date = collected_at.astimezone(timezone.utc).date().isoformat()

    if body.sync_id:
        existing = db.scalar(select(Contribution).where(Contribution.sync_id == body.sync_id))
        if existing:
            return existing

    assert_day_open(db, cust.agent_id, business_date)

    row = Contribution(
        id=new_id(),
        customer_id=cust.id,
        agent_id=cust.agent_id,
        amount=body.amount,
        collected_at=collected_at,
        sync_id=body.sync_id,
        business_date=business_date,
    )
    db.add(row)
    audit(db, user.id, "create", "contribution", row.id, f"{body.amount}")
    db.flush()
    day = ensure_day(db, cust.agent_id, business_date)
    refresh_day_total(db, day)
    return row


@app.post("/contributions")
def log_contribution(
    body: ContributionIn,
    user: User = Depends(require_roles(Role.agent.value, Role.admin.value)),
    db: Session = Depends(get_db),
):
    row = _create_contribution(db, user, body)
    db.commit()
    db.refresh(row)
    return contribution_out(db, row)


@app.post("/contributions/sync")
def sync_contributions(
    body: SyncIn,
    user: User = Depends(require_roles(Role.agent.value, Role.admin.value)),
    db: Session = Depends(get_db),
):
    created = []
    for item in body.items:
        row = _create_contribution(db, user, item)
        created.append(contribution_out(db, row))
    db.commit()
    return {"created": created}


@app.get("/contributions")
def list_contributions(
    customer_id: Optional[str] = None,
    agent_id: Optional[str] = None,
    date: Optional[str] = None,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    q = select(Contribution)
    if customer_id:
        q = q.where(Contribution.customer_id == customer_id)
    if agent_id:
        q = q.where(Contribution.agent_id == agent_id)
    if user.role == Role.agent.value:
        q = q.where(Contribution.agent_id == user.id)
    if date:
        q = q.where(Contribution.business_date == date)
    rows = db.scalars(q.order_by(Contribution.collected_at.desc()).limit(200)).all()
    return [contribution_out(db, r) for r in rows]


@app.post("/collection-days/today")
def collection_day_today(
    body: DeclaredCashIn,
    user: User = Depends(require_roles(Role.agent.value, Role.admin.value)),
    db: Session = Depends(get_db),
):
    agent_id = user.id if user.role == Role.agent.value else user.id
    if user.role != Role.agent.value:
        agent = db.scalar(select(User).where(User.role == Role.agent.value))
        agent_id = agent.id if agent else user.id
    else:
        agent_id = user.id
    day = ensure_day(db, agent_id)
    if body.declared_cash is not None and day.status != DayStatus.closed.value:
        day.declared_cash = body.declared_cash
        refresh_day_total(db, day)
    else:
        refresh_day_total(db, day)
    db.commit()
    db.refresh(day)
    return day_out(db, day)


@app.get("/collection-days")
def list_days(
    date: Optional[str] = None,
    user: User = Depends(require_roles(Role.admin.value, Role.management.value)),
    db: Session = Depends(get_db),
):
    bd = date or today_str()
    # Ensure days exist for all agents
    agents = db.scalars(select(User).where(User.role == Role.agent.value)).all()
    for a in agents:
        ensure_day(db, a.id, bd)
    db.commit()
    rows = db.scalars(
        select(CollectionDay).where(CollectionDay.business_date == bd)
    ).all()
    return [day_out(db, d) for d in rows]


@app.patch("/collection-days/{day_id}")
def patch_day(
    day_id: str,
    body: DayPatch,
    user: User = Depends(require_roles(Role.admin.value, Role.agent.value)),
    db: Session = Depends(get_db),
):
    day = db.get(CollectionDay, day_id)
    if not day:
        raise HTTPException(status_code=404, detail="Day not found")
    if day.status == DayStatus.closed.value:
        raise HTTPException(status_code=400, detail="Day is locked")
    if user.role == Role.agent.value and day.agent_id != user.id:
        raise HTTPException(status_code=403, detail="Forbidden")
    day.declared_cash = body.declared_cash
    refresh_day_total(db, day)
    audit(db, user.id, "declare_cash", "collection_day", day.id, str(body.declared_cash))
    db.commit()
    db.refresh(day)
    return day_out(db, day)


@app.post("/collection-days/{day_id}/signoff")
def signoff_day(
    day_id: str,
    user: User = Depends(require_roles(Role.admin.value)),
    db: Session = Depends(get_db),
):
    day = db.get(CollectionDay, day_id)
    if not day:
        raise HTTPException(status_code=404, detail="Day not found")
    if day.status == DayStatus.closed.value:
        raise HTTPException(status_code=400, detail="Already closed")
    refresh_day_total(db, day)
    if day.declared_cash is None:
        raise HTTPException(status_code=400, detail="Declared cash required")
    if day.declared_cash != day.system_total:
        day.status = DayStatus.mismatched.value
        db.commit()
        raise HTTPException(
            status_code=400,
            detail=f"Mismatch: declared {day.declared_cash} vs system {day.system_total}",
        )
    day.status = DayStatus.closed.value
    day.signed_off_at = utcnow()
    day.signed_off_by = user.id
    # Lock contributions
    rows = db.scalars(
        select(Contribution).where(
            Contribution.agent_id == day.agent_id,
            Contribution.business_date == day.business_date,
        )
    ).all()
    for r in rows:
        r.locked = True
    audit(db, user.id, "signoff", "collection_day", day.id, day.business_date)
    db.commit()
    db.refresh(day)
    return day_out(db, day)


@app.get("/withdrawals/preview")
def preview_withdrawal(
    customer_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    cust = db.get(Customer, customer_id)
    if not cust:
        raise HTTPException(status_code=404, detail="Customer not found")
    gross = savings_balance(db, customer_id)
    charge = cust.usual_daily_amount
    net = max(0, gross - charge)
    return {
        "customer_id": customer_id,
        "gross": gross,
        "charge": charge,
        "net": net,
        "usual_daily_amount": cust.usual_daily_amount,
    }


@app.post("/withdrawals")
def create_withdrawal(
    body: WithdrawalIn,
    user: User = Depends(require_roles(Role.admin.value, Role.management.value)),
    db: Session = Depends(get_db),
):
    cust = db.get(Customer, body.customer_id)
    if not cust:
        raise HTTPException(status_code=404, detail="Customer not found")
    gross = savings_balance(db, body.customer_id)
    if body.amount is not None:
        if body.amount > gross:
            raise HTTPException(status_code=400, detail="Amount exceeds balance")
        gross = body.amount
    if gross <= 0:
        raise HTTPException(status_code=400, detail="Nothing to withdraw")
    charge = cust.usual_daily_amount
    net = max(0, gross - charge)
    w = Withdrawal(
        id=new_id(),
        customer_id=cust.id,
        gross=gross,
        charge=charge,
        net=net,
        created_by=user.id,
    )
    db.add(w)
    audit(db, user.id, "withdraw", "withdrawal", w.id, f"net={net}")
    db.commit()
    db.refresh(w)
    return {
        "id": w.id,
        "customer_id": w.customer_id,
        "gross": w.gross,
        "charge": w.charge,
        "net": w.net,
        "created_at": w.created_at.isoformat(),
    }


@app.get("/loans")
def list_loans(
    status: Optional[str] = None,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    q = select(Loan)
    if status:
        q = q.where(Loan.status == status)
    rows = db.scalars(q.order_by(Loan.requested_at.desc())).all()
    return [loan_out(db, r) for r in rows]


@app.post("/loans")
def request_loan(
    body: LoanIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    cust = db.get(Customer, body.customer_id)
    if not cust:
        raise HTTPException(status_code=404, detail="Customer not found")
    interest = int(round(body.principal * LOAN_RATE))
    total = body.principal + interest
    loan = Loan(
        id=new_id(),
        customer_id=cust.id,
        principal=body.principal,
        interest_rate=LOAN_RATE,
        interest_amount=interest,
        total_repayable=total,
        outstanding=total,
        status=LoanStatus.pending.value,
        due_date=(date.today() + timedelta(days=30)).isoformat(),
    )
    db.add(loan)
    audit(db, user.id, "request", "loan", loan.id, str(body.principal))
    db.commit()
    db.refresh(loan)
    return loan_out(db, loan)


@app.post("/loans/{loan_id}/decide")
def decide_loan(
    loan_id: str,
    body: LoanDecideIn,
    user: User = Depends(require_roles(Role.admin.value, Role.management.value)),
    db: Session = Depends(get_db),
):
    loan = db.get(Loan, loan_id)
    if not loan:
        raise HTTPException(status_code=404, detail="Loan not found")
    if loan.status != LoanStatus.pending.value:
        raise HTTPException(status_code=400, detail="Loan already decided")
    if body.approve:
        loan.status = LoanStatus.active.value
        loan.disbursed_at = utcnow()
        loan.decided_by = user.id
        audit(db, user.id, "approve", "loan", loan.id, "")
    else:
        loan.status = LoanStatus.declined.value
        loan.outstanding = 0
        loan.decided_by = user.id
        audit(db, user.id, "decline", "loan", loan.id, "")
    db.commit()
    db.refresh(loan)
    return loan_out(db, loan)


@app.post("/loans/{loan_id}/repay")
def repay_loan(
    loan_id: str,
    body: RepayIn,
    user: User = Depends(require_roles(Role.admin.value, Role.management.value)),
    db: Session = Depends(get_db),
):
    loan = db.get(Loan, loan_id)
    if not loan:
        raise HTTPException(status_code=404, detail="Loan not found")
    if loan.status not in (LoanStatus.active.value, LoanStatus.overdue.value):
        raise HTTPException(status_code=400, detail="Loan not active")
    amount = min(body.amount, loan.outstanding)
    loan.outstanding -= amount
    db.add(
        LoanRepayment(
            id=new_id(),
            loan_id=loan.id,
            amount=amount,
            created_by=user.id,
        )
    )
    if loan.outstanding == 0:
        loan.status = LoanStatus.repaid.value
    audit(db, user.id, "repay", "loan", loan.id, str(amount))
    db.commit()
    db.refresh(loan)
    return loan_out(db, loan)


@app.get("/reports/summary")
def report_summary(
    user: User = Depends(require_roles(Role.admin.value, Role.management.value)),
    db: Session = Depends(get_db),
):
    customers = db.scalars(select(Customer)).all()
    total_savings = sum(savings_balance(db, c.id) for c in customers)
    loans_out = db.scalar(
        select(func.coalesce(func.sum(Loan.outstanding), 0)).where(
            Loan.status.in_([LoanStatus.active.value, LoanStatus.overdue.value])
        )
    ) or 0
    interest = db.scalar(
        select(func.coalesce(func.sum(Loan.interest_amount), 0)).where(
            Loan.status.in_(
                [LoanStatus.active.value, LoanStatus.overdue.value, LoanStatus.repaid.value]
            )
        )
    ) or 0
    today = db.scalar(
        select(func.coalesce(func.sum(Contribution.amount), 0)).where(
            Contribution.business_date == today_str()
        )
    ) or 0
    return {
        "total_savings": int(total_savings),
        "total_loans_outstanding": int(loans_out),
        "total_interest_earned": int(interest),
        "today_collections": int(today),
    }


@app.get("/reports/customer/{customer_id}")
def customer_statement(
    customer_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    cust = db.get(Customer, customer_id)
    if not cust:
        raise HTTPException(status_code=404, detail="Customer not found")
    contribs = db.scalars(
        select(Contribution)
        .where(Contribution.customer_id == customer_id)
        .order_by(Contribution.collected_at.desc())
    ).all()
    withdrawals = db.scalars(
        select(Withdrawal)
        .where(Withdrawal.customer_id == customer_id)
        .order_by(Withdrawal.created_at.desc())
    ).all()
    loans = db.scalars(select(Loan).where(Loan.customer_id == customer_id)).all()
    return {
        "customer": customer_out(db, cust),
        "contributions": [contribution_out(db, c) for c in contribs],
        "withdrawals": [
            {
                "id": w.id,
                "customer_id": w.customer_id,
                "gross": w.gross,
                "charge": w.charge,
                "net": w.net,
                "created_at": w.created_at.isoformat(),
            }
            for w in withdrawals
        ],
        "loans": [loan_out(db, l) for l in loans],
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
