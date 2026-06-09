
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/utils/color_system.dart';
import '../../domain/entities/compaction_point.dart';
import '../cubits/tracking_cubit.dart';
import '../cubits/projects_cubit.dart';
import '../cubits/export_cubit.dart';
import '../cubits/compass_cubit.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/heatmap_widget.dart';
import 'calibration_page.dart';
import 'settings_page.dart';
import '../../core/utils/unit_system.dart';
import '../../core/utils/compaction_model.dart';
import 'projects_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    context.read<CompassCubit>().startListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildNavigationBar(),
      floatingActionButton: _buildFAB(),
    );
  }

  
  
  
  AppBar _buildAppBar() {
    return AppBar(
      title: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'FMA',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('Compaction Pro',
            style: Theme.of(context).textTheme.titleLarge),
      ]),
      actions: [
        
        BlocBuilder<CompassCubit, CompassState>(
          builder: (_, state) {
            if (state is CompassReading) {
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Chip(
                  avatar: Icon(
                    Icons.explore,
                    size: 14,
                    color: state.isLocked ? AppTheme.success : AppTheme.warning,
                  ),
                  label: Text(
                    '${state.heading.toStringAsFixed(0)}°',
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }
            return const SizedBox();
          },
        ),
        IconButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProjectsPage())),
          icon: const Icon(Icons.folder_outlined),
          tooltip: 'المشاريع',
        ),
        IconButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsPage())),
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'الإعدادات',
        ),
      ],
    );
  }

  
  
  
  Widget _buildBody() {
    return BlocConsumer<TrackingCubit, TrackingState>(
      listener: (ctx, state) {
        if (state is TrackingError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            action: SnackBarAction(
              label: 'الإعدادات',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsPage())),
            ),
          ));
        }
      },
      builder: (ctx, state) => IndexedStack(
        index: _selectedTab,
        children: [
          _buildTrackingTab(state),
          _buildMapTab(state),
          _buildStatsTab(state),
        ],
      ),
    );
  }

  
  
  
  Widget _buildNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedTab,
      onDestinationSelected: (i) => setState(() => _selectedTab = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.sensors_outlined),
          selectedIcon: Icon(Icons.sensors),
          label: 'التتبع',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'الخريطة',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'الإحصائيات',
        ),
      ],
    );
  }

  
  
  
  Widget _buildFAB() {
    return BlocBuilder<TrackingCubit, TrackingState>(
      builder: (_, state) {
        final isActive = state is TrackingActive;
        return FloatingActionButton.extended(
          onPressed: isActive
              ? () => context.read<TrackingCubit>().stopTracking()
              : () => context.read<TrackingCubit>().startTracking(),
          backgroundColor: isActive ? AppTheme.danger : AppTheme.success,
          foregroundColor: isActive ? Colors.white : Colors.black87,
          icon: Icon(isActive ? Icons.stop_rounded : Icons.play_arrow_rounded),
          label: Text(
            isActive ? 'إيقاف' : 'بدء',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          elevation: 2,
        );
      },
    );
  }

  
  
  
  Widget _buildTrackingTab(TrackingState state) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildStatusBanner(state),
              const SizedBox(height: 16),
              if (_hasPoints(state)) ...[
                _buildStatsGrid(_getPoints(state)),
                const SizedBox(height: 16),
              ],
              _buildControlButtons(state),
              if (state is TrackingActive) ...[
                const SizedBox(height: 16),
                _buildGpsInfo(state),
              ],
              if (_hasPoints(state)) ...[
                const SizedBox(height: 20),
                SectionHeader(
                  title: 'آخر النقاط المسجلة',
                  action: TextButton(
                    onPressed: () => setState(() => _selectedTab = 2),
                    child: const Text('عرض الكل'),
                  ),
                ),
                const SizedBox(height: 10),
                ..._getPoints(state).reversed.take(5).map(_buildPointTile),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  
  Widget _buildStatusBanner(TrackingState state) {
    if (state is TrackingInitial) {
      return _statusCard(
        icon: Icons.tune_rounded,
        color: AppTheme.warning,
        title: 'المعايرة مطلوبة',
        subtitle: 'أدخل بيانات المعايرة المرجعية لبدء العمل',
        action: FilledButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CalibrationPage())),
          icon: const Icon(Icons.tune, size: 16),
          label: const Text('إعداد المعايرة'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.warning,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
    if (state is TrackingActive) {
      return _statusCard(
        icon: Icons.sensors,
        color: AppTheme.success,
        title: 'التتبع نشط',
        subtitle: '${_getPoints(state).length} نقطة مسجلة',
        action: const LiveIndicator(),
      );
    }
    if (state is TrackingReady) {
      return _statusCard(
        icon: Icons.check_circle_outline,
        color: AppTheme.primary,
        title: 'جاهز للتتبع',
        subtitle: 'نوع التربة: ${state.calibration.soilType} | هدف: ${state.calibration.targetMin}%',
        action: TextButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CalibrationPage())),
          child: const Text('تعديل'),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _statusCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      child: IntrinsicHeight(
        child: Row(children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: tt.titleSmall
                              ?.copyWith(color: color, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: tt.bodySmall),
                    ],
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 8),
                  action,
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  
  Widget _buildStatsGrid(List<CompactionPoint> points) {
    final stats = CompactionStats.fromPoints(points);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.1,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        StatCard(
          label: 'إجمالي النقاط',
          value: stats.total.toString(),
          icon: Icons.location_on_outlined,
        ),
        StatCard(
          label: 'متوسط الدمك',
          value: '${stats.average.toStringAsFixed(1)}%',
          valueColor: CompactionColorSystem.getColor(stats.average),
        ),
        StatCard(
          label: 'مقبول',
          value: '${stats.goodCount} (${stats.passRate.toStringAsFixed(1)}%)',
          valueColor: AppTheme.success,
          icon: Icons.check_circle_outline,
        ),
        StatCard(
          label: 'خارج الحد',
          value: '${stats.poorCount + stats.overCount}',
          valueColor: AppTheme.danger,
          icon: Icons.cancel_outlined,
        ),
      ],
    );
  }

  
  Widget _buildControlButtons(TrackingState state) {
    final isActive  = state is TrackingActive;
    final isReady   = state is TrackingReady;
    final hasPoints = _hasPoints(state);

    return Column(children: [
      
      SizedBox(
        width: double.infinity,
        child: !isActive
            ? FilledButton.icon(
                onPressed: (isReady || hasPoints)
                    ? () => context.read<TrackingCubit>().startTracking()
                    : () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CalibrationPage())),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('بدء التتبع التلقائي'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            : FilledButton.icon(
                onPressed: () => context.read<TrackingCubit>().stopTracking(),
                icon: const Icon(Icons.stop_rounded),
                label: const Text('إيقاف التتبع'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
      ),
      const SizedBox(height: 10),
      
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CalibrationPage())),
            icon: const Icon(Icons.tune, size: 15),
            label: const Text('معايرة', overflow: TextOverflow.ellipsis),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
          ),
        ),
        if (hasPoints) ...[
          const SizedBox(width: 6),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _showSaveDialog(state),
              icon: const Icon(Icons.save_outlined, size: 15),
              label: const Text('حفظ', overflow: TextOverflow.ellipsis),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showExportDialog(state),
              icon: const Icon(Icons.ios_share_outlined, size: 15),
              label: const Text('تصدير', overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
        ],
      ]),
      if (hasPoints) ...[
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _confirmClear,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('مسح جميع النقاط'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.danger,
              side: const BorderSide(color: AppTheme.danger),
            ),
          ),
        ),
      ],
    ]);
  }

  
  Widget _buildGpsInfo(TrackingActive state) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.gps_fixed, color: AppTheme.success, size: 16),
            const SizedBox(width: 6),
            Text('بيانات GPS الحالية',
                style: tt.titleSmall?.copyWith(color: AppTheme.success)),
            const Spacer(),
            GpsAccuracyWidget(
                accuracy: state.currentAcc, threshold: state.minAccuracy),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _gpsChip('خط العرض', state.currentLat.toStringAsFixed(7))),
            const SizedBox(width: 8),
            Expanded(child: _gpsChip('خط الطول', state.currentLon.toStringAsFixed(7))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Icon(
              state.currentAcc > state.minAccuracy
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              size: 14,
              color: state.currentAcc > state.minAccuracy
                  ? AppTheme.warning
                  : AppTheme.success,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                state.currentAcc > state.minAccuracy
                    ? 'الدقة ضعيفة — انتظر تحسن إشارة GPS (${state.currentAcc.toStringAsFixed(0)} م > ${state.minAccuracy.toStringAsFixed(0)} م)'
                    : 'دقة GPS جيدة — التسجيل التلقائي نشط',
                style: TextStyle(
                  fontSize: 11,
                  color: state.currentAcc > state.minAccuracy
                      ? AppTheme.warning
                      : AppTheme.success,
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _gpsChip(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
      ]),
    );
  }

  
  Widget _buildPointTile(CompactionPoint p) {
    final color = CompactionColorSystem.getColor(p.compactionPercent);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Center(
            child: Text(
              p.compactionPercent.toStringAsFixed(0),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ),
        title: Text(p.pointId,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          'دورات: ${p.passes} | رطوبة: ${p.moistureField.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          CompactionColorSystem.getStatusText(p.compactionPercent),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }

  
  
  
  Widget _buildMapTab(TrackingState state) {
    final points      = _getPoints(state);
    final calibration = _getCalibration(state);
    final northDeg    = _getNorthDeg(state);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(children: [
        HeatmapWidget(
          points: points,
          refLat: calibration?.refLat,
          refLon: calibration?.refLon,
          northDeg: northDeg,
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'مفتاح الألوان', icon: Icons.palette_outlined),
        const SizedBox(height: 12),
        const ColorLegendWidget(),
        const SizedBox(height: 24),
      ]),
    );
  }

  
  
  
  Widget _buildStatsTab(TrackingState state) {
    final points = _getPoints(state);

    if (points.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bar_chart_outlined,
              size: 64, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('لا توجد بيانات بعد',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
        ]),
      );
    }

    final stats = CompactionStats.fromPoints(points);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.9,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            StatCard(
              label: 'المتوسط',
              value: '${stats.average.toStringAsFixed(2)}%',
              valueColor: CompactionColorSystem.getColor(stats.average),
            ),
            StatCard(
              label: 'الأعلى',
              value: '${stats.max.toStringAsFixed(2)}%',
              valueColor: AppTheme.success,
              icon: Icons.arrow_upward,
            ),
            StatCard(
              label: 'الأدنى',
              value: '${stats.min.toStringAsFixed(2)}%',
              valueColor: AppTheme.danger,
              icon: Icons.arrow_downward,
            ),
            StatCard(
              label: 'الانحراف المعياري',
              value: stats.stdDev.toStringAsFixed(3),
              valueColor: AppTheme.info,
              icon: Icons.show_chart,
            ),
            StatCard(
              label: 'معامل التباين CV',
              value: '${stats.cv.toStringAsFixed(2)}%',
              valueColor: AppTheme.warning,
            ),
            StatCard(
              label: 'معدل الاجتياز',
              value: '${stats.passRate.toStringAsFixed(1)}%',
              valueColor: stats.passRate >= 95 ? AppTheme.success : AppTheme.danger,
            ),
          ],
        ),
        const SizedBox(height: 24),

        
        const SectionHeader(title: 'توزيع الجودة', icon: Icons.pie_chart_outline),
        const SizedBox(height: 14),
        SizedBox(
          height: 220,
          child: PieChart(PieChartData(
            sections: [
              if (stats.goodCount > 0)
                PieChartSectionData(
                  value: stats.goodCount.toDouble(),
                  color: AppTheme.success,
                  title: 'مقبول\n${stats.goodCount}',
                  radius: 80,
                  titleStyle: const TextStyle(
                      fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              if (stats.poorCount > 0)
                PieChartSectionData(
                  value: stats.poorCount.toDouble(),
                  color: AppTheme.danger,
                  title: 'ضعيف\n${stats.poorCount}',
                  radius: 80,
                  titleStyle: const TextStyle(
                      fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              if (stats.overCount > 0)
                PieChartSectionData(
                  value: stats.overCount.toDouble(),
                  color: AppTheme.over,
                  title: 'مفرط\n${stats.overCount}',
                  radius: 80,
                  titleStyle: const TextStyle(
                      fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                ),
            ],
            centerSpaceRadius: 40,
          )),
        ),
        const SizedBox(height: 24),

        
        const SectionHeader(title: 'تطور معامل الدمك', icon: Icons.show_chart),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 8, 12),
            child: SizedBox(
              height: 200,
              child: LineChart(LineChartData(
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: _chartGridLine,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}%',
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: points
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                            e.key.toDouble(), e.value.compactionPercent))
                        .toList(),
                    isCurved: true,
                    gradient: LinearGradient(colors: [
                      Theme.of(context).colorScheme.primary,
                      AppTheme.success,
                    ]),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 3,
                        color: CompactionColorSystem.getColor(spot.y),
                        strokeColor: Colors.white,
                        strokeWidth: 1,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.25),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: 95,
                    color: AppTheme.success.withOpacity(0.6),
                    strokeWidth: 1.5,
                    dashArray: [6, 3],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (_) => '95%',
                      style: const TextStyle(
                          color: AppTheme.success, fontSize: 9),
                    ),
                  ),
                ]),
                minY: 60,
                maxY: 105,
              )),
            ),
          ),
        ),
        const SizedBox(height: 24),

        
        const SectionHeader(title: 'جدول النقاط', icon: Icons.table_chart_outlined),
        const SizedBox(height: 12),
        _buildPointsTable(points),
        const SizedBox(height: 24),
      ]),
    );
  }

  static FlLine _chartGridLine(double value) => FlLine(
    color: AppTheme.border,
    strokeWidth: 1,
    dashArray: [4, 4],
  );

  Widget _buildPointsTable(List<CompactionPoint> points) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(cs.primaryContainer.withOpacity(0.4)),
          columnSpacing: 14,
          horizontalMargin: 14,
          headingTextStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
          dataTextStyle: const TextStyle(fontSize: 11),
          columns: const [
            DataColumn(label: Text('النقطة')),
            DataColumn(label: Text('الدورات')),
            DataColumn(label: Text('الدمك %')),
            DataColumn(label: Text('الحالة')),
            DataColumn(label: Text('الدقة م')),
          ],
          rows: points.map((p) {
            final color = CompactionColorSystem.getColor(p.compactionPercent);
            return DataRow(cells: [
              DataCell(Text(p.pointId)),
              DataCell(Text(p.passes.toString())),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${p.compactionPercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              )),
              DataCell(Text(CompactionColorSystem.getStatusText(p.compactionPercent))),
              DataCell(Text(p.accuracyM.toStringAsFixed(1))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  
  
  
  void _showSaveDialog(TrackingState state) {
    final nameCtrl  = TextEditingController(text: 'مشروع جديد');
    final locCtrl   = TextEditingController();
    final engCtrl   = TextEditingController();
    final supCtrl   = TextEditingController();
    final contCtrl  = TextEditingController();
    final stageCtrl = TextEditingController(text: 'طرقات');
    int layerNo     = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          right: 20, left: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('حفظ المشروع',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم المشروع')),
          const SizedBox(height: 10),
          TextField(controller: locCtrl,
              decoration: const InputDecoration(labelText: 'الموقع')),
          const SizedBox(height: 10),
          TextField(controller: engCtrl,
              decoration: const InputDecoration(labelText: 'المهندس المشرف')),
          const SizedBox(height: 10),
          TextField(controller: supCtrl,
              decoration: const InputDecoration(labelText: 'الجهة المشرفة')),
          const SizedBox(height: 10),
          TextField(controller: contCtrl,
              decoration: const InputDecoration(labelText: 'الجهة المنفذة')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final meta = ProjectMeta(
                  projectId: 'FMA-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.isEmpty ? 'مشروع جديد' : nameCtrl.text,
                  location: locCtrl.text,
                  engineer: engCtrl.text,
                  supervisor: supCtrl.text,
                  contractor: contCtrl.text,
                  stage: stageCtrl.text,
                  layerNo: layerNo,
                  createdAt: DateTime.now(),
                );
                await context.read<TrackingCubit>().saveProject(meta);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('تم حفظ المشروع بنجاح'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              child: const Text('حفظ المشروع'),
            ),
          ),
        ]),
      ),
    );
  }

  void _showExportDialog(TrackingState state) {
    final points      = _getPoints(state);
    final calibration = _getCalibration(state);
    final us          = _getUnitSystem(state);

    if (calibration == null || points.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => BlocListener<ExportCubit, ExportState>(
        listener: (_, expState) {
          if (expState is ExportError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(expState.message),
              backgroundColor: AppTheme.danger,
            ));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('تصدير التقارير',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            BlocBuilder<ExportCubit, ExportState>(
              builder: (_, expState) {
                if (expState is ExportLoading) {
                  return Column(children: [
                    CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(expState.message),
                    const SizedBox(height: 20),
                  ]);
                }
                final meta = ProjectMeta(
                  projectId: 'FMA', name: 'تقرير FMA', location: '',
                  engineer: '', supervisor: '', contractor: '', stage: '',
                  layerNo: 1, createdAt: DateTime.now(),
                );
                return Column(children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.read<ExportCubit>().exportExcel(
                          points: points,
                          calibration: calibration,
                          meta: meta,
                          unitSystem: us),
                      icon: const Icon(Icons.table_chart_outlined),
                      label: const Text('تصدير Excel'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1D6F42),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.read<ExportCubit>().exportPdf(
                          points: points,
                          calibration: calibration,
                          meta: meta,
                          unitSystem: us),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('تصدير PDF'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB72025),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ]);
              },
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('مسح جميع النقاط'),
        content: const Text(
            'سيتم حذف جميع النقاط المسجلة نهائياً. هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              context.read<TrackingCubit>().clearPoints();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  
  bool _hasPoints(TrackingState s) => _getPoints(s).isNotEmpty;

  List<CompactionPoint> _getPoints(TrackingState s) {
    if (s is TrackingReady) return s.points;
    if (s is TrackingActive) return s.points;
    return [];
  }

  CalibrationData? _getCalibration(TrackingState s) {
    if (s is TrackingReady) return s.calibration;
    if (s is TrackingActive) return s.calibration;
    return null;
  }

  double _getNorthDeg(TrackingState s) {
    if (s is TrackingReady) return s.northDeg;
    if (s is TrackingActive) return s.northDeg;
    return 0.0;
  }

  UnitSystem _getUnitSystem(TrackingState s) {
    if (s is TrackingReady) return s.unitSystem;
    if (s is TrackingActive) return s.unitSystem;
    return const UnitSystem();
  }
}
