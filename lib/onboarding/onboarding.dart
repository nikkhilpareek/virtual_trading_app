import 'package:flutter/material.dart';
import '../widgets/sliding_button.dart';
import '../auth/login.dart';

class Onboarding extends StatelessWidget {
  const Onboarding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Title Section
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transform',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 42,
                        fontWeight: FontWeight.w600, // Semibold
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'the way you',
                      style: TextStyle(
                        fontFamily: 'ClashDisplay',
                        fontSize: 42,
                        fontWeight: FontWeight.w600, // Semibold
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'learn ',
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 42,
                              fontWeight: FontWeight.w600, // Semibold
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: 'Trading',
                            style: TextStyle(
                              fontFamily: 'ClashDisplay',
                              fontSize: 42,
                              fontWeight: FontWeight.w600, // Semibold
                              color: Theme.of(context).colorScheme.primary,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Subtitle
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Learn by Simulating your Trades without the fear of losses.',
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha((0.7 * 255).round()),
                    height: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              // Illustration
              SizedBox(
                height: 300,
                width: 250,
                child: Image.asset(
                  'assets/images/illustration.png',
                  fit: BoxFit.fill,
                ),
              ),
              const Spacer(),
              // Get Started Sliding Button
              SlidingButton(
                text: 'Get Started',
                backgroundColor: const Color(
                  0xFF303030,
                ), // Keep the existing pink color
                sliderColor: Theme.of(
                  context,
                ).colorScheme.primary, // Royal Blue slider color
                textColor: Colors.black,
                onSlideComplete: () {
                  // Navigate to login screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
