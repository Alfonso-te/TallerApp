import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1C1C1E),
              Color(0xFF0D0D0F),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 24 : 40,
              vertical: 40,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenSize.height - 80, // Garantiza altura mínima
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Imagen destacada siempre completa con tamaño responsivo
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double imageHeight = screenSize.width > 600 ? 0.4 : 0.3; // Reduce el tamaño de la imagen en pantallas grandes
                      return Container(
                        height: screenSize.height * imageHeight,
                        margin: const EdgeInsets.only(bottom: 40),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.25),
                              blurRadius: 18,
                              spreadRadius: 1,
                              offset: const Offset(0, 12),
                            ),
                          ],
                          image: const DecorationImage(
                            image: AssetImage('assets/images/taller_mecanico.jpg'),
                            fit: BoxFit.cover, // Asegura que la imagen se adapte al contenedor
                          ),
                        ),
                      );
                    },
                  ),

                  // Título metálico más claro
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFFD700), // Dorado claro
                        Color(0xFFFFC107),
                        Color(0xFFFFD700),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ).createShader(bounds),
                    child: Text(
                      'TALLER MECÁNICO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 30 : 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        height: 1.2,
                        color: Colors.white, // Fallback
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtítulo
                  Text(
                    'Excelencia en servicio automotriz',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey[300],
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Botón Iniciar Sesión
                  _buildPremiumButton(
                    context,
                    text: 'INICIAR SESIÓN',
                    onPressed: () => _navigateTo(context, const LoginScreen()),
                  ),

                  const SizedBox(height: 20),

                  // Divisor
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey[700],
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'O CONTINÚA CON',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey[700],
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Botón Registro
                  _buildPremiumOutlineButton(
                    context,
                    text: 'REGISTRARSE',
                    onPressed: () => _navigateTo(context, const RegisterScreen()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: const Color(0xFFFF8F00),
        foregroundColor: Colors.white,
        elevation: 6,
        shadowColor: Colors.amber.withOpacity(0.4),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      child: Text(text),
    );
  }

  Widget _buildPremiumOutlineButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: const BorderSide(
          color: Color(0xFFFF8F00),
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        foregroundColor: const Color(0xFFFF8F00),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      child: Text(text),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeInOut;
          final tween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

          return FadeTransition(
            opacity: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}