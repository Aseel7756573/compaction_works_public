
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/projects_cubit.dart';
import '../cubits/tracking_cubit.dart';
import '../theme/app_theme.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});
  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProjectsCubit>().loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('المشاريع المحفوظة')),
      body: BlocBuilder<ProjectsCubit, ProjectsState>(
        builder: (_, state) {
          if (state is ProjectsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProjectsError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.error_outline, size: 48, color: cs.error),
                const SizedBox(height: 12),
                Text(state.message,
                    style: tt.bodyLarge?.copyWith(color: cs.error),
                    textAlign: TextAlign.center),
              ]),
            );
          }
          if (state is ProjectsLoaded) {
            if (state.projects.isEmpty) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.folder_open_outlined,
                      size: 64, color: cs.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('لا توجد مشاريع محفوظة',
                      style: tt.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant)),
                ]),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = state.projects[i];
                return Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.folder_outlined,
                          color: cs.onPrimaryContainer, size: 22),
                    ),
                    title: Text(p.name,
                        style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        if (p.location.isNotEmpty)
                          Row(children: [
                            Icon(Icons.location_on_outlined,
                                size: 12, color: cs.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(p.location,
                                  style: tt.bodySmall,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                        Row(children: [
                          Icon(Icons.engineering_outlined,
                              size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            '${p.engineer.isNotEmpty ? p.engineer : "—"} | ${p.createdAt.toString().substring(0, 10)}',
                            style: tt.bodySmall,
                          ),
                        ]),
                        if (p.stage.isNotEmpty)
                          Text('مرحلة: ${p.stage} — طبقة ${p.layerNo}',
                              style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant)),
                      ],
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: Icon(Icons.download_outlined,
                            color: cs.primary, size: 20),
                        tooltip: 'تحميل المشروع',
                        onPressed: () async {
                          await context
                              .read<TrackingCubit>()
                              .loadProject(p.projectId);
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('تم تحميل المشروع'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: cs.error, size: 20),
                        tooltip: 'حذف',
                        onPressed: () => _confirmDelete(p.projectId, p.name),
                      ),
                    ]),
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المشروع'),
        content: Text('هل تريد حذف "$name"؟\nلا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ProjectsCubit>().delete(id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
