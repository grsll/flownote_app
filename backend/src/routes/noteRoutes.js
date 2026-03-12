const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { getNotes, createNote, updateNote, deleteNote } = require('../controllers/noteController');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

router.use(authenticate);

const noteValidation = [
  body('title').trim().notEmpty().withMessage('Title is required'),
];

router.get('/',       getNotes);
router.post('/',      noteValidation, validate, createNote);
router.put('/:id',    noteValidation, validate, updateNote);
router.delete('/:id', deleteNote);

module.exports = router;
