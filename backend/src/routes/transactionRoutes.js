const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const {
  getTransactions,
  createTransaction,
  updateTransaction,
  deleteTransaction,
  getSummary,
  getMonthlyChart,
} = require('../controllers/transactionController');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

// All routes require authentication
router.use(authenticate);

const transactionValidation = [
  body('title').trim().notEmpty().withMessage('Title is required'),
  body('amount').isFloat({ min: 0.01 }).withMessage('Amount must be a positive number'),
  body('type').isIn(['income', 'expense']).withMessage('Type must be income or expense'),
];

router.get('/',           getTransactions);
router.get('/summary',    getSummary);
router.get('/chart',      getMonthlyChart);
router.post('/',          transactionValidation, validate, createTransaction);
router.put('/:id',        transactionValidation, validate, updateTransaction);
router.delete('/:id',     deleteTransaction);

module.exports = router;
