import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Material “compact” vs “medium+” style breakpoint: tablets, unfolded foldables.
const kTabletShortestSide = 600.0;

/// Minimum window width before showing navigation rail (with tablet shortest side).
const kNavRailMinWidth = 720.0;

/// Default width for two-column card grids (history, leaderboard).
const kWideColumnsMinWidth = 960.0;

/// Hero + side column, profile split layout.
const kWideLayoutMinWidth = 980.0;

/// Centered content column cap (matches existing ConstrainedBox usage).
const kContentMaxWidthTight = 980.0;

// --- Game / mission (Street View + guess map) ---

/// Guess map when collapsed (peek card in the corner).
({double width, double height}) gameMiniMapDimensions(bool isTabletLike) =>
    isTabletLike
        ? (width: 204.0, height: 156.0)
        : (width: 168.0, height: 128.0);

/// Expanded map height from available window — favors Street View on tablets, gives
/// more room to the map in split-screen / short chrome.
double gameExpandedMapHeight(Size size, {required bool isTabletLike}) {
  final h = size.height;
  if (h <= 1) return 200;
  var frac = isTabletLike ? 0.48 : 0.56;
  if (h < 420) {
    frac += 0.12;
  } else if (h < 520) {
    frac += 0.06;
  }
  frac = frac.clamp(0.45, 0.72);
  final cap = isTabletLike ? 540.0 : 430.0;
  return math.min(math.max(h * frac, 132.0), cap);
}

/// Clue + round HUD column.
double gameHudMaxWidth(double width, {required bool isTabletLike}) =>
    math.min(width * 0.9, isTabletLike ? 560.0 : 440.0);

/// Error / loading sheets.
double gameSheetMaxWidth(double width, {required bool isTabletLike}) =>
    math.min(width * (isTabletLike ? 0.88 : 0.92), isTabletLike ? 520.0 : 440.0);

/// Round score overlay.
double gameResultOverlayMaxWidth(double width, {required bool isTabletLike}) =>
    math.min(width * 0.95, isTabletLike ? 560.0 : 480.0);

/// Expanded guess map width (centered); caps width on large tablets.
double gameExpandedMapWidth(double width, {required bool isTabletLike}) {
  final raw = width - 32;
  if (width <= 0) return 200;
  final minW = isTabletLike ? 280.0 : 200.0;
  if (!isTabletLike) return math.max(raw, minW);
  return math.min(math.max(raw, minW), 880.0);
}

extension KuglaLayoutBreakpoints on BuildContext {
  Size get _size => MediaQuery.sizeOf(this);

  /// True for small tablets, iPads, unfolded inner displays — not landscape phones.
  bool get isTabletLikeLayout =>
      _size.shortestSide >= kTabletShortestSide;

  /// Side nav only when the window reads as a tablet/large screen and is wide enough.
  bool get useNavigationRailLayout =>
      isTabletLikeLayout && _size.width >= kNavRailMinWidth;

  /// Extra horizontal inset on large tablets to keep a readable column (~680dp).
  double get centeredContentHorizontalPadding {
    final w = _size.width;
    if (!isTabletLikeLayout || w <= 720) return 20.0;
    return ((w - 680) / 2).clamp(20.0, 240.0);
  }

  /// Multi-column lists / wrap grids when local width allows (parent [LayoutBuilder]).
  bool wideColumnsFor(double maxWidth,
          {double minWidth = kWideColumnsMinWidth}) =>
      isTabletLikeLayout && maxWidth >= minWidth;
}
