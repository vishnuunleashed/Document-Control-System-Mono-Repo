import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_app/app/di/dependency_injection.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isRegisterMode = false;
  String _selectedRole = "Employee"; // Demo role helper

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final authBloc = context.read<AuthBloc>();
    if (_isRegisterMode) {
      authBloc.add(
        AuthRegisterRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
        ),
      );
    } else {
      authBloc.add(
        AuthLoginRequested(
          _emailController.text.trim(),
          _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return BlocProvider(
      create: (context) => AuthBloc(DependencyInjection.authRepository)..add(AuthCheckRequested()),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go('/');
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F172A),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              ),
            );
          }

          return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A), // Slate 900
                    Color(0xFF1E293B), // Slate 800
                    Color(0xFF0F172A),
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: size.width > 500 ? 440 : size.width * 0.9,
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF334155).withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App Branding
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.assignment_turned_in,
                                  size: 32,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                "DCS Control",
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isRegisterMode
                                ? "Create a workspace account"
                                : "Log in to your document workspace",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Form Fields
                          if (_isRegisterMode) ...[
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: "Full Name",
                                icon: Icons.person_outline,
                                theme: theme,
                              ),
                              validator: (value) => value == null || value.trim().length < 2
                                  ? "Enter a valid name"
                                  : null,
                            ),
                            const SizedBox(height: 20),
                          ],

                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                              label: "Email Address",
                              icon: Icons.email_outlined,
                              theme: theme,
                            ),
                            validator: (value) => value == null || !value.contains("@")
                                ? "Enter a valid email"
                                : null,
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _passwordController,
                            style: const TextStyle(color: Colors.white),
                            obscureText: true,
                            decoration: _inputDecoration(
                              label: "Password",
                              icon: Icons.lock_outline,
                              theme: theme,
                            ),
                            validator: (value) => value == null || value.length < 6
                                ? "Password must be at least 6 characters"
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // Demo Role Helper (Only on Register Mode)
                          if (_isRegisterMode) ...[
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              dropdownColor: const Color(0xFF1E293B),
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                label: "Assigned Workspace Role",
                                icon: Icons.badge_outlined,
                                theme: theme,
                              ),
                              items: ["Employee", "Reviewer", "Approver", "Admin"]
                                  .map((role) => DropdownMenuItem(
                                        value: role,
                                        child: Text(role),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedRole = val;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 28),
                          ],

                          // Submit Button
                          ElevatedButton(
                            onPressed: () => _submit(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              _isRegisterMode ? "REGISTER ACCOUNT" : "SIGN IN",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Mode Switcher Text
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isRegisterMode = !_isRegisterMode;
                                _formKey.currentState?.reset();
                              });
                            },
                            child: Text(
                              _isRegisterMode
                                  ? "Already have an account? Sign In"
                                  : "Need a new account? Register",
                              style: TextStyle(
                                color: theme.colorScheme.primary.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required ThemeData theme,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFF0F172A).withOpacity(0.6),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }
}
