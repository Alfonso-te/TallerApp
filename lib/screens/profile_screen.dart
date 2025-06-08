import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isEditing = false;
  bool _showPasswordFields = false;
  bool _isLoading = true;
  String? _profileImageUrl;
  final Color _goldColor = Color(0xFFD4AF37);
  final Color _darkColor = Colors.grey[900]!;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _nameController.text = userDoc.data()?['name'] ?? '';
        _emailController.text = user.email ?? '';
        _phoneController.text = userDoc.data()?['phone'] ?? '';
        _addressController.text = userDoc.data()?['address'] ?? '';
        _profileImageUrl = userDoc.data()?['profileImageUrl'];
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Actualizar datos en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Cambiar contraseña si se proporcionó
      if (_showPasswordFields &&
          _newPasswordController.text.isNotEmpty &&
          _newPasswordController.text == _confirmPasswordController.text) {
        await user.updatePassword(_newPasswordController.text);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perfil actualizado con éxito'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: _goldColor),
          ),
        ),
      );

      setState(() {
        _isEditing = false;
        _showPasswordFields = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar perfil: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: _goldColor),
          ),
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkColor,
        title: Text(
          'Confirmar eliminación',
          style: TextStyle(color: _goldColor),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: _goldColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Eliminar datos de Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();

          // Eliminar cuenta de autenticación
          await user.delete();

          // Redirigir a pantalla de login
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar cuenta: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: _goldColor),
            ),
          ),
        );
      }
    }
  }

  Future<void> _changeProfileImage() async {
    // Implementar lógica para cambiar imagen de perfil
    // Puedes usar image_picker para seleccionar de galería o cámara
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'MI PERFIL',
          style: TextStyle(
            color: _goldColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: _goldColor),
        elevation: 0,
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: _goldColor),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Sección de foto de perfil
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _goldColor, width: 2),
                            image: _profileImageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_profileImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImageUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: _goldColor,
                                )
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _changeProfileImage,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _darkColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _goldColor),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: _goldColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Campos del formulario
                    _buildEditableField(
                      controller: _nameController,
                      label: 'Nombre completo',
                      icon: Icons.person,
                      isEnabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _buildEditableField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      icon: Icons.email,
                      isEnabled: false, // Email no se puede editar
                    ),
                    SizedBox(height: 16),
                    _buildEditableField(
                      controller: _phoneController,
                      label: 'Teléfono',
                      icon: Icons.phone,
                      isEnabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    _buildEditableField(
                      controller: _addressController,
                      label: 'Dirección',
                      icon: Icons.location_on,
                      isEnabled: _isEditing,
                      maxLines: 2,
                    ),
                    SizedBox(height: 24),

                    // Campos de contraseña (solo al editar)
                    if (_isEditing && _showPasswordFields) ...[
                      _buildPasswordField(
                        controller: _passwordController,
                        label: 'Contraseña actual',
                        icon: Icons.lock,
                      ),
                      SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _newPasswordController,
                        label: 'Nueva contraseña',
                        icon: Icons.lock_outline,
                      ),
                      SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: 'Confirmar nueva contraseña',
                        icon: Icons.lock_reset,
                        validator: (value) {
                          if (_newPasswordController.text.isNotEmpty &&
                              value != _newPasswordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                    ],

                    // Botón para mostrar campos de contraseña
                    if (_isEditing && !_showPasswordFields)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showPasswordFields = true;
                          });
                        },
                        child: Text(
                          'Cambiar contraseña',
                          style: TextStyle(color: _goldColor),
                        ),
                      ),

                    // Botones de acción
                    SizedBox(height: 32),
                    if (!_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _goldColor,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'EDITAR PERFIL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    if (_isEditing) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _goldColor,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'GUARDAR CAMBIOS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _showPasswordFields = false;
                            _loadUserData(); // Recargar datos originales
                          });
                        },
                        child: Text(
                          'Cancelar',
                          style: TextStyle(color: _goldColor),
                        ),
                      ),
                    ],
                    SizedBox(height: 32),
                    Divider(color: _goldColor.withOpacity(0.3)),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: _deleteAccount,
                      child: Text(
                        'ELIMINAR MI CUENTA',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isEnabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: isEnabled,
      style: TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _goldColor),
        prefixIcon: Icon(icon, color: _goldColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _goldColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _goldColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _goldColor, width: 2),
        ),
        filled: true,
        fillColor: _darkColor,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _goldColor),
        prefixIcon: Icon(icon, color: _goldColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _goldColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _goldColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _goldColor, width: 2),
        ),
        filled: true,
        fillColor: _darkColor,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _darkColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(bottom: BorderSide(color: _goldColor, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _goldColor,
                  child: Icon(Icons.person, size: 30, color: Colors.black),
                ),
                SizedBox(height: 10),
                Text(
                  _nameController.text.isNotEmpty ? _nameController.text : 'Usuario',
                  style: TextStyle(
                    color: _goldColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? '',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: _goldColor),
            title: Text('Dashboard', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
          ListTile(
            leading: Icon(Icons.directions_car, color: _goldColor),
            title: Text('Mis Vehículos', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/vehicles');
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: _goldColor),
            title: Text('Mi Perfil', style: TextStyle(color: _goldColor, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          Divider(color: _goldColor.withOpacity(0.5)),
          ListTile(
            leading: Icon(Icons.logout, color: _goldColor),
            title: Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}