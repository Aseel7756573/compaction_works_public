
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  
  static const Color _seed = Color(0xFF1565C0);

  
  static const Color primary       = Color(0xFF94CCFF);
  static const Color primaryDark   = Color(0xFF004880);
  static const Color surface       = Color(0xFF0F1923);
  static const Color background    = Color(0xFF0F1923);
  static const Color card          = Color(0xFF19222E);
  static const Color border        = Color(0xFF2A3547);
  static const Color textPrimary   = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF8FA3BF);
  static const Color success       = Color(0xFF4ADE80);
  static const Color danger        = Color(0xFFF87171);
  static const Color warning       = Color(0xFFFBBF24);
  static const Color info          = Color(0xFF60A5FA);
  static const Color over          = Color(0xFF34D399);

  static ThemeData get dark {
    final cs = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: cs);

    return base.copyWith(
      scaffoldBackgroundColor: cs.surface,
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).copyWith(
        displayLarge:   GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.w900, color: cs.onSurface),
        headlineLarge:  GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w800, color: cs.onSurface),
        headlineMedium: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface),
        headlineSmall:  GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
        titleLarge:     GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
        titleMedium:    GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
        titleSmall:     GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
        bodyLarge:      GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w400, color: cs.onSurface),
        bodyMedium:     GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant),
        bodySmall:      GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant),
        labelLarge:     GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
        labelMedium:    GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurface),
        labelSmall:     GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        scrolledUnderElevation: 2,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface,
        ),
        iconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 22),
        actionsIconTheme: IconThemeData(color: cs.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        surfaceTintColor: cs.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
          side: BorderSide(color: cs.outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.cairo(fontSize: 13, color: cs.onSurfaceVariant),
        hintStyle: GoogleFonts.cairo(fontSize: 12, color: cs.onSurfaceVariant),
        floatingLabelStyle: GoogleFonts.cairo(fontSize: 13, color: cs.primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 3,
        backgroundColor: cs.surfaceContainer,
        indicatorColor: cs.primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? cs.onSurface : cs.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            size: 22,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.cairo(fontSize: 13),
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: cs.onSurfaceVariant,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: GoogleFonts.cairo(fontSize: 12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 6,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface,
        ),
        contentTextStyle: GoogleFonts.cairo(
          fontSize: 14, color: cs.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: cs.onSurfaceVariant.withOpacity(0.4),
        elevation: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.onPrimary : cs.outline),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.primary : cs.surfaceVariant),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: cs.primary,
        thumbColor: cs.primary,
        inactiveTrackColor: cs.surfaceVariant,
        overlayColor: cs.primary.withOpacity(0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceVariant,
        circularTrackColor: cs.surfaceVariant,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        elevation: 3,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

extension ContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.of(this).size;
  bool get isRTL => Directionality.of(this) == TextDirection.rtl;
}
