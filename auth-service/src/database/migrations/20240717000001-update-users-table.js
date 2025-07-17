'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // First, drop the existing role enum and recreate it with new values
    await queryInterface.sequelize.query('ALTER TABLE users MODIFY COLUMN role ENUM(\'director\', \'administrador\', \'empleado\') DEFAULT \'empleado\'');
    
    // Add department column
    await queryInterface.addColumn('users', 'department', {
      type: Sequelize.ENUM(
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
      ),
      defaultValue: 'sin_departamento',
      allowNull: true
    });
    
    // Add jobTitle column
    await queryInterface.addColumn('users', 'jobTitle', {
      type: Sequelize.STRING(100),
      allowNull: true
    });
    
    // Update existing users to have the new default role if they have old values
    await queryInterface.sequelize.query(
      "UPDATE users SET role = 'empleado' WHERE role NOT IN ('director', 'administrador', 'empleado')"
    );
  },

  down: async (queryInterface, Sequelize) => {
    // Remove the new columns
    await queryInterface.removeColumn('users', 'department');
    await queryInterface.removeColumn('users', 'jobTitle');
    
    // Revert role enum to original values
    await queryInterface.sequelize.query('ALTER TABLE users MODIFY COLUMN role ENUM(\'user\', \'admin\') DEFAULT \'user\'');
  }
};