const { Pool } = require('pg');
require('dotenv').config({ path: '../.env' });

/**
 * Database migration script
 * Creates all required tables for FlowNote application
 */
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || 'flownote_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

const createTables = async () => {
  const client = await pool.connect();
  
  try {
    console.log('🚀 Starting database migration...');
    
    await client.query('BEGIN');

    // ── Users Table ──────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id          SERIAL PRIMARY KEY,
        name        VARCHAR(100) NOT NULL,
        email       VARCHAR(150) UNIQUE NOT NULL,
        password    VARCHAR(255) NOT NULL,
        avatar_url  VARCHAR(500),
        created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);
    console.log('✅ Table: users');

    // ── Categories Table ──────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS categories (
        id         SERIAL PRIMARY KEY,
        name       VARCHAR(100) NOT NULL,
        icon       VARCHAR(50) NOT NULL DEFAULT 'category',
        color      VARCHAR(20) NOT NULL DEFAULT '#6366F1',
        type       VARCHAR(10) CHECK (type IN ('income', 'expense', 'both')) DEFAULT 'both',
        is_default BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);
    console.log('✅ Table: categories');

    // ── Transactions Table ────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS transactions (
        id          SERIAL PRIMARY KEY,
        user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title       VARCHAR(200) NOT NULL,
        amount      DECIMAL(15, 2) NOT NULL CHECK (amount > 0),
        type        VARCHAR(10) NOT NULL CHECK (type IN ('income', 'expense')),
        category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
        date        DATE NOT NULL DEFAULT CURRENT_DATE,
        note        TEXT,
        created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);
    console.log('✅ Table: transactions');

    // ── Notes Table ───────────────────────────────────────────────────────
    await client.query(`
      CREATE TABLE IF NOT EXISTS notes (
        id           SERIAL PRIMARY KEY,
        user_id      INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title        VARCHAR(300) NOT NULL,
        content      TEXT,
        is_task      BOOLEAN DEFAULT FALSE,
        is_completed BOOLEAN DEFAULT FALSE,
        color        VARCHAR(20) DEFAULT '#FFFFFF',
        created_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);
    console.log('✅ Table: notes');

    // ── Indexes for performance ───────────────────────────────────────────
    await client.query(`CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_notes_is_task ON notes(is_task);`);
    console.log('✅ Indexes created');

    await client.query('COMMIT');
    console.log('\n🎉 Migration completed successfully!');
    
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', err.message);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
};

createTables().catch((err) => {
  console.error(err);
  process.exit(1);
});
