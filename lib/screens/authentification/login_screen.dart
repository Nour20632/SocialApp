// screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:social_app/utils/app_localizations.dart';
import 'package:social_app/utils/auth_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrUsernameController =
      TextEditingController(); // تعديل لدعم اسم المستخدم أو البريد
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true; // For toggle password visibility
  bool _isEmailLogin = true; // للتبديل بين البريد واسم المستخدم

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? error;

    // تحديد نوع تسجيل الدخول (بالبريد أو اسم المستخدم)
    if (_isEmailLogin) {
      // تسجيل الدخول بالبريد الإلكتروني
      error = await AuthUtils.signIn(
        email: _emailOrUsernameController.text.trim(),
        password: _passwordController.text.trim(),
        context: context,
      );
    } else {
      // تسجيل الدخول باسم المستخدم
      error = await AuthUtils.signInWithUsername(
        username: _emailOrUsernameController.text.trim(),
        password: _passwordController.text.trim(),
        context: context,
      );
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      // Use the improved error handler for consistent and localized errors
      _errorMessage = AuthUtils.handleAuthError(context, error);
    });

    // Only navigate if there is NO error
    if (_errorMessage == null) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isRtl = loc.isArabic;

    return Directionality(
      // Set the correct text direction based on language
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        loc.login,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24),

                      // تبديل طريقة تسجيل الدخول (بريد/اسم مستخدم)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: Text('Email'),
                            selected: _isEmailLogin,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _isEmailLogin = true;
                                });
                              }
                            },
                          ),
                          SizedBox(width: 16),
                          ChoiceChip(
                            label: Text('Username'),
                            selected: !_isEmailLogin,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _isEmailLogin = false;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Email/Username Field with localized validation
                      TextFormField(
                        controller: _emailOrUsernameController,
                        keyboardType:
                            _isEmailLogin
                                ? TextInputType.emailAddress
                                : TextInputType.text,
                        textDirection: TextDirection.ltr, // Email is always LTR
                        decoration: InputDecoration(
                          hintText:
                              _isEmailLogin ? loc.enterEmail : 'Enter username',
                          prefixIcon: Icon(
                            _isEmailLogin ? Icons.email : Icons.person,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return _isEmailLogin
                                ? loc.emailRequired
                                : 'Username is required';
                          }
                          if (_isEmailLogin &&
                              !RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                            return loc.invalidEmailError;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      // Password Field with toggle visibility
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: loc.passwordRequired,
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return loc.passwordRequired;
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 8),
                      // Forgot password link
                      Align(
                        alignment:
                            isRtl
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) =>
                                      _buildForgotPasswordDialog(context),
                            );
                          },
                          child: Text(loc.forgotPassword),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      SizedBox(height: 16),
                      // Login button with loading indicator
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isLoading ? null : _login,
                          child:
                              _isLoading
                                  ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(loc.login),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Signup link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(loc.dontHaveAccount),
                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/signup');
                            },
                            child: Text(loc.signup),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isRtl = loc.isArabic;
    final emailController = TextEditingController();
    bool isLoading = false;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(loc.resetPassword),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.enterEmailForReset),
                SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr, // Email is always LTR
                  decoration: InputDecoration(
                    hintText: loc.enterEmail,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(loc.cancel),
              ),
              ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : () async {
                          setState(() {
                            isLoading = true;
                          });

                          final error = await AuthUtils.resetPassword(
                            emailController.text.trim(),
                            context,
                          );

                          if (context.mounted) {
                            setState(() {
                              isLoading = false;
                            });

                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error == null
                                      ? loc.resetLinkSent
                                      : 'Error: ${AuthUtils.handleAuthError(context, error)}',
                                ),
                                backgroundColor:
                                    error == null ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                child:
                    isLoading
                        ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(loc.sendLink),
              ),
            ],
          );
        },
      ),
    );
  }
}
