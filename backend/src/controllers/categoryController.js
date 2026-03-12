const pool = require('../config/database');

/**
 * GET /api/categories
 * Get all categories (global + user-specific if needed)
 */
const getCategories = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, icon, color, type, is_default
       FROM categories
       ORDER BY is_default DESC, name ASC`
    );

    return res.status(200).json({ success: true, data: result.rows });
  } catch (err) {
    console.error('Get categories error:', err);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

/**
 * POST /api/categories
 * Create a custom category
 */
const createCategory = async (req, res) => {
  const { name, icon, color, type } = req.body;

  try {
    const result = await pool.query(
      `INSERT INTO categories (name, icon, color, type)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [name, icon || 'category', color || '#6366F1', type || 'both']
    );

    return res.status(201).json({
      success: true,
      message: 'Category created.',
      data: result.rows[0],
    });
  } catch (err) {
    console.error('Create category error:', err);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

module.exports = { getCategories, createCategory };
