import 'package:flutter/material.dart';

class AnimatedNotchedBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<NavBarItem> items;

  const AnimatedNotchedBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  }) : super(key: key);

  @override
  State<AnimatedNotchedBar> createState() => _AnimatedNotchedBarState();
}

class _AnimatedNotchedBarState extends State<AnimatedNotchedBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _expandController;
  late Animation<double> _slideAnimation;
  late Animation<double> _expandAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOut,
    );

    _previousIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(AnimatedNotchedBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _slideController.forward(from: 0);
      _expandController.forward(from: 0).then((_) {
        _expandController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  double _getIndicatorPosition(double itemWidth) {
    final from = _previousIndex < 2 ? _previousIndex : _previousIndex + 1;
    final to = widget.selectedIndex < 2
        ? widget.selectedIndex
        : widget.selectedIndex + 1;
    return (from * itemWidth) +
        ((to - from) * itemWidth * _slideAnimation.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 5;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Animated expanding circle indicator
          AnimatedBuilder(
            animation: Listenable.merge([_slideAnimation, _expandAnimation]),
            builder: (context, child) {
              final position = _getIndicatorPosition(itemWidth);
              final baseSize = 55.0;
              final expandSize = baseSize + (_expandAnimation.value * 15);

              return Positioned(
                left: position + (itemWidth / 2) - (expandSize / 2),
                top: -expandSize / 3,
                child: Container(
                  width: expandSize,
                  height: expandSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      widget.items[widget.selectedIndex].selectedIcon,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              );
            },
          ),

          // Bottom bar with notch
          ClipPath(
            clipper: NotchClipper(),
            child: Container(height: 70, color: theme.colorScheme.surface),
          ),

          // Navigation items
          Row(
            children: [
              for (int i = 0; i < 2; i++)
                _buildNavItem(
                  context,
                  widget.items[i],
                  i,
                  widget.selectedIndex == i,
                  itemWidth,
                ),

              SizedBox(width: itemWidth),

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
    NavBarItem item,
    int index,
    bool isSelected,
    double width,
  ) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onItemSelected(index),
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  opacity: isSelected ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    item.icon,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    size: 24,
                  ),
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
        ),
      ),
    );
  }
}

class NotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final notchRadius = 38.0;

    path.moveTo(0, 0);

    // Left side to notch
    path.lineTo(centerX - notchRadius - 20, 0);

    // Smooth curve into notch
    path.quadraticBezierTo(
      centerX - notchRadius - 10,
      0,
      centerX - notchRadius,
      notchRadius / 3,
    );

    // Arc for the notch
    path.arcToPoint(
      Offset(centerX + notchRadius, notchRadius / 3),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    // Smooth curve out of notch
    path.quadraticBezierTo(
      centerX + notchRadius + 10,
      0,
      centerX + notchRadius + 20,
      0,
    );

    // Right side
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(NotchClipper oldClipper) => false;
}

class NavBarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
