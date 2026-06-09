
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/unit_system.dart';
import '../cubits/tracking_cubit.dart';
import '../cubits/compass_cubit.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  DensityUnit _densityUnit = DensityUnit.gcm3;
  LengthUnit  _lengthUnit  = LengthUnit.metric;
  double _spacing   = 5.0;
  double _minAcc    = 15.0;
  double _northManual = 0.0;

  @override
  void initState() {
    super.initState();
    final state = context.read<TrackingCubit>().state;
    if (state is TrackingReady) {
      _densityUnit = state.unitSystem.densityUnit;
      _lengthUnit  = state.unitSystem.lengthUnit;
      _spacing = state.unitSystem.lengthFromMeters(state.spacingM);
      _minAcc  = state.minAccuracy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        actions: [
          FilledButton.tonal(
            onPressed: _save,
            child: const Text('حفظ'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'نظام الوحدات', icon: Icons.straighten),
          const SizedBox(height: 12),

          _settingCard(
            title: 'وحدة الكثافة',
            subtitle: 'تُستخدم لإدخال أقصى كثافة معملية',
            child: DropdownButtonFormField<DensityUnit>(
              value: _densityUnit,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: const [
                DropdownMenuItem(value: DensityUnit.gcm3, child: Text('g/cm³ — جرام/سنتيمتر مكعب')),
                DropdownMenuItem(value: DensityUnit.kgm3, child: Text('kg/m³ — كيلوجرام/متر مكعب')),
                DropdownMenuItem(value: DensityUnit.knm3, child: Text('kN/m³ — كيلونيوتن/متر مكعب')),
                DropdownMenuItem(value: DensityUnit.pcf,  child: Text('lb/ft³ — رطل/قدم مكعب')),
              ],
              onChanged: (v) => setState(() => _densityUnit = v!),
            ),
          ),
          const SizedBox(height: 10),

          _settingCard(
            title: 'وحدة الطول',
            subtitle: 'تُستخدم لضبط مسافة التباعد',
            child: SegmentedButton<LengthUnit>(
              selected: {_lengthUnit},
              onSelectionChanged: (s) => setState(() => _lengthUnit = s.first),
              segments: const [
                ButtonSegment(value: LengthUnit.metric,   label: Text('متري (m)')),
                ButtonSegment(value: LengthUnit.imperial, label: Text('إمبراطوري (ft)')),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const SectionHeader(title: 'إعدادات GPS', icon: Icons.gps_fixed),
          const SizedBox(height: 12),

          _settingCard(
            title: 'مسافة التباعد بين النقاط',
            subtitle: 'عند تجاوز هذه المسافة تُسجَّل نقطة جديدة',
            child: Row(children: [
              Expanded(child: Slider(
                value: _spacing,
                min: 1,
                max: _lengthUnit == LengthUnit.metric ? 50 : 164,
                divisions: 99,
                onChanged: (v) => setState(() => _spacing = v),
              )),
              Text(
                '${_spacing.toStringAsFixed(1)} ${_lengthUnit == LengthUnit.metric ? "م" : "قدم"}',
                style: tt.labelMedium?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w700),
              ),
            ]),
          ),
          const SizedBox(height: 10),

          _settingCard(
            title: 'حد دقة GPS المقبولة',
            subtitle: 'تُسجَّل النقطة فقط إذا كانت الدقة ≤ هذه القيمة',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Slider(
                  value: _minAcc,
                  min: 3, max: 50, divisions: 47,
                  onChanged: (v) => setState(() => _minAcc = v),
                )),
                Text(
                  '${_minAcc.toStringAsFixed(0)} م',
                  style: tt.labelMedium?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w700),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(
                  _minAcc <= 20 ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                  size: 14,
                  color: _minAcc <= 10 ? AppTheme.success
                       : _minAcc <= 20 ? AppTheme.info
                       : AppTheme.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  _minAcc <= 10 ? 'دقة عالية جداً'
                      : _minAcc <= 20 ? 'دقة جيدة'
                      : 'دقة منخفضة',
                  style: tt.bodySmall?.copyWith(
                    color: _minAcc <= 10 ? AppTheme.success
                         : _minAcc <= 20 ? AppTheme.info
                         : AppTheme.warning,
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          const SectionHeader(title: 'معايرة اتجاه الشمال', icon: Icons.explore),
          const SizedBox(height: 12),

          BlocBuilder<CompassCubit, CompassState>(
            builder: (_, state) {
              double heading = 0;
              bool locked = false;
              if (state is CompassReading) {
                heading = state.heading;
                locked  = state.isLocked;
              }
              return _settingCard(
                title: 'البوصلة',
                subtitle: 'ضبط اتجاه الشمال لمطابقة الخريطة مع الواقع',
                child: Column(children: [
                  Center(
                    child: Stack(alignment: Alignment.center, children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: locked ? AppTheme.success : cs.outlineVariant,
                            width: 2,
                          ),
                          color: cs.surfaceContainerHighest,
                        ),
                      ),
                      Transform.rotate(
                        angle: heading * 3.14159265 / 180,
                        child: Icon(Icons.navigation,
                            size: 48, color: cs.error),
                      ),
                      Positioned(
                        top: 8,
                        child: Text('N',
                          style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: locked ? AppTheme.success : cs.onSurface,
                          )),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(
                      locked ? Icons.lock_outline : Icons.lock_open_outlined,
                      size: 14,
                      color: locked ? AppTheme.success : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'الاتجاه: ${heading.toStringAsFixed(1)}°  ${locked ? "مقفل" : "حر"}',
                      style: tt.bodySmall?.copyWith(
                        color: locked ? AppTheme.success : cs.onSurfaceVariant,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: FilledButton.icon(
                      onPressed: () => context.read<CompassCubit>().lockHeading(),
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: const Text('قفّل الاتجاه'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.black,
                      ),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () => context.read<CompassCubit>().unlock(),
                      icon: const Icon(Icons.lock_open_outlined, size: 16),
                      label: const Text('إلغاء القفل'),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'أو أدخل الزاوية يدوياً (0-360°)',
                        isDense: true,
                      ),
                      onChanged: (v) => _northManual = double.tryParse(v) ?? 0,
                    )),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () => context
                          .read<CompassCubit>()
                          .setManualHeading(_northManual),
                      child: const Text('ضبط'),
                    ),
                  ]),
                ]),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _settingCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          child,
        ]),
      ),
    );
  }

  void _save() {
    final us = UnitSystem(densityUnit: _densityUnit, lengthUnit: _lengthUnit);
    final spacingM = us.lengthToMeters(_spacing);
    context.read<TrackingCubit>().updateSettings(
      unitSystem: us, spacingM: spacingM, minAccuracy: _minAcc,
    );
    final compassState = context.read<CompassCubit>().state;
    if (compassState is CompassReading) {
      context.read<TrackingCubit>().updateSettings(northDeg: compassState.heading);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('تم حفظ الإعدادات'),
      backgroundColor: AppTheme.success,
    ));
    Navigator.pop(context);
  }
}
