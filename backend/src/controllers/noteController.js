const pool = require('../config/database');

/**
 * GET /api/notes
 * Fetch all notes for authenticated user
 * Supports: ?is_task=true|false, ?search=text, ?limit=N, ?page=N
 */
const getNotes = async (req, res) => {
  const userId = req.user.id;
  const { is_task, search, limit = 50, page = 1 } = req.query;

  try {
    let conditions = ['user_id = $1'];
    let params = [userId];
    let idx = 2;

    if (is_task !== undefined) {
      conditions.push(`is_task = $${idx++}`);
      params.push(is_task === 'true');
    }
    if (search) {
      conditions.push(`(title ILIKE $${idx} OR content ILIKE $${idx})`);
      params.push(`%${search}%`);
      idx++;
    }

    const offset = (parseInt(page) - 1) * parseInt(limit);

    const query = `
      SELECT id, title, content, is_task, is_completed, color, created_at, updated_at
      FROM notes
      WHERE ${conditions.join(' AND ')}
      ORDER BY updated_at DESC
      LIMIT $${idx++} OFFSET $${idx}
    `;
    params.push(parseInt(limit), offset);

    const countQuery = `SELECT COUNT(*) FROM notes WHERE ${conditions.join(' AND ')}`;
    
    const [dataResult, countResult] = await Promise.all([
      pool.query(query, params),
      pool.query(countQuery, params.slice(0, -2)),
    ]);

    return res.status(200).json({
      success: true,
      data: dataResult.rows,
      pagination: {
        total: parseInt(countResult.rows[0].count),
        page: parseInt(page),
        limit: parseInt(limit),
      },
    });
  } catch (err) {
    console.error('Get notes error:', err);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

/**
 * POST /api/notes
 * Create a new note or task
 */
const createNote = async (req, res) => {
  const { title, content, is_task, color } = req.body;
  const userId = req.user.id;

  try {
    const result = await pool.query(
      `INSERT INTO notes (user_id, title, content, is_task, color)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [userId, title, content || null, is_task || false, color || '#FFFFFF']
    );

    return res.status(201).json({
      success: true,
      message: 'Note created successfully.',
      data: result.rows[0],
    });
  } catch (err) {
    console.error('Create note error:', err);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

/**
 * PUT /api/notes/:id
 * Update a note (title, content, completion status, color)
 */
const updateNote = async (req, res) => {
  const { id } = req.params;
  const { title, content, is_task, is_completed, color } = req.body;
  const userId = req.user.id;

  try {
    const owned = await pool.query(
      'SELECT id FROM notes WHERE id = $1 AND user_id = $2',
      [id, userId]
    );
    if (owned.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Note not found.' });
    }

    const result = await pool.query(
      `UPDATE notes
       SET title = $1, content = $2, is_task = $3, is_completed = $4, color = $5, updated_at = NOW()
       WHERE id = $6 AND user_id = $7
       RETURNING *`,
      [title, content || null, is_task || false, is_completed || false, color || '#FFFFFF', id, userId]
    );

    return res.status(200).json({
      success: true,
      message: 'Note updated successfully.',
      data: result.rows[0],
    });
  } catch (err) {
    console.error('Update note error:', err);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

/**
 * DELETE /api/notes/:id
 * Delete a note (only by owner)
 */
const deleteNote = async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  try {
    const result = await pool.query(
      'DELETE FROM notes WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Note not found.' });
    }

    return res.status(200).json({ success: true, message: 'Note deleted successfully.' });
  } catch (err) {
    console.error('Delete note error:', err);
    return res.status(500).json({ success: false, message: 'Internal server error.' });
  }
};

module.exports = { getNotes, createNote, updateNote, deleteNote };
