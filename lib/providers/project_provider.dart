/// ============================================================
/// project_provider.dart  (نسخة Supabase)
/// ============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_service.dart';
import '../models/project.dart';

class ProjectsState {
  final List<Project> projects;
  final List<Project> myProjects;
  final Project?      selectedProject;
  final bool          isLoading;
  final String?       error;
  final int           currentPage;
  final bool          hasMore;

  const ProjectsState({
    this.projects       = const [],
    this.myProjects     = const [],
    this.selectedProject,
    this.isLoading      = false,
    this.error,
    this.currentPage    = 1,
    this.hasMore        = true,
  });

  ProjectsState copyWith({
    List<Project>? projects,
    List<Project>? myProjects,
    Project?       selectedProject,
    bool?          isLoading,
    String?        error,
    int?           currentPage,
    bool?          hasMore,
  }) => ProjectsState(
    projects:        projects        ?? this.projects,
    myProjects:      myProjects      ?? this.myProjects,
    selectedProject: selectedProject ?? this.selectedProject,
    isLoading:       isLoading       ?? this.isLoading,
    error:           error,
    currentPage:     currentPage     ?? this.currentPage,
    hasMore:         hasMore         ?? this.hasMore,
  );
}

class ProjectsNotifier extends StateNotifier<ProjectsState> {
  final SupabaseService _service;

  ProjectsNotifier(this._service) : super(const ProjectsState());

  Future<void> fetchProjects({
    bool    refresh  = false,
    String? sort,
    String? industry,
    String? stage,
  }) async {
    if (state.isLoading) return;
    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, error: null, currentPage: page);

    try {
      final projects = await _service.getProjects(
        page:     page,
        sort:     sort,
        industry: industry,
        stage:    stage,
      );

      state = state.copyWith(
        projects:    refresh ? projects : [...state.projects, ...projects],
        isLoading:   false,
        currentPage: page + 1,
        hasMore:     projects.length == 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMyProjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final myProjects = await _service.getMyProjects();
      state = state.copyWith(myProjects: myProjects, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchProjectById(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final project = await _service.getProjectById(id);
      state = state.copyWith(selectedProject: project, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createProject(Project project) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final created = await _service.createProject(project);
      state = state.copyWith(
        myProjects: [created, ...state.myProjects],
        isLoading:  false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateProject(String id, Project project) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _service.updateProject(id, project);
      state = state.copyWith(
        myProjects: state.myProjects
            .map((p) => p.id == id ? updated : p)
            .toList(),
        selectedProject: updated,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteProject(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteProject(id);
      state = state.copyWith(
        myProjects: state.myProjects.where((p) => p.id != id).toList(),
        projects:   state.projects.where((p) => p.id != id).toList(),
        isLoading:  false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, ProjectsState>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return ProjectsNotifier(service);
});
