
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';




class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;
  final Widget? trailing;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  label,
                  style: tt.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: 6),
            Text(
              value,
              style: tt.titleLarge?.copyWith(
                color: valueColor ?? cs.primary,
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class GpsAccuracyWidget extends StatelessWidget {
  final double accuracy;
  final double threshold;
  const GpsAccuracyWidget({super.key, required this.accuracy, required this.threshold});

  @override
  Widget build(BuildContext context) {
    final good = accuracy <= threshold;
    final color = good ? AppTheme.success : AppTheme.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(good ? Icons.gps_fixed : Icons.gps_not_fixed, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          '${accuracy.toStringAsFixed(1)} م',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}




class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.icon, this.action});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(
          width: 3, height: 20,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        if (icon != null) ...[
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            title,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (action != null) action!,
      ]),
    );
  }
}




class ColorLegendWidget extends StatelessWidget {
  const ColorLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const ranges = [
      (Color(0xFF67001F), '< 60%', 'خطر شديد'),
      (Color(0xFFB2182B), '60-70%', 'ضعيف جداً'),
      (Color(0xFFD6604D), '70-80%', 'ضعيف'),
      (Color(0xFFF4A582), '80-85%', 'مقبول مشروط'),
      (Color(0xFFD9EF8B), '85-90%', 'متوسط'),
      (Color(0xFFA6D96A), '90-93%', 'جيد'),
      (Color(0xFF65BD63), '93-95%', 'جيد جداً'),
      (Color(0xFF1A7837), '95-100%', 'مثالي'),
      (Color(0xFF4393C3), '100-103%', 'مفرط'),
      (Color(0xFF2166AC), '> 103%', 'مفرط شديد'),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ranges
          .map((r) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: r.$1,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${r.$2}\n${r.$3}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ))
          .toList(),
    );
  }
}




class LoadingOverlay extends StatelessWidget {
  final String message;
  const LoadingOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: cs.primary),
              const SizedBox(height: 20),
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
            ]),
          ),
        ),
      ),
    );
  }
}




class LiveIndicator extends StatefulWidget {
  const LiveIndicator({super.key});
  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(0.1 + 0.08 * _anim.value),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.success.withOpacity(0.4 * _anim.value)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(_anim.value),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'مباشر',
            style: TextStyle(
              color: AppTheme.success,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ]),
      ),
    );
  }
}
