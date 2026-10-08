-- Initial schema for the appdb database
-- Three tables that will be populated and then partially lost via WAL corruption

CREATE TABLE IF NOT EXISTS orders (
    id          SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    amount      NUMERIC(10, 2) NOT NULL,
    status      VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ledger (
    id          SERIAL PRIMARY KEY,
    order_id    INTEGER REFERENCES orders(id),
    debit       NUMERIC(10, 2) DEFAULT 0,
    credit      NUMERIC(10, 2) DEFAULT 0,
    balance     NUMERIC(10, 2) NOT NULL,
    posted_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS events (
    id          SERIAL PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,
    entity_id   INTEGER NOT NULL,
    event_type  VARCHAR(50) NOT NULL,
    payload     JSONB,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
