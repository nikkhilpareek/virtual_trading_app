# 🎨 Quick Theme Reference Guide

## Color Usage Cheat Sheet

### Primary Colors
```dart
// Royal Blue - Use for: buttons, links, highlights
Theme.of(context).colorScheme.primary        // #0061FF (light) / #4D8DFF (dark)
```

### Secondary Colors
```dart
// Green - Use for: profit indicators, positive actions
Theme.of(context).colorScheme.secondary      // #00C853 (light) / #27C46D (dark)
```

### Background Colors
```dart
// Main background
Theme.of(context).scaffoldBackgroundColor    // #F5F7FA (light) / #0D1117 (dark)

// Card/Surface
Theme.of(context).colorScheme.surface        // #FFFFFF (light) / #161B22 (dark)
```

### Text Colors
```dart
// Primary text (headings, important text)
Theme.of(context).colorScheme.onSurface      // #1C1C1C (light) / #E6E6E6 (dark)

// Secondary text (labels, descriptions)
Theme.of(context).colorScheme.onSurfaceVariant  // #5F6368 (light) / #9BA3B0 (dark)
```

### Error/Loss Colors
```dart
// Use for: losses, errors, delete actions
Theme.of(context).colorScheme.error          // #D32F2F (light) / #FF6B6B (dark)
```

---

## Text Style Quick Reference

### Headings
```dart
// Large heading (32px)
style: Theme.of(context).textTheme.headlineLarge

// Medium heading (28px)
style: Theme.of(context).textTheme.headlineMedium

// Small heading (24px)
style: Theme.of(context).textTheme.headlineSmall
```

### Titles
```dart
// Card titles (22px)
style: Theme.of(context).textTheme.titleLarge

// Section titles (16px)
style: Theme.of(context).textTheme.titleMedium

// Small titles (14px)
style: Theme.of(context).textTheme.titleSmall
```

### Body Text
```dart
// Main content (16px)
style: Theme.of(context).textTheme.bodyLarge

// Regular text (14px)
style: Theme.of(context).textTheme.bodyMedium

// Small text (12px)
style: Theme.of(context).textTheme.bodySmall
```

### Trading-Specific
```dart
// Large price display (32px, tabular)
style: AppTextStyles.priceDisplay

// Small price (18px, tabular)
style: AppTextStyles.priceSmall

// Percentage change (14px, tabular)
style: AppTextStyles.percentageChange

// Crypto symbol (16px, spaced)
style: AppTextStyles.cryptoSymbol
```

---

## Common Widget Examples

### Card with Theme Colors
```dart
Card(
  // Uses theme automatically
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Title',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Text(
          'Card content goes here',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  ),
)
```

### Profit/Loss Display
```dart
final profitLoss = 1234.56;
final isProfit = profitLoss >= 0;

Row(
  children: [
    Icon(
      isProfit ? Icons.arrow_upward : Icons.arrow_downward,
      color: isProfit 
          ? Theme.of(context).colorScheme.secondary  // Green
          : Theme.of(context).colorScheme.error,     // Red
      size: 20,
    ),
    SizedBox(width: 4),
    Text(
      '${isProfit ? '+' : ''}₹${profitLoss.toStringAsFixed(2)}',
      style: AppTextStyles.percentageChange.copyWith(
        color: isProfit 
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).colorScheme.error,
      ),
    ),
  ],
)
```

### Primary Button
```dart
ElevatedButton(
  onPressed: () {},
  // Uses theme automatically
  child: Text('Buy Now'),
)
```

### Outlined Button
```dart
OutlinedButton(
  onPressed: () {},
  // Uses theme automatically
  child: Text('View Details'),
)
```

### Text Input Field
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Enter Amount',
    hintText: '0.00',
    prefixText: '₹ ',
    // All styling from theme
  ),
)
```

---

## Toggle Dark Mode

### In Any Widget
```dart
// Get current theme
final isDark = Theme.of(context).brightness == Brightness.dark;

