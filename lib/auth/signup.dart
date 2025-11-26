import 'package:flutter/material.dart';
import 'package:virtual_trading_app/auth/auth_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Signup method
  void signup() async {
    // Validate inputs
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check password length
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Attempt to sign up with full name metadata
      await authService.signUpWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
        fullName: _nameController.text.trim(),
      );

      // Success - pop back to AuthGate
      if (mounted) {
        // Show success message briefly before navigating
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created successfully! Please check your email to verify.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Pop all routes and go back to root (AuthGate)
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Google Sign-in method
  void signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await authService.signInWithGoogle();

      if (response == null) {
        // User cancelled
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Success - pop back to AuthGate
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine if we need compact spacing for smaller screens
            final isCompactScreen = constraints.maxHeight < 700;
            final topPadding = isCompactScreen ? 20.0 : 30.0;
            final titleSpacing = isCompactScreen ? 12.0 : 16.0;
            final sectionSpacing = isCompactScreen ? 24.0 : 40.0;
            final fieldSpacing = isCompactScreen ? 16.0 : 24.0;
            final bottomPadding = isCompactScreen ? 20.0 : 40.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: topPadding),

                  // Title Section
                  Text(
                    'Create your',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: isCompactScreen ? 36.0 : 42.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'trading ',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: isCompactScreen ? 36.0 : 42.0,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                            height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: 'account',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: isCompactScreen ? 36.0 : 42.0,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: titleSpacing),

                  // Subtitle
                  Text(
                    'Start your journey to financial success.',
                    style: TextStyle(
                      fontFamily: 'ClashDisplay',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withAlpha((0.7 * 255).round()),
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: sectionSpacing),

                  // Name Field
                  _buildInputField(
                    label: 'Full Name',
                    controller: _nameController,
                    hintText: 'Enter your full name',
                    keyboardType: TextInputType.text,
                  ),

                  SizedBox(height: fieldSpacing),

                  // Email Field
                  _buildInputField(
                    label: 'Email',
                    controller: _emailController,
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  SizedBox(height: fieldSpacing),

                  // Password Field
                  _buildInputField(
                    label: 'Password',
                    controller: _passwordController,
                    hintText: 'Create a password',
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),

                  SizedBox(height: fieldSpacing),

                  // Confirm Password Field
                  _buildInputField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    hintText: 'Confirm your password',
                    isPassword: true,
                    obscureText: _obscureConfirmPassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),

                  SizedBox(height: sectionSpacing),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : Text(
                              'Create Account',
                              style: TextStyle(
                                fontFamily: 'ClashDisplay',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: isCompactScreen ? 24.0 : 32.0),

                  // Divider with "OR"
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withAlpha((0.2 * 255).round()),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withAlpha((0.5 * 255).round()),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withAlpha((0.2 * 255).round()),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isCompactScreen ? 24.0 : 32.0),

                  // Google Sign-in Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.white, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      icon: Image.asset(
                        'assets/icon/google_icon.png',
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.login, color: Colors.black);
                        },
                      ),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isCompactScreen ? 24.0 : 32.0),

                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 16,
                          color: Colors.white.withAlpha((0.7 * 255).round()),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: bottomPadding),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ClashDisplay',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword ? obscureText : false,
            keyboardType: keyboardType,
            style: TextStyle(
              fontFamily: 'ClashDisplay',
              fontSize: 16,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontFamily: 'ClashDisplay',
                color: Colors.white.withAlpha((0.5 * 255).round()),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withAlpha((0.5 * 255).round()),
                      ),
                      onPressed: onToggleObscure,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
