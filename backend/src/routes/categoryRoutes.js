const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { getCategories, createCategory } = require('../controllers/categoryController');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

router.use(authenticate);

router.get('/', getCategories);
router.post('/',
  [body('name').trim().notEmpty().withMessage('Category name is required')],
  validate,
  createCategory
);

module.exports = router;
