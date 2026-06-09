
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/compaction_point.dart';
import '../../domain/repositories/project_repository.dart';


abstract class ProjectsState extends Equatable {
  const ProjectsState();
}

class ProjectsInitial extends ProjectsState {
  @override
  List<Object?> get props => [];
}

class ProjectsLoading extends ProjectsState {
  @override
  List<Object?> get props => [];
}

class ProjectsLoaded extends ProjectsState {
  final List<ProjectMeta> projects;
  const ProjectsLoaded(this.projects);
  @override
  List<Object?> get props => [projects.length];
}

class ProjectsError extends ProjectsState {
  final String message;
  const ProjectsError(this.message);
  @override
  List<Object?> get props => [message];
}


class ProjectsCubit extends Cubit<ProjectsState> {
  final ProjectRepository _repo;
  ProjectsCubit(this._repo) : super(ProjectsInitial());

  Future<void> loadAll() async {
    emit(ProjectsLoading());
    try {
      final projects = await _repo.getAllProjects();
      emit(ProjectsLoaded(projects));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> delete(String projectId) async {
    await _repo.deleteProject(projectId);
    await loadAll();
  }
}
