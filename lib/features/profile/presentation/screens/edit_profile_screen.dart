import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../providers/auth_provider.dart';

// ── Provider لحالة الرفع ─────────────────────────────────
final _uploadingProvider = StateProvider<bool>((ref) => false);

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _bioCtrl         = TextEditingController();
  final _companyCtrl     = TextEditingController();
  final _positionCtrl    = TextEditingController();
  final _locationCtrl    = TextEditingController();
  final _websiteCtrl     = TextEditingController();
  final _linkedInCtrl    = TextEditingController();

  List<String> _selectedIndustries = [];
  File?        _pickedImage;
  String?      _currentAvatarUrl;
  bool         _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  void _loadCurrent() {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    _nameCtrl.text     = user.name;
    _bioCtrl.text      = user.bio      ?? '';
    _companyCtrl.text  = user.company  ?? '';
    _positionCtrl.text = user.position ?? '';
    _locationCtrl.text = user.location ?? '';
    _websiteCtrl.text  = user.website  ?? '';
    _linkedInCtrl.text = user.linkedIn ?? '';
    _currentAvatarUrl  = user.avatar;
    _selectedIndustries = List.from(user.industries ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();  _bioCtrl.dispose();
    _companyCtrl.dispose(); _positionCtrl.dispose();
    _locationCtrl.dispose(); _websiteCtrl.dispose();
    _linkedInCtrl.dispose();
    super.dispose();
  }

  // ── اختيار صورة من المعرض أو الكاميرا ───────────────
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            if (_currentAvatarUrl != null || _pickedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() { _pickedImage = null; _currentAvatarUrl = null; });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── رفع الصورة إلى Supabase Storage ─────────────────
  Future<String?> _uploadAvatar(String uid) async {
    if (_pickedImage == null) return _currentAvatarUrl;

    setState(() => _saving = true);

    try {
      final supabase = Supabase.instance.client;
      final ext      = _pickedImage!.path.split('.').last;
      final path     = '$uid/avatar.$ext';
      final bytes    = await _pickedImage!.readAsBytes();

      await supabase.storage.from('avatars').uploadBinary(
        path, bytes,
        fileOptions: FileOptions(
          contentType: 'image/$ext',
          upsert: true,       // يستبدل الصورة القديمة
        ),
      );

      final url = supabase.storage.from('avatars').getPublicUrl(path);
      // أضف timestamp لمنع cache
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الصورة: $e'), backgroundColor: Colors.red),
        );
      }
      return _currentAvatarUrl;
    }
  }

  // ── حفظ التعديلات ────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final uid       = ref.read(currentUserProvider)!.id;
      final avatarUrl = await _uploadAvatar(uid);

      final service = ref.read(supabaseServiceProvider);
      await service.updateProfile({
        'name':       _nameCtrl.text.trim(),
        'bio':        _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'company':    _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
        'position':   _positionCtrl.text.trim().isEmpty ? null : _positionCtrl.text.trim(),
        'location':   _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        'website':    _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        'linkedin':   _linkedInCtrl.text.trim().isEmpty ? null : _linkedInCtrl.text.trim(),
        'industries': _selectedIndustries,
        'avatar':     avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // تحديث الـ provider بالبيانات الجديدة
      await ref.read(authProvider.notifier).refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ البروفايل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── UI ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user  = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── صورة البروفايل ────────────────────────
              Center(
                child: Stack(
                  children: [
                    // الصورة
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (_currentAvatarUrl != null
                                ? NetworkImage(_currentAvatarUrl!) as ImageProvider
                                : null),
                        child: (_pickedImage == null && _currentAvatarUrl == null)
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person,
                                      size: 50,
                                      color: theme.colorScheme.primary.withOpacity(0.5)),
                                ],
                              )
                            : null,
                      ),
                    ),

                    // زر التعديل
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _showImageSourceDialog,
                  child: const Text('Change Profile Photo'),
                ),
              ),
              const SizedBox(height: 24),

              // ── معلومات أساسية ────────────────────────
              _SectionHeader('Basic Info'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell others about yourself...',
                  prefixIcon: Icon(Icons.info_outline),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // ── معلومات العمل ─────────────────────────
              _SectionHeader('Work'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _companyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _positionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Position / Title',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 24),

              // ── تفاصيل أخرى ──────────────────────────
              _SectionHeader('Details'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Riyadh, Saudi Arabia',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _websiteCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  hintText: 'https://',
                  prefixIcon: Icon(Icons.language),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _linkedInCtrl,
                decoration: const InputDecoration(
                  labelText: 'LinkedIn URL',
                  hintText: 'https://linkedin.com/in/...',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 24),

              // ── الصناعات ─────────────────────────────
              _SectionHeader('Industries'),
              const SizedBox(height: 4),
              Text('Select industries you work in',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.industries.map((ind) {
                  final selected = _selectedIndustries.contains(ind);
                  return FilterChip(
                    label: Text(ind),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      selected
                          ? _selectedIndustries.remove(ind)
                          : _selectedIndustries.add(ind);
                    }),
                    selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: theme.colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // ── زر الحفظ ─────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _saving
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Save Changes',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold));
}
