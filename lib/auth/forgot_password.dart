import 'package:flutter/material.dart';
import 'package:virtual_trading_app/auth/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final authService = AuthService();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Reset password method
  void resetPassword() async {
    // Validate email
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await authService.resetPassword(_emailController.text.trim());

      // Success
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: ${e.toString()}'),
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
      backgroundColor: const Color(0xff0a0a0a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Show different content based on whether email was sent
              if (!_emailSent) ...[
                // Title Section
                const Text(
                  'Forgot',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 42.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'your ',
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 42.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      TextSpan(
                        text: 'password?',
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 42.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE5BCE7),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'Enter your email and we\'ll send you a link to reset your password.',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha((0.7 * 255).round()),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 60),

                // Email Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
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
                        color: const Color(0xff1a1a1a),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.1 * 255).round()),
                        ),
                      ),
                      child: TextField(
                        controller: _emailController,
                        style: const TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: TextStyle(
                            fontFamily: 'ClashDisplay',
                            color: Colors.white.withAlpha((0.5 * 255).round()),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Reset Password Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5BCE7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Send Reset Link',
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                // Success state
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // Success icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFE5BCE7,
                          ).withAlpha((0.2 * 255).round()),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          size: 50,
                          color: Color(0xFFE5BCE7),
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'Check your email',
                        style: TextStyle(
                          fontFamily: 'ClashDisplay',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'We\'ve sent a password reset link to\n${_emailController.text.trim()}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withAlpha((0.7 * 255).round()),
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Back to login button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5BCE7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Back to Login',
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Resend button
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _emailSent = false;
                          });
                        },
                        child: Text(
                          'Didn\'t receive the email? Resend',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFE5BCE7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
