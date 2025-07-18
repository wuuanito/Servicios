const express = require('express');
const { body, param } = require('express-validator');
const userController = require('../controllers/user.controller');
const { validateRequest } = require('../middleware/validate.middleware');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// Change user password (admin/director only)
router.patch(
  '/:id/change-password',
  [
    param('id').isInt({ min: 1 }).withMessage('User ID must be a positive integer'),
    body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters long'),
    validateRequest
  ],
  authMiddleware,
  userController.changeUserPassword
);

// Get all users (admin only)
router.get(
  '/',
  authMiddleware,
  userController.getAllUsers
);

// Get user by ID (admin or self)
router.get(
  '/:id',
  [
    param('id').isInt({ min: 1 }).withMessage('User ID must be a positive integer'),
    validateRequest
  ],
  authMiddleware,
  userController.getUserById
);

// Update user complete profile (admin/director or self)
router.put(
  '/:id',
  [
    param('id').isInt({ min: 1 }).withMessage('User ID must be a positive integer'),
    body('username').optional().isString().isLength({ min: 3, max: 50 }).withMessage('Username must be between 3 and 50 characters'),
    body('firstName').optional().isString().isLength({ min: 1, max: 50 }).withMessage('First name must be between 1 and 50 characters'),
    body('lastName').optional().isString().isLength({ min: 1, max: 50 }).withMessage('Last name must be between 1 and 50 characters'),
    body('email').optional().isEmail().withMessage('Must be a valid email address'),
    body('department').optional().isIn([
      'informatica', 
      'administracion', 
      'internacional', 
      'compras', 
      'gerencia', 
      'oficina_tecnica', 
      'calidad', 
      'laboratorio', 
      'rrhh', 
      'logistica', 
      'mantenimiento', 
      'softgel', 
      'produccion',
      'sin_departamento'
    ]).withMessage('Invalid department'),
    body('role').optional().isIn([
      'director', 'administrador', 'empleado'
    ]).withMessage('Invalid role'),
    body('jobTitle').optional().isString().isLength({ max: 100 }).withMessage('Job title must be a string with max 100 characters'),
    body('isActive').optional().isBoolean().withMessage('isActive must be a boolean value'),
    validateRequest
  ],
  authMiddleware,
  userController.updateUser
);

// Delete user (admin only)
router.delete(
  '/:id',
  [
    param('id').isInt({ min: 1 }).withMessage('User ID must be a positive integer'),
    validateRequest
  ],
  authMiddleware,
  userController.deleteUser
);

// Update user role (admin only)
router.patch(
  '/:id/role',
  [
    param('id').isInt({ min: 1 }).withMessage('User ID must be a positive integer'),
    body('role').isIn(['user', 'admin']).withMessage('Invalid role - Must be "user" or "admin"'),
    validateRequest
  ],
  authMiddleware,
  userController.updateUserRole
);

module.exports = router;