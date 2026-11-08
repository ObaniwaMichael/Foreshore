-- Existing SQLAlchemy/SQLite schema, applied as a D1 migration.
-- Column types match backend/main.py models (VARCHAR/DATETIME/BOOLEAN/FLOAT).

CREATE TABLE users (
	id VARCHAR(36) NOT NULL,
	name VARCHAR(120) NOT NULL,
	phone VARCHAR(32) NOT NULL,
	password_hash VARCHAR(255) NOT NULL,
	role VARCHAR(32) NOT NULL,
	created_at DATETIME NOT NULL,
	PRIMARY KEY (id)
);

CREATE UNIQUE INDEX ix_users_phone ON users (phone);

CREATE TABLE customers (
	id VARCHAR(36) NOT NULL,
	card_id VARCHAR(32) NOT NULL,
	name VARCHAR(120) NOT NULL,
	phone VARCHAR(32) NOT NULL,
	address TEXT NOT NULL,
	agent_id VARCHAR(36) NOT NULL,
	usual_daily_amount INTEGER NOT NULL,
	created_at DATETIME NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(agent_id) REFERENCES users (id)
);

CREATE UNIQUE INDEX ix_customers_card_id ON customers (card_id);

CREATE TABLE contributions (
	id VARCHAR(36) NOT NULL,
	customer_id VARCHAR(36) NOT NULL,
	agent_id VARCHAR(36) NOT NULL,
	amount INTEGER NOT NULL,
	collected_at DATETIME NOT NULL,
	sync_id VARCHAR(64),
	business_date VARCHAR(10) NOT NULL,
	locked BOOLEAN NOT NULL,
	PRIMARY KEY (id),
	CONSTRAINT uq_sync_id UNIQUE (sync_id),
	FOREIGN KEY(customer_id) REFERENCES customers (id),
	FOREIGN KEY(agent_id) REFERENCES users (id)
);

CREATE INDEX ix_contributions_agent_id ON contributions (agent_id);
CREATE INDEX ix_contributions_business_date ON contributions (business_date);
CREATE INDEX ix_contributions_customer_id ON contributions (customer_id);

CREATE TABLE collection_days (
	id VARCHAR(36) NOT NULL,
	agent_id VARCHAR(36) NOT NULL,
	business_date VARCHAR(10) NOT NULL,
	declared_cash INTEGER,
	system_total INTEGER NOT NULL,
	status VARCHAR(32) NOT NULL,
	signed_off_at DATETIME,
	signed_off_by VARCHAR(36),
	PRIMARY KEY (id),
	CONSTRAINT uq_agent_day UNIQUE (agent_id, business_date),
	FOREIGN KEY(agent_id) REFERENCES users (id)
);

CREATE INDEX ix_collection_days_agent_id ON collection_days (agent_id);
CREATE INDEX ix_collection_days_business_date ON collection_days (business_date);

CREATE TABLE withdrawals (
	id VARCHAR(36) NOT NULL,
	customer_id VARCHAR(36) NOT NULL,
	gross INTEGER NOT NULL,
	charge INTEGER NOT NULL,
	net INTEGER NOT NULL,
	created_at DATETIME NOT NULL,
	created_by VARCHAR(36) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(customer_id) REFERENCES customers (id),
	FOREIGN KEY(created_by) REFERENCES users (id)
);

CREATE INDEX ix_withdrawals_customer_id ON withdrawals (customer_id);

CREATE TABLE loans (
	id VARCHAR(36) NOT NULL,
	customer_id VARCHAR(36) NOT NULL,
	principal INTEGER NOT NULL,
	interest_rate FLOAT NOT NULL,
	interest_amount INTEGER NOT NULL,
	total_repayable INTEGER NOT NULL,
	outstanding INTEGER NOT NULL,
	status VARCHAR(32) NOT NULL,
	requested_at DATETIME NOT NULL,
	disbursed_at DATETIME,
	due_date VARCHAR(10) NOT NULL,
	decided_by VARCHAR(36),
	PRIMARY KEY (id),
	FOREIGN KEY(customer_id) REFERENCES customers (id)
);

CREATE INDEX ix_loans_customer_id ON loans (customer_id);

CREATE TABLE loan_repayments (
	id VARCHAR(36) NOT NULL,
	loan_id VARCHAR(36) NOT NULL,
	amount INTEGER NOT NULL,
	created_at DATETIME NOT NULL,
	created_by VARCHAR(36) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY(loan_id) REFERENCES loans (id),
	FOREIGN KEY(created_by) REFERENCES users (id)
);

CREATE INDEX ix_loan_repayments_loan_id ON loan_repayments (loan_id);

CREATE TABLE audit_events (
	id VARCHAR(36) NOT NULL,
	actor_id VARCHAR(36) NOT NULL,
	action VARCHAR(64) NOT NULL,
	entity_type VARCHAR(64) NOT NULL,
	entity_id VARCHAR(36) NOT NULL,
	detail TEXT NOT NULL,
	created_at DATETIME NOT NULL,
	PRIMARY KEY (id)
);
