import 'package:flutter_riverpod/flutter_riverpod.dart';
// ✅ hide Provider لتجنب التعارض بين gotrue و riverpod
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

import '../constants/supabase_constants.dart';
import 'supabase_client_provider.dart';
import '../../models/user.dart' as app;
import '../../models/project.dart';
import '../../models/investor.dart';
import '../../models/match.dart';
import '../../models/message.dart';
import '../../models/like.dart';
import '../../models/rating.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(client: ref.watch(supabaseClientProvider));
});

class SupabaseService {
  final SupabaseClient client;
  SupabaseService({required this.client});

  // ══════════════════ AUTH ══════════════════

  Future<AuthResponse> login(String email, String password) async {
    final res = await client.auth
        .signInWithPassword(email: email, password: password);
    if (res.user == null) throw Exception('فشل تسجيل الدخول');
    return res;
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'user_type': userType},
    );
    if (res.user == null) throw Exception('فشل إنشاء الحساب');
    await client.from(SupabaseConstants.profilesTable).upsert({
      'id': res.user!.id, 'email': email,
      'name': name, 'user_type': userType,
    });
    return res;
  }

  Future<void> logout() => client.auth.signOut();

  Future<app.User?> getCurrentUserProfile() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    final data = await client
        .from(SupabaseConstants.profilesTable)
        .select().eq('id', uid).maybeSingle();
    return data == null ? null : app.User.fromJson(data);
  }

  Future<app.User> updateProfile(Map<String, dynamic> updates) async {
    final uid = client.auth.currentUser!.id;
    final data = await client
        .from(SupabaseConstants.profilesTable)
        .update(updates).eq('id', uid).select().single();
    return app.User.fromJson(data);
  }

  // ══════════════════ PROJECTS ══════════════════

  Future<List<Project>> getProjects({
    int page = 1, int limit = 20,
    String? industry, String? stage, String? sort,
  }) async {
    // ✅ بناء الـ query بشكل صحيح — filter أولاً ثم order ثم range
    var q = client.from(SupabaseConstants.projectsTable)
        .select('*, profiles:owner_id(name,avatar)');

    // نحوّل ناتج eq إلى dynamic لتجنب مشكلة النوع في Dart
    dynamic dq = q;
    if (industry != null) dq = (dq as dynamic).eq('industry', industry);
    if (stage    != null) dq = (dq as dynamic).eq('stage', stage);

    final res = await (dq as dynamic)
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    return (res as List).map((j) => Project.fromJson(_flat(j))).toList();
  }

  Future<Project> getProjectById(String id) async {
    final d = await client.from(SupabaseConstants.projectsTable)
        .select('*, profiles:owner_id(name,avatar)').eq('id', id).single();
    return Project.fromJson(_flat(d));
  }

  Future<Project> createProject(Project project) async {
    final uid = client.auth.currentUser!.id;
    final map = project.toJson()..remove('id');
    map['owner_id'] = uid;
    final d = await client.from(SupabaseConstants.projectsTable)
        .insert(map).select().single();
    return Project.fromJson(d);
  }

  Future<Project> updateProject(String id, Project project) async {
    final map = project.toJson()..remove('id');
    final d = await client.from(SupabaseConstants.projectsTable)
        .update(map).eq('id', id).select().single();
    return Project.fromJson(d);
  }

  Future<void> deleteProject(String id) async =>
      client.from(SupabaseConstants.projectsTable).delete().eq('id', id);

  Future<List<Project>> getMyProjects() async {
    final uid = client.auth.currentUser!.id;
    final res = await client.from(SupabaseConstants.projectsTable)
        .select('*, profiles:owner_id(name,avatar)')
        .eq('owner_id', uid).order('created_at', ascending: false);
    return (res as List).map((j) => Project.fromJson(_flat(j))).toList();
  }

  // ══════════════════ INVESTORS ══════════════════

  Future<List<Investor>> getInvestors({
    int page = 1, int limit = 20, String? industry, String? stage,
  }) async {
    final res = await client.from(SupabaseConstants.investorsTable)
        .select('*, profiles:user_id(name,avatar,bio,company,position,location)')
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);
    return (res as List).map((j) => Investor.fromJson(_flat(j))).toList();
  }

  Future<Investor> getInvestorById(String id) async {
    final d = await client.from(SupabaseConstants.investorsTable)
        .select('*, profiles:user_id(name,avatar,bio,company,position,location)')
        .eq('id', id).single();
    return Investor.fromJson(_flat(d));
  }

  Future<void> updateInvestorCriteria(InvestmentCriteria criteria) async {
    final uid = client.auth.currentUser!.id;
    await client.from(SupabaseConstants.investorsTable)
        .update({'criteria': criteria.toJson()}).eq('user_id', uid);
  }

  // ══════════════════ MATCHES ══════════════════

  Future<List<Match>> getMatchedInvestors() async {
    final uid = client.auth.currentUser!.id;
    final res = await client.from(SupabaseConstants.matchesTable)
        .select('*, investors(*)')
        .eq('entrepreneur_id', uid).eq('target_type', 'investor')
        .order('match_percentage', ascending: false);
    return (res as List).map((j) => Match.fromJson(j)).toList();
  }

  Future<List<Match>> getMatchedProjects() async {
    final uid = client.auth.currentUser!.id;
    final res = await client.from(SupabaseConstants.matchesTable)
        .select('*, projects(*)')
        .eq('investor_id', uid).eq('target_type', 'project')
        .order('match_percentage', ascending: false);
    return (res as List).map((j) => Match.fromJson(j)).toList();
  }

  // ══════════════════ SEARCH ══════════════════

  Future<SearchResults> search({
    required String query, String? type,
    int page = 1, int limit = 20,
  }) async {
    final from = (page - 1) * limit;
    final to   = page * limit - 1;

    List<app.User>  users     = [];
    List<Project>   projects  = [];
    List<Investor>  investors = [];

    if (type == null || type == 'user') {
      final r = await client.from(SupabaseConstants.profilesTable)
          .select().ilike('name', '%$query%').range(from, to);
      users = (r as List).map((j) => app.User.fromJson(j)).toList();
    }
    if (type == null || type == 'project') {
      final r = await client.from(SupabaseConstants.projectsTable)
          .select().or('title.ilike.%$query%,description.ilike.%$query%')
          .range(from, to);
      projects = (r as List).map((j) => Project.fromJson(j)).toList();
    }
    if (type == null || type == 'investor') {
      final r = await client.from(SupabaseConstants.investorsTable)
          .select('*, profiles:user_id(name)').range(from, to);
      investors = (r as List).map((j) => Investor.fromJson(_flat(j))).toList();
    }

    return SearchResults(users: users, projects: projects,
        investors: investors,
        total: users.length + projects.length + investors.length);
  }

  // ══════════════════ LIKES ══════════════════

  Future<Like> createLike({
    required String targetId, required String targetType,
  }) async {
    final uid = client.auth.currentUser!.id;
    final d = await client.from(SupabaseConstants.likesTable)
        .insert({'user_id': uid, 'target_id': targetId,
                 'target_type': targetType})
        .select().single();
    return Like.fromJson(d);
  }

  Future<void> deleteLike(String id) =>
      client.from(SupabaseConstants.likesTable).delete().eq('id', id);

  Future<List<Like>> getMyLikes() async {
    final uid = client.auth.currentUser!.id;
    final res = await client.from(SupabaseConstants.likesTable)
        .select().eq('user_id', uid).order('created_at', ascending: false);
    return (res as List).map((j) => Like.fromJson(j)).toList();
  }

  // ══════════════════ RATINGS ══════════════════

  Future<Rating> createRating({
    required String targetId, required String targetType,
    required int score, String? comment,
  }) async {
    final uid     = client.auth.currentUser!.id;
    final profile = await getCurrentUserProfile();
    final d = await client.from(SupabaseConstants.ratingsTable).insert({
      'user_id': uid, 'user_name': profile?.name ?? '',
      'user_avatar': profile?.avatar,
      'target_id': targetId, 'target_type': targetType,
      'score': score,
      if (comment != null) 'comment': comment,
    }).select().single();
    return Rating.fromJson(d);
  }

  Future<RatingSummary> getRatingSummary(String targetId) async {
    final res = await client.from(SupabaseConstants.ratingsTable)
        .select('score').eq('target_id', targetId);
    final scores = (res as List).map((r) => r['score'] as int).toList();
    final total  = scores.length;
    final avg    = total > 0 ? scores.reduce((a, b) => a + b) / total : 0.0;
    final dist   = <int, int>{};
    for (final s in scores) { dist[s] = (dist[s] ?? 0) + 1; }
    return RatingSummary(targetId: targetId,
        averageRating: avg.toDouble(), totalRatings: total, distribution: dist);
  }

  // ══════════════════ MESSAGES ══════════════════

  Future<List<Conversation>> getConversations() async {
    final uid = client.auth.currentUser!.id;
    final res = await client.from(SupabaseConstants.convParticipants)
        .select('conversation_id, conversations(id,created_at,updated_at)')
        .eq('user_id', uid);
    return (res as List).map((row) {
      final conv = row['conversations'] as Map<String, dynamic>;
      return Conversation.fromJson(conv);
    }).toList();
  }

  Future<List<Message>> getMessages(String conversationId) async {
    final res = await client.from(SupabaseConstants.messagesTable)
        .select().eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return (res as List).map((j) => Message.fromJson(j)).toList();
  }

  Stream<List<Message>> messagesStream(String conversationId) {
    return client.from(SupabaseConstants.messagesTable)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map((j) => Message.fromJson(j)).toList());
  }

  Future<Message> sendMessage({
    required String conversationId, required String content,
  }) async {
    final uid = client.auth.currentUser!.id;
    final d = await client.from(SupabaseConstants.messagesTable).insert({
      'conversation_id': conversationId,
      'sender_id': uid, 'content': content, 'is_read': false,
    }).select().single();
    return Message.fromJson(d);
  }

  Future<Conversation> createConversation(String recipientId) async {
    final uid = client.auth.currentUser!.id;
    final convData = await client.from(SupabaseConstants.conversationsTable)
        .insert({'created_at': DateTime.now().toIso8601String()})
        .select().single();
    final convId = convData['id'] as String;
    await client.from(SupabaseConstants.convParticipants).insert([
      {'conversation_id': convId, 'user_id': uid},
      {'conversation_id': convId, 'user_id': recipientId},
    ]);
    return Conversation.fromJson(convData);
  }

  // ══════════════════ HELPER ══════════════════

  Map<String, dynamic> _flat(Map<String, dynamic> json) {
    final p = json['profiles'] as Map<String, dynamic>?;
    if (p == null) return json;
    return {
      ...json,
      'name':     p['name']     ?? json['name'],
      'avatar':   p['avatar']   ?? json['avatar'],
      'bio':      p['bio']      ?? json['bio'],
      'company':  p['company']  ?? json['company'],
      'position': p['position'] ?? json['position'],
      'location': p['location'] ?? json['location'],
    };
  }
}

class SearchResults {
  final List<app.User>  users;
  final List<Project>   projects;
  final List<Investor>  investors;
  final int             total;

  SearchResults({required this.users, required this.projects,
      required this.investors, required this.total});
}
