import 'package:flutter/material.dart';

class NotchedBottomBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<BottomNavItem> items;
  final Widget? floatingActionButton;

  const NotchedBottomBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  State<NotchedBottomBar> createState() => _NotchedBottomBarState();
}

class _NotchedBottomBarState extends State<NotchedBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _previousIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(NotchedBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _getIndicatorPosition(double itemWidth) {
    final from = _previousIndex < 2 ? _previousIndex : _previousIndex + 1;
    final to = widget.selectedIndex < 2
        ? widget.selectedIndex
        : widget.selectedIndex + 1;
    return (from * itemWidth) + ((to - from) * itemWidth * _animation.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 5; // 5 items including center space

    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated circular indicator
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final position = _getIndicatorPosition(itemWidth);

              return Positioned(
                left: position + (itemWidth / 2) - 30,
                top: 5,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withOpacity(0.15),
                  ),
                ),
              );
            },
          ),

          // Bottom bar with notch
          ClipPath(
            clipper: BottomBarClipper(),
            child: Container(height: 65, color: theme.colorScheme.surface),
          ),

          // Navigation items
          Row(
            children: [
              // Left items (0, 1)
              for (int i = 0; i < 2; i++)
                _buildNavItem(
                  context,
                  widget.items[i],
                  i,
                  widget.selectedIndex == i,
                  itemWidth,
                ),

              // Center space for FAB
              SizedBox(width: itemWidth),

              // Right items (2, 3)
              for (int i = 2; i < widget.items.length; i++)
                _buildNavItem(
                  context,
                  widget.items[i],
                  i,
                  widget.selectedIndex == i,
                  itemWidth,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    BottomNavItem item,
    int index,
    bool isSelected,
    double width,
  ) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => widget.onItemSelected(index),
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 250),
              tween: Tween(begin: 1.0, end: isSelected ? 1.15 : 1.0),
              curve: Curves.easeOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    size: 24,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final notchRadius = 35.0;
    final notchMargin = 8.0;

    path.moveTo(0, 0);
    path.lineTo(centerX - notchRadius - notchMargin, 0);

    // Create smooth notch curve
    path.quadraticBezierTo(
      centerX - notchRadius - notchMargin,
      0,
      centerX - notchRadius,
      notchRadius / 2,
    );

    path.arcToPoint(
      Offset(centerX + notchRadius, notchRadius / 2),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    path.quadraticBezierTo(
      centerX + notchRadius + notchMargin,
      0,
      centerX + notchRadius + notchMargin,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(BottomBarClipper oldClipper) => false;
}

class BottomNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
