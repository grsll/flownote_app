const pool = require('../config/database');

/**
 * GET /api/transactions
 * Fetch all transactions for authenticated user
 * Supports: ?type=income|expense, ?category_id=N, ?start=YYYY-MM-DD, ?end=YYYY-MM-DD, ?limit=N, ?page=N
 */
const getTransactions = async (req, res) => {
  const userId = req.user.id;
  const { type, category_id, start, end, limit = 50, page = 1 } = req.query;

  try {
    let conditions = ['t.user_id = $1'];
    let params = [userId];
    let idx = 2;

    if (type) {
      conditions.push(`t.type = $${idx++}`);
      params.push(type);
    }
    if (category_id) {
      conditions.push(`t.category_id = $${idx++}`);
      params.push(parseInt(category_id));
    }
    if (start) {
      conditions.push(`t.date >= $${idx++}`);
      params.push(start);
    }
    if (end) {
      conditions.push(`t.date <= $${idx++}`);
      params.push(end);
    }

    const offset = (parseInt(page) - 1) * parseInt(limit);
    
    const query = `
      SELECT 
        t.id, t.title, t.amount, t.type, t.date, t.note, t.created_at,
        c.id AS category_id, c.name AS category_name, c.icon AS category_icon, c.color AS category_color
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE ${conditions.join(' AND ')}
      ORDER BY t.date DESC, t.created_at DESC
      LIMIT $${idx++} OFFSET $${idx}
    `;
    params.push(parseInt(limit), offset);

    // Get total count for pagination
    const countQuery = `
      SELECT COUNT(*) FROM transactions t
      WHERE ${conditions.join(' AND ')}
    `;
    const [dataResult, countResult] = await Promise.all([
      pool.query(query, params),
      pool.query(countQuery, params.slice(0, -2)),
    ]);

    const total = parseInt(countResult.rows[0].count);

    return res.status(200).json({
      success: true,
      data: dataResult.rows,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / parseInt(limit)),
      },
    });
  } catch (err) {
    console.error('Get transactions error:', err);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

/**
 * POST /api/transactions
 * Create a new transaction
 */
const createTransaction = async (req, res) => {
  const { title, amount, type, category_id, date, note } = req.body;
  const userId = req.user.id;

  try {
    const result = await pool.query(
      `INSERT INTO transactions (user_id, title, amount, type, category_id, date, note)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [userId, title, parseFloat(amount), type, category_id || null, date || new Date().toISOString().split('T')[0], note || null]
    );

    // Fetch with category details
    const transaction = await pool.query(
      `SELECT t.*, c.name AS category_name, c.icon AS category_icon, c.color AS category_color
       FROM transactions t
       LEFT JOIN categories c ON t.category_id = c.id
       WHERE t.id = $1`,
      [result.rows[0].id]
    );

    return res.status(201).json({
      success: true,
      message: 'Transaction created successfully.',
      data: transaction.rows[0],
    });
  } catch (err) {
    console.error('Create transaction error:', err);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

/**
 * PUT /api/transactions/:id
 * Update an existing transaction (only by owner)
 */
const updateTransaction = async (req, res) => {
  const { id } = req.params;
  const { title, amount, type, category_id, date, note } = req.body;
  const userId = req.user.id;

  try {
    // Verify ownership
    const owned = await pool.query(
      'SELECT id FROM transactions WHERE id = $1 AND user_id = $2',
      [id, userId]
    );
    if (owned.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Transaction not found.' });
    }

    const result = await pool.query(
      `UPDATE transactions
       SET title = $1, amount = $2, type = $3, category_id = $4, date = $5, note = $6, updated_at = NOW()
       WHERE id = $7 AND user_id = $8
       RETURNING *`,
      [title, parseFloat(amount), type, category_id || null, date, note || null, id, userId]
    );

    return res.status(200).json({
      success: true,
      message: 'Transaction updated successfully.',
      data: result.rows[0],
    });
  } catch (err) {
    console.error('Update transaction error:', err);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

/**
 * DELETE /api/transactions/:id
 * Delete a transaction (only by owner)
 */
const deleteTransaction = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  try {
    const result = await pool.query(
      'DELETE FROM transactions WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Transaction not found.' });
    }

    return res.status(200).json({ success: true, message: 'Transaction deleted successfully.' });
  } catch (err) {
    console.error('Delete transaction error:', err);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

/**
 * GET /api/transactions/summary
 * Monthly balance summary + category breakdown
 */
const getSummary = async (req, res) => {
  const userId = req.user.id;
  const { month, year } = req.query;
  
  const currentDate = new Date();
  const targetMonth = month || (currentDate.getMonth() + 1);
  const targetYear = year || currentDate.getFullYear();

  try {
    // Monthly totals
    const totalsResult = await pool.query(
      `SELECT 
         type,
         SUM(amount) AS total
       FROM transactions
       WHERE user_id = $1
         AND EXTRACT(MONTH FROM date) = $2
         AND EXTRACT(YEAR FROM date) = $3
       GROUP BY type`,
      [userId, targetMonth, targetYear]
    );

    // Category breakdown
    const categoryResult = await pool.query(
      `SELECT 
         c.name AS category, c.color, c.icon,
         t.type,
         SUM(t.amount) AS total,
         COUNT(*) AS count
       FROM transactions t
       LEFT JOIN categories c ON t.category_id = c.id
       WHERE t.user_id = $1
         AND EXTRACT(MONTH FROM t.date) = $2
         AND EXTRACT(YEAR FROM t.date) = $3
       GROUP BY c.name, c.color, c.icon, t.type
       ORDER BY total DESC`,
      [userId, targetMonth, targetYear]
    );

    // All-time balance
    const balanceResult = await pool.query(
      `SELECT 
         SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) -
         SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS balance,
         SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) AS total_income,
         SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS total_expense
       FROM transactions WHERE user_id = $1`,
      [userId]
    );

    let income = 0, expense = 0;
    totalsResult.rows.forEach((row) => {
      if (row.type === 'income') income = parseFloat(row.total);
      if (row.type === 'expense') expense = parseFloat(row.total);
    });

    return res.status(200).json({
      success: true,
      data: {
        month: parseInt(targetMonth),
        year: parseInt(targetYear),
        monthly: { income, expense, balance: income - expense },
        allTime: balanceResult.rows[0],
        categoryBreakdown: categoryResult.rows,
      },
    });
  } catch (err) {
    console.error('Get summary error:', err);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

/**
 * GET /api/transactions/monthly-chart
 * Last 6 months data for line chart
 */
const getMonthlyChart = async (req, res) => {
  const userId = req.user.id;

  try {
    const result = await pool.query(
      `SELECT 
         EXTRACT(YEAR FROM date) AS year,
         EXTRACT(MONTH FROM date) AS month,
         type,
         SUM(amount) AS total
       FROM transactions
       WHERE user_id = $1
         AND date >= NOW() - INTERVAL '6 months'
       GROUP BY year, month, type
       ORDER BY year, month`,
      [userId]
    );

    return res.status(200).json({ success: true, data: result.rows });
  } catch (err) {
    console.error('Monthly chart error:', err);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

module.exports = {
  getTransactions,
  createTransaction,
  updateTransaction,
  deleteTransaction,
  getSummary,
  getMonthlyChart,
};
