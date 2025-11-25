import 'package:flutter/material.dart';

/// Widget to display cryptocurrency logo from Logokit API
/// Falls back to symbol text if image fails to load
class CryptoLogo extends StatelessWidget {
  final String symbol;
  final double size;
  final double fontSize;

  const CryptoLogo({
    super.key,
    required this.symbol,
    this.size = 48,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    // Logokit API uses lowercase symbols
    final logoUrl =
        'https://assets.coincap.io/assets/icons/${symbol.toLowerCase()}@2x.png';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.05 * 255).round()),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      padding: EdgeInsets.all(size * 0.1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: Image.network(
          logoUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: size / 3,
                height: size / 3,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFFE5BCE7),
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Fallback to text if image fails to load
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE5BCE7).withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(size / 4),
              ),
              child: Center(
                child: Text(
                  symbol.substring(0, symbol.length > 3 ? 3 : symbol.length),
                  style: TextStyle(
                    fontFamily: 'ClashDisplay',
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE5BCE7),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
