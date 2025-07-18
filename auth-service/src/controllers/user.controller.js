const userService = require('../services/user.service');
const { formatResponse } = require('../utils/response-formatter');

// Get all users with complete information (admin/director only)
const getAllUsers = async (req, res, next) => {
  try {
    // Check if user is admin or director
    if (req.user.role !== 'administrador' && req.user.role !== 'director') {
      return res.status(403).json({ 
        error: 'Forbidden - Admin or Director access required' 
      });
    }
    
    const users = await userService.findAll();
    
    return res.status(200).json(formatResponse(
      users.map(user => ({
        id: user.id,
        username: user.username,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
        department: user.department,
        jobTitle: user.jobTitle,
        isActive: user.isActive,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        lastLogin: user.lastLogin
      }))
    ));
  } catch (error) {
    next(error);
  }
};

// Get user by ID (admin or self)
const getUserById = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    // Check if user is admin or getting their own profile
    if (req.user.role !== 'admin' && req.user.id !== parseInt(id, 10)) {
      return res.status(403).json({ 
        error: 'Forbidden - You can only access your own profile' 
      });
    }
    
    const user = await userService.findById(id);
    
    if (!user) {
      return res.status(404).json({ 
        error: 'User not found' 
      });
    }
    
    return res.status(200).json(formatResponse({
      id: user.id,
      username: user.username,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      isActive: user.isActive,
      createdAt: user.createdAt,
      lastLogin: user.lastLogin
    }));
  } catch (error) {
    next(error);
  }
};

// Update user complete profile (admin/director or self)
const updateUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { firstName, lastName, email, department, role, jobTitle, username, isActive } = req.body;
    
    // Check if user is administrador/director or updating their own profile
    if (req.user.role !== 'administrador' && req.user.role !== 'director' && req.user.id !== parseInt(id, 10)) {
      return res.status(403).json({ 
        error: 'Forbidden - You can only update your own profile' 
      });
    }
    
    // Check if user exists
    const user = await userService.findById(id);
    if (!user) {
      return res.status(404).json({ 
        error: 'User not found' 
      });
    }
    
    // Base data that anyone can update on their own profile
    let updateData = { firstName, lastName, email };
    
    // Admins and directors can update more fields
    if (req.user.role === 'administrador' || req.user.role === 'director') {
      updateData = { 
        ...updateData, 
        department, 
        jobTitle,
        username,
        isActive
      };
      
      // Only directors can change roles
      if (req.user.role === 'director') {
        updateData.role = role;
      }
    }
    
    // Remove undefined values
    Object.keys(updateData).forEach(key => {
      if (updateData[key] === undefined) {
        delete updateData[key];
      }
    });
    
    // Update user
    const updatedUser = await userService.updateUser(id, updateData);
    
    return res.status(200).json(formatResponse({
      id: updatedUser.id,
      username: updatedUser.username,
      email: updatedUser.email,
      firstName: updatedUser.firstName,
      lastName: updatedUser.lastName,
      role: updatedUser.role,
      department: updatedUser.department,
      jobTitle: updatedUser.jobTitle,
      isActive: updatedUser.isActive,
      updatedAt: updatedUser.updatedAt
    }, 'User updated successfully'));
  } catch (error) {
    next(error);
  }
};

// Change user password (admin/director only)
const changeUserPassword = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { newPassword } = req.body;
    
    // Check if user is admin or director
    if (req.user.role !== 'administrador' && req.user.role !== 'director') {
      return res.status(403).json({ 
        error: 'Forbidden - Admin or Director access required' 
      });
    }
    
    // Validate password
    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({ 
        error: 'Password must be at least 6 characters long' 
      });
    }
    
    // Check if user exists
    const user = await userService.findById(id);
    if (!user) {
      return res.status(404).json({ 
        error: 'User not found' 
      });
    }
    
    // Update password
    await userService.updatePassword(id, newPassword);
    
    return res.status(200).json(formatResponse(
      null,
      'Password updated successfully'
    ));
  } catch (error) {
    next(error);
  }
};

// Delete user (admin only)
const deleteUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ 
        error: 'Forbidden - Admin access required' 
      });
    }
    
    // Check if user exists
    const user = await userService.findById(id);
    if (!user) {
      return res.status(404).json({ 
        error: 'User not found' 
      });
    }
    
    // Delete user
    await userService.deleteUser(id);
    
    return res.status(200).json(formatResponse(
      null, 
      'User deleted successfully'
    ));
  } catch (error) {
    next(error);
  }
};

// Update user role (admin only)
const updateUserRole = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { role } = req.body;
    
    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ 
        error: 'Forbidden - Admin access required' 
      });
    }
    
    // Check if role is valid
    if (!['user', 'admin'].includes(role)) {
      return res.status(400).json({ 
        error: 'Invalid role - Must be "user" or "admin"' 
      });
    }
    
    // Check if user exists
    const user = await userService.findById(id);
    if (!user) {
      return res.status(404).json({ 
        error: 'User not found' 
      });
    }
    
    // Update user role
    const updatedUser = await userService.updateUserRole(id, role);
    
    return res.status(200).json(formatResponse({
      id: updatedUser.id,
      username: updatedUser.username,
      role: updatedUser.role
    }, 'User role updated successfully'));
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getAllUsers,
  getUserById,
  updateUser,
  changeUserPassword,
  deleteUser,
  updateUserRole
};