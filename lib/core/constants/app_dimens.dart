/// All layout dimensions, spacing, radii and sizes used across the app.
/// Change a value here and it propagates everywhere automatically.
class AppDimens {
  AppDimens._();

  // ── Spacing / Gap ──────────────────────────────────────────────────────────
  static const double spaceXxs  = 2;
  static const double spaceXs   = 4;
  static const double spaceSm   = 6;
  static const double spaceMd   = 8;
  static const double spaceLg   = 10;
  static const double spaceXl   = 12;
  static const double space14   = 14;
  static const double space16   = 16;
  static const double space20   = 20;
  static const double space24   = 24;
  static const double space28   = 28;
  static const double space32   = 32;
  static const double space40   = 40;
  static const double space56   = 56;

  // ── Border radii ──────────────────────────────────────────────────────────
  static const double radiusXs   = 4;
  static const double radiusSm   = 6;
  static const double radiusMd   = 10;
  static const double radiusLg   = 12;
  static const double radiusXl   = 14;
  static const double radiusCard = 18;
  static const double radiusSheet= 24;
  static const double radiusChip = 20;
  static const double radiusFull = 100; // fully rounded

  // ── Icon sizes ────────────────────────────────────────────────────────────
  static const double iconXs  = 11;
  static const double iconSm  = 14;
  static const double iconMd  = 16;
  static const double iconLg  = 18;
  static const double iconXl  = 20;
  static const double iconXxl = 24;
  static const double iconHero= 36;
  static const double iconEmp = 52;  // empty state illustration icon

  // ── Font sizes ────────────────────────────────────────────────────────────
  static const double fontXs   = 10;
  static const double fontSm   = 11;
  static const double fontMd   = 12;
  static const double fontBase = 13;
  static const double fontLg   = 14;
  static const double fontXl   = 16;

  // ── Component sizes ───────────────────────────────────────────────────────
  static const double thumbnailCard     = 56;   // task card thumbnail
  static const double thumbnailCardRad  = 14;   // thumbnail border radius
  static const double priorityDot       = 10;   // priority indicator dot
  static const double priorityDotBorder = 2;

  static const double deleteButtonSize  = 30;   // circular delete button
  static const double progressBarHeight = 5;    // card progress bar
  static const double progressBarHeightLg = 7;  // detail sheet progress bar
  static const double progressBarRadius = 6;

  static const double filterChipHeight  = 9;    // vertical padding
  static const double filterBadgePadH   = 7;
  static const double filterBadgePadV   = 2;

  static const double dragHandleWidth   = 40;
  static const double dragHandleHeight  = 4;

  static const double emptyStateIcon    = 120;  // container size
  static const double emptyStateDotWide = 20;   // wide dot in decorative row
  static const double emptyStateDotNarrow = 8;
  static const double emptyStateDotHeight = 8;

  static const double shimmerCardH1     = 88;
  static const double shimmerCardH2     = 96;
  static const double shimmerTitleH     = 14;
  static const double shimmerSubtitleH  = 10;
  static const double shimmerBarH       = 5;
  static const double shimmerSubtitleW  = 120;

  static const double subDetailRowH     = 220;  // hero image height
  static const double heroImageHeight   = 220;

  static const double actionBtnRadius   = 14;

  // ── Page / Section padding ─────────────────────────────────────────────────
  static const double pagePadH     = 16;  // horizontal page padding
  static const double pagePadV     = 20;  // vertical section padding
  static const double cardPad      = 14;  // card inner padding
  static const double formPadH     = 20;
  static const double formPadBottom = 24;

  static const double headerExpandedH = 130;  // SliverAppBar expandedHeight
  static const double listBottomPad   = 110;  // FAB clearance

  // ── App bar action buttons ────────────────────────────────────────────────
  static const double appBarBtnRadius  = 12;
  static const double appBarBtnMarginR = 4;
  static const double appBarBtnMarginRLast = 12;
  static const double appBarMenuOffset = 44;
  static const double appBarMenuRadius = 16;
  static const double appBarIconSize   = 20;
}
