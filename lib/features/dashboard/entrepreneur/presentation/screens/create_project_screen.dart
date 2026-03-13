import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '/core/constants/app_constants.dart';
import '/models/project.dart';
import '/providers/project_provider.dart';
import '/providers/auth_provider.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  final String? projectId;

  const CreateProjectScreen({super.key, this.projectId});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fundingGoalController = TextEditingController();
  final _websiteController = TextEditingController();
  final _videoUrlController = TextEditingController();

  String _selectedIndustry = AppConstants.industries.first;
  String _selectedStage = AppConstants.investmentStages.first;
  List<String> _tags = [];
  final _tagController = TextEditingController();

  bool get isEditing => widget.projectId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProject();
      });
    }
  }

  void _loadProject() async {
    await ref.read(projectsProvider.notifier).fetchProjectById(widget.projectId!);
    final project = ref.read(projectsProvider).selectedProject;
    if (project != null) {
      _titleController.text = project.title;
      _descriptionController.text = project.description;
      _fundingGoalController.text = project.fundingGoal.toString();
      _websiteController.text = project.website ?? '';
      _videoUrlController.text = project.videoUrl ?? '';
      setState(() {
        _selectedIndustry = project.industry;
        _selectedStage = project.stage;
        _tags = project.tags ?? [];
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fundingGoalController.dispose();
    _websiteController.dispose();
    _videoUrlController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(currentUserProvider);
      final project = Project(
        id: widget.projectId ?? '',
        ownerId: user?.id ?? '',
        ownerName: user?.name ?? '',
        ownerAvatar: user?.avatar,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        industry: _selectedIndustry,
        stage: _selectedStage,
        fundingGoal: double.parse(_fundingGoalController.text.trim()),
        website:
            _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        videoUrl:
            _videoUrlController.text.trim().isEmpty ? null : _videoUrlController.text.trim(),
        tags: _tags.isEmpty ? null : _tags,
      );

      bool success;
      if (isEditing) {
        success = await ref
            .read(projectsProvider.notifier)
            .updateProject(widget.projectId!, project);
      } else {
        success =
            await ref.read(projectsProvider.notifier).createProject(project);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Project updated successfully'
                  : 'Project created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(projectsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to save project'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsState = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(isEditing ? 'Edit Project' : 'Create Project'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Project Title',
                  hintText: 'Enter your project name',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your project...',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.length < 50) {
                    return 'Description should be at least 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Industry Dropdown
              DropdownButtonFormField<String>(
                value: _selectedIndustry,
                decoration: const InputDecoration(
                  labelText: 'Industry',
                  prefixIcon: Icon(Icons.category),
                ),
                items: AppConstants.industries.map((industry) {
                  return DropdownMenuItem(
                    value: industry,
                    child: Text(industry),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedIndustry = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Stage Dropdown
              DropdownButtonFormField<String>(
                value: _selectedStage,
                decoration: const InputDecoration(
                  labelText: 'Investment Stage',
                  prefixIcon: Icon(Icons.stairs),
                ),
                items: AppConstants.investmentStages.map((stage) {
                  return DropdownMenuItem(
                    value: stage,
                    child: Text(stage),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStage = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Funding Goal
              TextFormField(
                controller: _fundingGoalController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Funding Goal (\$)',
                  hintText: 'e.g., 500000',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a funding goal';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Website (Optional)
              TextFormField(
                controller: _websiteController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Website (Optional)',
                  hintText: 'https://yourproject.com',
                  prefixIcon: Icon(Icons.language),
                ),
              ),
              const SizedBox(height: 16),

              // Video URL (Optional)
              TextFormField(
                controller: _videoUrlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Pitch Video URL (Optional)',
                  hintText: 'YouTube or Vimeo link',
                  prefixIcon: Icon(Icons.video_library),
                ),
              ),
              const SizedBox(height: 16),

              // Tags
              Text(
                'Tags',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: 'Add a tag',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add_circle),
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Submit Button
              FilledButton(
                onPressed: projectsState.isLoading ? null : _handleSubmit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: projectsState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isEditing ? 'Update Project' : 'Create Project',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