// Toggle theme
IconButton(
  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
  onPressed: () {
    context.read<ThemeBloc>().add(const ToggleThemeEvent());
  },
)
```

### Check Theme State
```dart
BlocBuilder<ThemeBloc, ThemeState>(
  builder: (context, state) {
    return Text(
      state.isDarkMode ? 'Dark Mode Active' : 'Light Mode Active',
    );
  },
)
```

---

## Color Constants (Direct Access)

When you need the exact colors (not theme-dependent):

```dart
import 'package:virtual_trading_app/core/theme/app_colors.dart';

// Light theme colors
AppColors.lightPrimary        // #0061FF
AppColors.lightSecondary      // #00C853
AppColors.lightBackground     // #F5F7FA
AppColors.lightCardBackground // #FFFFFF
AppColors.lightTextPrimary    // #1C1C1C
AppColors.lightTextSecondary  // #5F6368
AppColors.lightError          // #D32F2F

// Dark theme colors
AppColors.darkPrimary         // #4D8DFF
AppColors.darkSecondary       // #27C46D
AppColors.darkBackground      // #0D1117
AppColors.darkCardBackground  // #161B22
AppColors.darkTextPrimary     // #E6E6E6
AppColors.darkTextSecondary   // #9BA3B0
AppColors.darkError           // #FF6B6B

// Semantic colors (same in both themes)
AppColors.profit              // #00C853
AppColors.loss                // #D32F2F
AppColors.neutral             // #9E9E9E
```

---

## Gradients

```dart
import 'package:virtual_trading_app/core/theme/app_colors.dart';

// Profit gradient (green)
Container(
  decoration: BoxDecoration(
    gradient: AppColors.profitGradient,
    borderRadius: BorderRadius.circular(12),
  ),
)

// Loss gradient (red)
Container(
  decoration: BoxDecoration(
    gradient: AppColors.lossGradient,
    borderRadius: BorderRadius.circular(12),
  ),
)

// Primary gradient (blue)
Container(
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(12),
  ),
)
```

---

## Responsive Design Tips

### Use MediaQuery for Sizing
```dart
final screenWidth = MediaQuery.of(context).size.width;
final isSmallScreen = screenWidth < 600;

// Adjust padding based on screen size
padding: EdgeInsets.all(isSmallScreen ? 12 : 24)
```

### Responsive Text
```dart
Text(
  'Hello',
  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
    fontSize: isSmallScreen ? 24 : 28,
  ),
)
```

---

## Animation Examples

### Fade In
```dart
AnimatedOpacity(
  opacity: _isVisible ? 1.0 : 0.0,
  duration: Duration(milliseconds: 300),
  child: YourWidget(),
)
```

### Slide In
```dart
AnimatedSlide(
  offset: _isVisible ? Offset.zero : Offset(0, 0.5),
  duration: Duration(milliseconds: 300),
  child: YourWidget(),
)
```

### Scale
```dart
AnimatedScale(
  scale: _isHovered ? 1.05 : 1.0,
  duration: Duration(milliseconds: 200),
  child: YourWidget(),
)
```

---

## Common Mistakes to Avoid

### ❌ Don't Do This
```dart
// Hardcoded colors
Container(color: Color(0xFF0061FF))

// Hardcoded text styles
Text('Hello', style: TextStyle(fontSize: 16, color: Colors.black))

// Fixed sizes without considering theme
SizedBox(height: 20)
```

### ✅ Do This Instead
```dart
// Use theme colors
Container(color: Theme.of(context).colorScheme.primary)

// Use theme text styles
Text('Hello', style: Theme.of(context).textTheme.bodyLarge)

// Use theme spacing (if defined)
SizedBox(height: 16) // Stick to 8px grid: 8, 16, 24, 32...
```

---

## Testing Checklist

- [ ] Dark mode toggle works in Profile screen
- [ ] Theme persists after app restart
- [ ] All text is readable in both themes
- [ ] Colors are consistent throughout the app
- [ ] Buttons have proper hover/press states
- [ ] Input fields are clearly visible
- [ ] Profit/loss colors are correct (green/red)
- [ ] Charts use theme-appropriate colors
- [ ] Cards have proper elevation
- [ ] Icons are visible in both themes

---

**Last Updated**: November 25, 2025  
**Theme Version**: 1.0.0  
**Compatible with**: Flutter 3.8.1+
