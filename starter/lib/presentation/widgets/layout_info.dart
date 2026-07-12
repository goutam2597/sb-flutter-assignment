import '../../theme/app_theme.dart';

/// Central responsive breakpoints for the whole console screen.
class Breakpoints {
  static const double compact = 600; // phones
  static const double medium = 905; // large phones / small tablets
  static const double expanded = 1240; // tablets landscape / desktop
  static const double large = 1600; // wide desktop
}

/// Small immutable helper that derives everything layout-related from width.
class LayoutInfo {
  const LayoutInfo(this.width);

  final double width;

  bool get isCompact => width < Breakpoints.compact;
  bool get isMedium =>
      width >= Breakpoints.compact && width < Breakpoints.medium;
  bool get isExpanded =>
      width >= Breakpoints.medium && width < Breakpoints.expanded;
  bool get isLarge => width >= Breakpoints.expanded;

  /// A persistent sidebar only makes sense once we have real horizontal room.
  bool get showSidebar => width >= Breakpoints.medium;

  /// Number of metric cards per row.
  int get metricColumns {
    if (width < 500) return 2;
    if (width < Breakpoints.medium) return 2;
    if (width < Breakpoints.expanded) return 4;
    return 4;
  }

  double get sidebarWidth => width >= Breakpoints.large ? 420 : 360;

  double get contentMaxWidth => width >= Breakpoints.large ? 1480 : 1320;

  double get horizontalPadding {
    if (isCompact) return Spacing.sm;
    if (isMedium) return Spacing.lg;
    return Spacing.xl;
  }
}
