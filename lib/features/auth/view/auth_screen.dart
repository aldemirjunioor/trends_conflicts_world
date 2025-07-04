import 'package:flutter/material.dart';
import 'package:myapp/features/auth/controller/auth_controller.dart';
import 'package:myapp/features/home/view/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthController _authController = AuthController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoginView = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleView() {
    if (_isLoading) return;
    setState(() {
      _isLoginView = !_isLoginView;
      _formKey.currentState?.reset();
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  void _navigateToHome() {
     if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _submitForm() async {
    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String? errorMessage;
      if (_isLoginView) {
        errorMessage = await _authController.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
         if (errorMessage == null) {
          _navigateToHome();
        }
      } else {
        errorMessage = await _authController.register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
         if (errorMessage == null) {
          _showSnackBar('Registro realizado com sucesso!', isError: false);
          // Wait a bit for the user to see the message before navigating
          await Future.delayed(const Duration(seconds: 1));
          _navigateToHome();
        }
      }

      // Must check if the widget is still mounted before updating the state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (errorMessage != null) {
          _showSnackBar(errorMessage);
        }
      }
    }
  }

  void _forgotPassword() async {
    if (_isLoading) return;

    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Por favor, insira seu e-mail.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? errorMessage =
        await _authController.forgotPassword(_emailController.text.trim());

     if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (errorMessage != null) {
          _showSnackBar(errorMessage);
        } else {
          _showSnackBar(
            'Link para recuperação enviado para ${_emailController.text.trim()}',
            isError: false,
          );
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isLoginView
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF000080)),
                onPressed: _isLoading ? null : _toggleView,
              ),
            ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _isLoginView ? _buildLoginForm() : _buildRegisterForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return KeyedSubtree(
      key: const ValueKey('loginForm'),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Trends Conflicts World',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000080), // Navy Blue
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Faça login para continuar',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildTextField(
              controller: _emailController,
              labelText: 'E-mail',
              icon: Icons.email_outlined,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty ||
                    !value.contains('@')) {
                  return 'Por favor, insira um e-mail válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _passwordController,
              labelText: 'Senha',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (value) {
                if (value == null || value.trim().length < 6) {
                  return 'A senha deve ter pelo menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: const Text(
                  'Esqueceu a senha?',
                  style: TextStyle(color: Color(0xFF000080)), // Navy Blue
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildSubmitButton('Login'),
            const SizedBox(height: 20),
            _buildToggleViewButton("Não tem uma conta?", 'Registre-se'),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return KeyedSubtree(
      key: const ValueKey('registerForm'),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Crie sua conta',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000080), // Navy Blue
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cadastre-se para começar',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildTextField(
              controller: _nameController,
              labelText: 'Nome Completo',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira seu nome completo';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              labelText: 'E-mail',
              icon: Icons.email_outlined,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty ||
                    !value.contains('@')) {
                  return 'Por favor, insira um e-mail válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _passwordController,
              labelText: 'Senha',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (value) {
                if (value == null || value.trim().length < 6) {
                  return 'A senha deve ter pelo menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            _buildSubmitButton('Registrar'),
            const SizedBox(height: 20),
            _buildToggleViewButton('Já tem uma conta?', 'Login'),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide:
              const BorderSide(color: Color(0xFF000080), width: 2), // Navy Blue
        ),
      ),
    );
  }

  Widget _buildSubmitButton(String text) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF000080), // Navy Blue
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 5,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Text(
                text,
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildToggleViewButton(String text, String buttonText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: const TextStyle(color: Colors.grey)),
        TextButton(
          onPressed: _isLoading ? null : _toggleView,
          child: Text(
            buttonText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF000080), // Navy Blue
            ),
          ),
        ),
      ],
    );
  }
}
