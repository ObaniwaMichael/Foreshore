-- Demo logins from README (Worker D1 has no FastAPI startup seed).
INSERT OR IGNORE INTO users (id, name, phone, password_hash, role, created_at) VALUES
(
  'agent-seed-1',
  'Tunde Adebayo',
  '08011110001',
  '$2b$12$Y7jkwZF7DdHiYerH8F4plustU61VCro0iHJFhHl37YC71Yv8ktcve',
  'agent',
  '2026-01-01T00:00:00+00:00'
),
(
  'admin-seed-1',
  'Ada Okonkwo',
  '08011110002',
  '$2b$12$Zyrgwt7s.hGwedlYCvCkRuSuTu0KsMBZj/AdNns2y6e2AVZZyX8ha',
  'admin',
  '2026-01-01T00:00:00+00:00'
),
(
  'mgmt-seed-1',
  'Bossman',
  '08011110003',
  '$2b$12$PeazroCmuHLIFXwK5jx8s.CFAA/ph3/e0Qy2mjngmZteHvxUj8WeS',
  'management',
  '2026-01-01T00:00:00+00:00'
);

INSERT OR IGNORE INTO customers (
  id, card_id, name, phone, address, agent_id, usual_daily_amount, created_at
) VALUES (
  'cust-chioma',
  'FH-00001',
  'Chioma Nwosu',
  '08020010001',
  '12 Market Road',
  'agent-seed-1',
  1000,
  '2026-01-01T00:00:00+00:00'
);
