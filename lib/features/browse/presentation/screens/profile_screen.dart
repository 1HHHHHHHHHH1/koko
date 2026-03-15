import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/supabase/supabase_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../models/user.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/likes_provider.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';

// ── Provider لجلب بيانات مستخدم بعينه ───────────────────
final userProfileProvider =
    FutureProvider.family<User?, String>((ref, userId) async {
  final service = ref.watch(supabaseServiceProvider);
  final data    = await service.client
      .from('profiles').select().eq('id', userId).maybeSingle();
  return data == null ? null : User.fromJson(data);
});

class ProfileScreen extends ConsumerWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme        = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider(userId));
    final currentUser  = ref.watch(currentUserProvider);
    final isMe         = currentUser?.id == userId;
    final isLiked      = ref.watch(isLikedProvider(userId));

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator())),

        error: (e, _) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Error: $e',
                style: TextStyle(color: Colors.red.shade600)))),

        data: (user) {
          if (user == null) {
            return Scaffold(
                appBar: AppBar(),
                body: const Center(child: Text('Profile not found')));
          }

          return CustomScrollView(
            slivers: [
              // ── SliverAppBar مع صورة ─────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          // ── الصورة الشخصية ──────────
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor:
                                    Colors.white.withOpacity(0.2),
                                backgroundImage: user.avatar != null
                                    ? NetworkImage(user.avatar!)
                                    : null,
                                child: user.avatar == null
                                    ? Text(
                                        user.name.isNotEmpty
                                            ? user.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            fontSize: 36,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))
                                    : null,
                              ),
                              // ✅ زر تعديل الصورة (فقط لصاحب البروفايل)
                              if (isMe)
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const EditProfileScreen())),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: theme.colorScheme.primary,
                                            width: 2),
                                      ),
                                      child: Icon(Icons.camera_alt,
                                          color: theme.colorScheme.primary,
                                          size: 16),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(user.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            user.userType == 'investor'
                                ? 'Investor'
                                : 'Entrepreneur',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14),
                          ),
                          if (user.company != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.company!,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // ── أزرار AppBar ───────────────────────
                actions: [
                  if (!isMe)
                    IconButton(
                      tooltip: 'Like',
                      icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.white),
                      onPressed: () => ref
                          .read(likesProvider.notifier)
                          .toggleLike(userId, user.userType),
                    ),
                  // ✅ زر تعديل البروفايل
                  if (isMe)
                    IconButton(
                      tooltip: 'Edit Profile',
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.white),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen()),
                      ).then((_) =>
                          // تحديث البيانات بعد العودة من التعديل
                          ref.invalidate(userProfileProvider(userId))),
                    ),
                ],
              ),

              // ── Body ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Stats ──
                      Row(
                        children: [
                          _StatCard(
                              icon: Icons.star,
                              value: user.averageRating
                                      ?.toStringAsFixed(1) ?? '—',
                              label: 'Rating',
                              color: Colors.amber),
                          const SizedBox(width: 12),
                          _StatCard(
                              icon: Icons.favorite,
                              value: '${user.totalLikes ?? 0}',
                              label: 'Likes',
                              color: Colors.red),
                          const SizedBox(width: 12),
                          _StatCard(
                              icon: Icons.rate_review,
                              value: '${user.totalRatings ?? 0}',
                              label: 'Reviews',
                              color: theme.colorScheme.primary),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ✅ زر تعديل البروفايل (لصاحب البروفايل)
                      if (isMe) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Profile'),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen()),
                            ).then((_) =>
                                ref.invalidate(userProfileProvider(userId))),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Bio ──
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        _SectionTitle('About'),
                        const SizedBox(height: 8),
                        Text(user.bio!,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(height: 1.6)),
                        const SizedBox(height: 20),
                      ],

                      // ── Work ──
                      if (user.company != null || user.position != null) ...[
                        _SectionTitle('Work'),
                        const SizedBox(height: 8),
                        if (user.position != null)
                          _InfoRow(Icons.work_outline, user.position!),
                        if (user.company != null)
                          _InfoRow(Icons.business_outlined, user.company!),
                        const SizedBox(height: 20),
                      ],

                      // ── Details ──
                      if (user.location != null ||
                          user.website  != null ||
                          user.linkedIn != null) ...[
                        _SectionTitle('Details'),
                        const SizedBox(height: 8),
                        if (user.location != null)
                          _InfoRow(Icons.location_on_outlined, user.location!),
                        if (user.website != null)
                          _InfoRow(Icons.language, user.website!),
                        if (user.linkedIn != null)
                          _InfoRow(Icons.link, user.linkedIn!),
                        const SizedBox(height: 20),
                      ],

                      // ── Industries ──
                      if (user.industries != null &&
                          user.industries!.isNotEmpty) ...[
                        _SectionTitle('Industries'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: user.industries!
                              .map((i) => Chip(label: Text(i)))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Message button (for others) ──
                      if (!isMe) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.message_outlined),
                            label: const Text('Send Message'),
                            onPressed: () => context.go(Routes.conversations),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   value;
  final String   label;
  final Color    color;

  const _StatCard({
    required this.icon, required this.value,
    required this.label, required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              Text(label, style: TextStyle(
                  fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold));
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey[700])),
            ),
          ],
        ),
      );
}
