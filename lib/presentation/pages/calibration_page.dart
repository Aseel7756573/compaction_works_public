
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/compaction_model.dart';
import '../../core/utils/unit_system.dart';
import '../../data/datasources/gps_datasource.dart';
import '../cubits/tracking_cubit.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../../core/utils/color_system.dart';

class CalibrationPage extends StatefulWidget {
  const CalibrationPage({super.key});
  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  final _formKey = GlobalKey<FormState>();

  final _refLatCtrl = TextEditingController(text: '13.96333');
  final _refLonCtrl = TextEditingController(text: '44.58194');

  double _maxDryDensity  = 1.85;
  double _omc            = 12.5;
  String _soilType       = 'رملية';
  double _initialComp    = 78.0;
  int    _refPasses      = 8;
  double _finalComp      = 98.5;
  double _moistureBefore = 11.2;
  double _moistureAfter  = 12.1;
  double _equipEff       = 1.0;
  double _targetMin      = 95.0;
  double _targetMax      = 100.0;
  bool   _loadingGps     = false;

  @override
  void dispose() {
    _refLatCtrl.dispose();
    _refLonCtrl.dispose();
    super.dispose();
  }

  UnitSystem get _us {
    final state = context.read<TrackingCubit>().state;
    return state is TrackingReady ? state.unitSystem : const UnitSystem();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المعايرة المرجعية'),
        actions: [
          FilledButton.tonal(
            onPressed: _confirm,
            child: const Text('تأكيد'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            
            Card(
              color: cs.tertiaryContainer.withOpacity(0.6),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Icon(Icons.info_outline, color: cs.tertiary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'هذه الخطوة أساسية — بدونها لن تكون النتائج دقيقة',
                      style: tt.bodySmall?.copyWith(color: cs.onTertiaryContainer),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            
            const SectionHeader(title: 'النقطة المرجعية', icon: Icons.location_on_outlined),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [
                    Expanded(child: TextFormField(
                      controller: _refLatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: _validateCoord,
                      decoration: const InputDecoration(labelText: 'خط العرض (Latitude)'),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: TextFormField(
                      controller: _refLonCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: _validateCoord,
                      decoration: const InputDecoration(labelText: 'خط الطول (Longitude)'),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loadingGps ? null : _getGpsLocation,
                      icon: _loadingGps
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location, size: 16),
                      label: Text(_loadingGps ? 'جاري تحديد الموقع...' : 'استخدام موقعي الحالي'),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            
            const SectionHeader(title: 'البيانات المعملية (Proctor)', icon: Icons.science_outlined),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _densityField(),
                  const SizedBox(height: 12),
                  _sliderRow('المحتوى الرطوبي الأمثل OMC (%)', _omc, 4, 35,
                      (v) => setState(() => _omc = v)),
                  const SizedBox(height: 12),
                  _dropdownRow('نوع التربة', _soilType,
                      ['رملية', 'طينية', 'غرينية', 'صخرية مكسرة', 'رملية طينية'],
                      (v) => setState(() => _soilType = v!)),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            
            const SectionHeader(title: 'قيم المعايرة الحقلية', icon: Icons.analytics_outlined),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _sliderRow('معامل الدمك الأولي (قبل الدمك) %', _initialComp, 40, 95,
                      (v) => setState(() => _initialComp = v)),
                  const SizedBox(height: 8),
                  _intSliderRow('عدد دورات الدمك المرجعية', _refPasses, 1, 50,
                      (v) => setState(() => _refPasses = v.round())),
                  const SizedBox(height: 8),
                  _sliderRow('معامل الدمك النهائي (بعد الدمك) %', _finalComp, 80, 105,
                      (v) => setState(() => _finalComp = v)),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            
            const SectionHeader(title: 'الرطوبة وكفاءة المعدة', icon: Icons.water_drop_outlined),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _sliderRow('الرطوبة الحقلية قبل الدمك (%)', _moistureBefore, 2, 40,
                      (v) => setState(() => _moistureBefore = v)),
                  const SizedBox(height: 8),
                  _sliderRow('الرطوبة الحقلية بعد الدمك (%)', _moistureAfter, 2, 40,
                      (v) => setState(() => _moistureAfter = v)),
                  const SizedBox(height: 8),
                  _equipEffRow(),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            
            const SectionHeader(title: 'معامل الدمك المستهدف', icon: Icons.track_changes_outlined),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _sliderRow('الحد الأدنى المقبول (%)', _targetMin, 85, 100,
                      (v) => setState(() => _targetMin = v)),
                  const SizedBox(height: 8),
                  _sliderRow('حد الدمك المفرط (%)', _targetMax, 95, 110,
                      (v) => setState(() => _targetMax = v)),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            
            if (_canPreview) ...[
              const SectionHeader(title: 'معاينة النموذج الهندسي', icon: Icons.preview_outlined),
              const SizedBox(height: 12),
              _buildPreview(),
              const SizedBox(height: 20),
            ],

            
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('تأكيد المعايرة وبدء العمل'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canPreview => _finalComp > _initialComp;

  Widget _buildPreview() {
    final cs = Theme.of(context).colorScheme;
    final model = CompactionModel(CalibrationData(
      refLat: double.tryParse(_refLatCtrl.text) ?? 0,
      refLon: double.tryParse(_refLonCtrl.text) ?? 0,
      maxDryDensityGcm3: _maxDryDensity,
      omc: _omc,
      soilType: _soilType,
      initialCompaction: _initialComp,
      refPasses: _refPasses,
      finalCompaction: _finalComp,
      moistureBefore: _moistureBefore,
      moistureAfter: _moistureAfter,
      equipmentEfficiency: _equipEff,
      targetMin: _targetMin,
      targetMax: _targetMax,
    ));

    return Card(
      color: cs.primaryContainer.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'معامل الدمك المتوقع حسب عدد الدورات',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [2, 4, 6, 8, 10, 12, 16].map((n) {
              final c = model.predict(n, _omc);
              final color = CompactionColorSystem.getColor(c);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$n دورات\n${c.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  

  Widget _densityField() {
    final rng = _us.densityRange;
    final converted = _us.densityFromSI(_maxDryDensity);
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(
            'أقصى كثافة معملية - Proctor (${_us.densityLabel})',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Text(
          '${converted.toStringAsFixed(3)} ${_us.densityLabel}',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ]),
      Slider(
        value: converted.clamp(rng.$1, rng.$2),
        min: rng.$1,
        max: rng.$2,
        onChanged: (v) => setState(() => _maxDryDensity = _us.densityToSI(v)),
      ),
      Text(
        'النطاق: ${rng.$1} – ${rng.$2} ${_us.densityLabel}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ]);
  }

  Widget _sliderRow(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ]),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: ((max - min) * 10).round(),
        onChanged: onChanged,
      ),
    ]);
  }

  Widget _intSliderRow(String label, int value, int min, int max,
      ValueChanged<double> onChanged) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Text(
          '$value دورات',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ]),
      Slider(
        value: value.toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: max - min,
        onChanged: onChanged,
      ),
    ]);
  }

  Widget _equipEffRow() {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(
            'كفاءة المعدة (0.1 – 10)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Text(
          _equipEff.toStringAsFixed(1),
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ]),
      Slider(
        value: _equipEff,
        min: 0.1,
        max: 10,
        divisions: 99,
        onChanged: (v) =>
            setState(() => _equipEff = double.parse(v.toStringAsFixed(1))),
      ),
      Text(
        '10 = معدة جديدة تماماً  |  0.1 = تهالك شديد',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ]);
  }

  Widget _dropdownRow(
      String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Row(children: [
      Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
      DropdownButton<String>(
        value: value,
        items: items
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: onChanged,
        dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 13,
        ),
        underline: const SizedBox(),
      ),
    ]);
  }

  String? _validateCoord(String? v) {
    if (v == null || v.isEmpty) return 'مطلوب';
    if (double.tryParse(v) == null) return 'رقم غير صحيح';
    return null;
  }

  Future<void> _getGpsLocation() async {
    setState(() => _loadingGps = true);
    try {
      final gps = GpsDatasource();
      await gps.requestPermission();
      final pos = await gps.getCurrentPosition();
      _refLatCtrl.text = pos.latitude.toStringAsFixed(8);
      _refLonCtrl.text = pos.longitude.toStringAsFixed(8);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم تحديد الموقع — دقة: ${pos.accuracy.toStringAsFixed(1)} م'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      setState(() => _loadingGps = false);
    }
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    if (_finalComp <= _initialComp) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('معامل الدمك النهائي يجب أن يكون أكبر من الأولي'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }

    context.read<TrackingCubit>().setCalibration(CalibrationData(
      refLat: double.parse(_refLatCtrl.text),
      refLon: double.parse(_refLonCtrl.text),
      maxDryDensityGcm3: _maxDryDensity,
      omc: _omc,
      soilType: _soilType,
      initialCompaction: _initialComp,
      refPasses: _refPasses,
      finalCompaction: _finalComp,
      moistureBefore: _moistureBefore,
      moistureAfter: _moistureAfter,
      equipmentEfficiency: _equipEff,
      targetMin: _targetMin,
      targetMax: _targetMax,
    ));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('تم حفظ المعايرة — النموذج الهندسي جاهز'),
      backgroundColor: AppTheme.success,
    ));
    Navigator.pop(context);
  }
}
