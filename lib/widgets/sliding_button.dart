import 'package:flutter/material.dart';

class SlidingButton extends StatefulWidget {
  final String text;
  final VoidCallback onSlideComplete;
  final Color backgroundColor;
  final Color sliderColor;
  final Color textColor;
  final double height;
  final double borderRadius;

  const SlidingButton({
    super.key,
    required this.text,
    required this.onSlideComplete,
    this.backgroundColor = const Color(0xFFE5BCE7),
    this.sliderColor = const Color(0xFFFF6B35),
    this.textColor = Colors.black,
    this.height = 56,
    this.borderRadius = 28,
  });

  @override
  State<SlidingButton> createState() => _SlidingButtonState();
}

class _SlidingButtonState extends State<SlidingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _dragPosition = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    // Start sliding gesture
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isCompleted) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final containerWidth = renderBox.size.width;
      final sliderWidth = _getSliderWidth(containerWidth);
      final maxSlideDistance = containerWidth - sliderWidth - 8;

      setState(() {
        _dragPosition = (_dragPosition + details.delta.dx)
            .clamp(0.0, maxSlideDistance);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isCompleted) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final containerWidth = renderBox.size.width;
      final sliderWidth = _getSliderWidth(containerWidth);
      final maxSlideDistance = containerWidth - sliderWidth - 8;

      if (_dragPosition > maxSlideDistance * 0.8) {
        // Slide completed
        setState(() {
          _dragPosition = maxSlideDistance;
          _isCompleted = true;
        });
        _animationController.forward();
        widget.onSlideComplete();
      } else {
        // Slide back to start
        _animationController.reverse().then((_) {
          setState(() {
            _dragPosition = 0;
          });
        });
      }
    }
  }

  // Calculate responsive slider width based on container width
  double _getSliderWidth(double containerWidth) {
    // Use 40% of container width but ensure minimum of 100 and maximum of 140
    return (containerWidth * 0.4).clamp(100.0, 140.0);
  }

  // Calculate responsive font size
  double _getFontSize(double sliderWidth) {
    // Scale font size based on slider width
    if (sliderWidth < 110) return 13.0;
    if (sliderWidth < 125) return 14.5;
    return 16.0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final sliderWidth = _getSliderWidth(containerWidth);
        final fontSize = _getFontSize(sliderWidth);
        
        return Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Stack(
            children: [
              // Arrow icons only in background
              Positioned.fill(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Arrow icons
                      ...List.generate(
                        5,
                        (index) => Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Icon(
                            Icons.chevron_right,
                            color: widget.textColor.withAlpha((0.3 * 255).round()),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              // Sliding button
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Positioned(
                    left: 4 + _dragPosition,
                    top: 4,
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: Container(
                        width: sliderWidth,
                        height: widget.height - 8,
                        decoration: BoxDecoration(
                          color: widget.sliderColor,
                          borderRadius: BorderRadius.circular(widget.borderRadius - 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((0.2 * 255).round()),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.black,
                                  size: 24,
                                )
                              : Text(
                                  widget.text,
                                  style: TextStyle(
                                    fontFamily: 'ClashDisplay',
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
