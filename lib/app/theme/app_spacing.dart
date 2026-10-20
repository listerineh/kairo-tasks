class AppSpacing {
  AppSpacing._();

  // Base spacing unit: 4px
  static const double spacing2 = 2;
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  static const double spacing40 = 40;
  static const double spacing48 = 48;
  static const double spacing64 = 64;

  // Border radii
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;
  static const double radiusFull = 999;

  // Touch targets (WCAG minimum 44x44)
  static const double minTouchTarget = 44;
  static const double buttonHeight = 48;
  static const double iconButtonSize = 44;

  // Kairo 2.0 layout (docs/redesign-plan.md §2.3): a radius hierarchy instead
  // of one radius everywhere. Buttons are capsules, avatars circles.
  static const double screenMargin = 16;
  static const double radiusRow = 10;
  static const double radiusSheet = 12;
  static const double radiusCard = 16;
  static const double hairline = 0.5;

  // Content max width (for tablets/landscape)
  static const double maxContentWidth = 600;
}
