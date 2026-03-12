const { Pool } = require('pg');
require('dotenv').config({ path: '../.env' });

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || 'flownote_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
});

/**
 * Default categories seed data
 * Provides a rich set of finance categories out of the box
 */
const defaultCategories = [
  // Income categories
  { name: 'Salary',      icon: 'work',           color: '#10B981', type: 'income' },
  { name: 'Freelance',   icon: 'laptop',         color: '#6366F1', type: 'income' },
  { name: 'Investment',  icon: 'trending_up',    color: '#F59E0B', type: 'income' },
  { name: 'Gift',        icon: 'card_giftcard',  color: '#EC4899', type: 'income' },
  { name: 'Other Income',icon: 'attach_money',   color: '#14B8A6', type: 'income' },
  
  // Expense categories
  { name: 'Food',        icon: 'restaurant',     color: '#EF4444', type: 'expense' },
  { name: 'Transport',   icon: 'directions_car', color: '#3B82F6', type: 'expense' },
  { name: 'Shopping',    icon: 'shopping_bag',   color: '#8B5CF6', type: 'expense' },
  { name: 'Bills',       icon: 'receipt',        color: '#F97316', type: 'expense' },
  { name: 'Healthcare',  icon: 'local_hospital', color: '#06B6D4', type: 'expense' },
  { name: 'Education',   icon: 'school',         color: '#84CC16', type: 'expense' },
  { name: 'Entertainment',icon:'movie',          color: '#A855F7', type: 'expense' },
  { name: 'Rent',        icon: 'home',           color: '#64748B', type: 'expense' },
  { name: 'Savings',     icon: 'savings',        color: '#0EA5E9', type: 'expense' },
  { name: 'Other',       icon: 'more_horiz',     color: '#6B7280', type: 'both' },
];

const seed = async () => {
  const client = await pool.connect();
  try {
    console.log('🌱 Seeding default categories...');
    
    for (const cat of defaultCategories) {
      await client.query(
        `INSERT INTO categories (name, icon, color, type, is_default)
         VALUES ($1, $2, $3, $4, TRUE)
         ON CONFLICT DO NOTHING`,
        [cat.name, cat.icon, cat.color, cat.type]
      );
    }
    
    console.log(`✅ Seeded ${defaultCategories.length} categories`);
    console.log('\n🎉 Seed completed!');
  } catch (err) {
    console.error('❌ Seed failed:', err.message);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
};

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
