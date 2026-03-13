import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_service.dart';
import '../models/project.dart';

// Projects State
class ProjectsState {
  final List<Project> projects;
  final List<Project> myProjects;
  final Project? selectedProject;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const ProjectsState({
    this.projects = const [],
    this.myProjects = const [],
    this.selectedProject,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  ProjectsState copyWith({
    List<Project>? projects,
    List<Project>? myProjects,
    Project? selectedProject,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      myProjects: myProjects ?? this.myProjects,
      selectedProject: selectedProject ?? this.selectedProject,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Projects Notifier
class ProjectsNotifier extends StateNotifier<ProjectsState> {
  final ApiService _apiService;

  ProjectsNotifier(this._apiService) : super(const ProjectsState());

  Future<void> fetchProjects({
    bool refresh = false,
    String? sort,
    String? industry,
    String? stage,
  }) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: page,
    );

    try {
      final projects = await _apiService.getProjects(
        page: page,
        sort: sort,
        industry: industry,
        stage: stage,
      );

      if (refresh) {
        state = state.copyWith(
          projects: projects,
          isLoading: false,
          currentPage: 2,
          hasMore: projects.length >= 20,
        );
      } else {
        state = state.copyWith(
          projects: [...state.projects, ...projects],
          isLoading: false,
          currentPage: page + 1,
          hasMore: projects.length >= 20,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchMyProjects() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final projects = await _apiService.getMyProjects();
      state = state.copyWith(
        myProjects: projects,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchProjectById(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final project = await _apiService.getProjectById(id);
      state = state.copyWith(
        selectedProject: project,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createProject(Project project) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newProject = await _apiService.createProject(project);
      state = state.copyWith(
        myProjects: [newProject, ...state.myProjects],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateProject(String id, Project project) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedProject = await _apiService.updateProject(id, project);
      
      final myProjects = state.myProjects.map((p) {
        return p.id == id ? updatedProject : p;
      }).toList();

      state = state.copyWith(
        myProjects: myProjects,
        selectedProject: updatedProject,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteProject(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.deleteProject(id);
      
      final myProjects = state.myProjects.where((p) => p.id != id).toList();
      
      state = state.copyWith(
        myProjects: myProjects,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearSelectedProject() {
    state = state.copyWith(selectedProject: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, ProjectsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProjectsNotifier(apiService);
});
