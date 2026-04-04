import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  static const String _investorSelect =
      '*, profiles:user_id(name,avatar,bio,company,position,location,website,linkedin,industries)';
  static const String _projectSelect = '*, profiles:owner_id(name,avatar)';

  // ══════════════════ AUTH ══════════════════

  Future<AuthResponse> login(String email, String password) async {
    final res =
        await client.auth.signInWithPassword(email: email, password: password);
    if (res.user == null) throw Exception('Login failed');
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
    if (res.user == null) throw Exception('Account creation failed');
    await client.from(SupabaseConstants.profilesTable).upsert({
      'id': res.user!.id,
      'email': email,
      'name': name,
      'user_type': userType,
    });
    if (userType == 'investor') {
      await _ensureInvestorRecord(userId: res.user!.id);
    }
    return res;
  }

  Future<void> logout() => client.auth.signOut();

  Future<app.User?> getCurrentUserProfile() async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    final data = await client
        .from(SupabaseConstants.profilesTable)
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (data == null) return null;

    final profile = app.User.fromJson(data);
    if (profile.isInvestor) {
      await _ensureInvestorRecord(userId: profile.id);
    }
    return profile;
  }

  Future<app.User> updateProfile(Map<String, dynamic> updates) async {
    final uid = client.auth.currentUser!.id;
    final data = await client
        .from(SupabaseConstants.profilesTable)
        .update(updates)
        .eq('id', uid)
        .select()
        .single();
    final profile = app.User.fromJson(data);
    if (profile.isInvestor) {
      await client.from(SupabaseConstants.investorsTable).upsert({
        'user_id': profile.id,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    }
    return profile;
  }

  // ══════════════════ PROJECTS ══════════════════

  Future<List<Project>> getProjects({
    int page = 1,
    int limit = 20,
    String? industry,
    String? stage,
    String? sort,
  }) async {
    dynamic q =
        client.from(SupabaseConstants.projectsTable).select(_projectSelect);
    if (industry != null && industry.trim().isNotEmpty) {
      q = q.eq('industry', industry.trim());
    }
    if (stage != null && stage.trim().isNotEmpty) {
      q = q.eq('stage', stage.trim());
    }

    switch (sort) {
      case 'highest_rated':
        q = q.order('average_rating', ascending: false);
        break;
      case 'most_liked':
        q = q.order('total_likes', ascending: false);
        break;
      case 'newest':
      default:
        q = q.order('created_at', ascending: false);
        break;
    }

    final res = await q.range((page - 1) * limit, page * limit - 1);
    return (res as List).map((j) => Project.fromJson(_flatProject(j))).toList();
  }

  Future<Project> getProjectById(String id) async {
    final d = await client
        .from(SupabaseConstants.projectsTable)
        .select('*, profiles:owner_id(name,avatar)')
        .eq('id', id)
        .single();
    return Project.fromJson(_flat(d));
  }

  Future<Project> createProject(Project project) async {
    final uid = client.auth.currentUser!.id;
    final map = project.toJson()..remove('id');
    map['owner_id'] = uid;
    final d = await client
        .from(SupabaseConstants.projectsTable)
        .insert(map)
        .select()
        .single();
    return Project.fromJson(d);
  }

  Future<Project> updateProject(String id, Project project) async {
    final map = project.toJson()..remove('id');
    final d = await client
        .from(SupabaseConstants.projectsTable)
        .update(map)
        .eq('id', id)
        .select()
        .single();
    return Project.fromJson(d);
  }

  Future<void> deleteProject(String id) async =>
      client.from(SupabaseConstants.projectsTable).delete().eq('id', id);

  Future<List<Project>> getMyProjects() async {
    final uid = client.auth.currentUser!.id;
    final res = await client
        .from(SupabaseConstants.projectsTable)
        .select('*, profiles:owner_id(name,avatar)')
        .eq('owner_id', uid)
        .order('created_at', ascending: false);
    return (res as List).map((j) => Project.fromJson(_flat(j))).toList();
  }

  // ══════════════════ INVESTORS ══════════════════

  Future<List<Investor>> getInvestors({
    int page = 1,
    int limit = 20,
    String? industry,
    String? stage,
    String? sort,
  }) async {
    dynamic q =
        client.from(SupabaseConstants.investorsTable).select(_investorSelect);

    switch (sort) {
      case 'highest_rated':
        q = q.order('average_rating', ascending: false);
        break;
      case 'most_liked':
        q = q.order('total_likes', ascending: false);
        break;
      case 'newest':
      default:
        q = q.order('created_at', ascending: false);
        break;
    }

    final hasClientFilters = (industry != null && industry.trim().isNotEmpty) ||
        (stage != null && stage.trim().isNotEmpty);

    final res = await q.range(
      hasClientFilters ? 0 : (page - 1) * limit,
      hasClientFilters ? 199 : page * limit - 1,
    );

    var investors =
        (res as List).map((j) => Investor.fromJson(_flat(j))).toList();

    if (industry != null && industry.trim().isNotEmpty) {
      final normalizedIndustry = industry.trim().toLowerCase();
      investors = investors.where((investor) {
        final criteriaIndustries = investor.criteria?.industries ?? const [];
        final profileIndustries = investor.industries ?? const [];
        final allIndustries = [...criteriaIndustries, ...profileIndustries]
            .map((value) => value.toLowerCase())
            .toSet();
        return allIndustries.contains(normalizedIndustry);
      }).toList();
    }

    if (stage != null && stage.trim().isNotEmpty) {
      final normalizedStage = stage.trim().toLowerCase();
      investors = investors.where((investor) {
        final stages = (investor.criteria?.stages ?? const [])
            .map((value) => value.toLowerCase())
            .toSet();
        return stages.contains(normalizedStage);
      }).toList();
    }

    if (hasClientFilters) {
      investors = investors.skip((page - 1) * limit).take(limit).toList();
    }

    return investors;
  }

  Future<Investor> getInvestorById(String id) async {
    final d = await client
        .from(SupabaseConstants.investorsTable)
        .select(_investorSelect)
        .eq('id', id)
        .single();
    return Investor.fromJson(_flat(d));
  }

  Future<Investor?> getCurrentInvestor() async {
    final profile = await getCurrentUserProfile();
    if (profile == null || !profile.isInvestor) return null;

    final data = await client
        .from(SupabaseConstants.investorsTable)
        .select(_investorSelect)
        .eq('user_id', profile.id)
        .maybeSingle();

    return data == null ? null : Investor.fromJson(_flat(data));
  }

  Future<void> updateInvestorCriteria(InvestmentCriteria criteria) async {
    final uid = client.auth.currentUser!.id;
    await client.from(SupabaseConstants.investorsTable).upsert({
      'user_id': uid,
      'criteria': criteria.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  // ══════════════════ MATCHES ══════════════════

  Future<List<Match>> getMatchedInvestors() async {
    final uid = client.auth.currentUser!.id;
    final res = await client
        .from(SupabaseConstants.matchesTable)
        .select()
        .eq('entrepreneur_id', uid)
        .eq('target_type', 'investor')
        .order('match_percentage', ascending: false);

    final rows = (res as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    if (rows.isEmpty) return [];

    final investorIds =
        rows.map((row) => row['target_id'] as String).toSet().toList();

    final investorsRes = await client
        .from(SupabaseConstants.investorsTable)
        .select(_investorSelect)
        .inFilter('id', investorIds);

    final investorsById = <String, Investor>{};
    for (final row in investorsRes as List) {
      final investor =
          Investor.fromJson(_flat(Map<String, dynamic>.from(row as Map)));
      investorsById[investor.id] = investor;
    }

    return rows.map((row) {
      final targetId = row['target_id'] as String? ?? '';
      return Match(
        id: row['id'] as String? ?? '',
        targetId: targetId,
        targetType: row['target_type'] as String? ?? 'investor',
        matchPercentage: (row['match_percentage'] as num? ?? 0).toDouble(),
        matchingCriteria: row['matching_criteria'] != null
            ? List<String>.from(row['matching_criteria'])
            : null,
        investor: investorsById[targetId],
        createdAt: row['created_at'] != null
            ? DateTime.tryParse(row['created_at'].toString())
            : null,
      );
    }).toList();
  }

  Future<List<Match>> getMatchedProjects() async {
    final uid = client.auth.currentUser!.id;
    final res = await client
        .from(SupabaseConstants.matchesTable)
        .select()
        .eq('investor_id', uid)
        .eq('target_type', 'project')
        .order('match_percentage', ascending: false);

    final rows = (res as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    if (rows.isEmpty) return [];

    final projectIds =
        rows.map((row) => row['target_id'] as String).toSet().toList();

    final projectsRes = await client
        .from(SupabaseConstants.projectsTable)
        .select(_projectSelect)
        .inFilter('id', projectIds);

    final projectsById = <String, Project>{};
    for (final row in projectsRes as List) {
      final project =
          Project.fromJson(_flatProject(Map<String, dynamic>.from(row as Map)));
      projectsById[project.id] = project;
    }

    return rows.map((row) {
      final targetId = row['target_id'] as String? ?? '';
      return Match(
        id: row['id'] as String? ?? '',
        targetId: targetId,
        targetType: row['target_type'] as String? ?? 'project',
        matchPercentage: (row['match_percentage'] as num? ?? 0).toDouble(),
        matchingCriteria: row['matching_criteria'] != null
            ? List<String>.from(row['matching_criteria'])
            : null,
        project: projectsById[targetId],
        createdAt: row['created_at'] != null
            ? DateTime.tryParse(row['created_at'].toString())
            : null,
      );
    }).toList();
  }

  Future<void> replaceMatchedInvestors(List<Match> matches) async {
    final uid = client.auth.currentUser!.id;
    await client
        .from(SupabaseConstants.matchesTable)
        .delete()
        .eq('entrepreneur_id', uid)
        .eq('target_type', 'investor');

    final rows = matches
        .where((match) => match.investor != null)
        .map((match) => {
              'entrepreneur_id': uid,
              'investor_id': match.investor!.userId,
              'target_id': match.targetId,
              'target_type': 'investor',
              'match_percentage': match.matchPercentage,
              'matching_criteria': match.matchingCriteria ?? <String>[],
            })
        .toList();

    if (rows.isEmpty) return;
    await client.from(SupabaseConstants.matchesTable).insert(rows);
  }

  Future<void> replaceMatchedProjects(List<Match> matches) async {
    final uid = client.auth.currentUser!.id;
    await client
        .from(SupabaseConstants.matchesTable)
        .delete()
        .eq('investor_id', uid)
        .eq('target_type', 'project');

    final rows = matches
        .where((match) => match.project != null)
        .map((match) => {
              'entrepreneur_id': match.project!.ownerId,
              'investor_id': uid,
              'target_id': match.targetId,
              'target_type': 'project',
              'match_percentage': match.matchPercentage,
              'matching_criteria': match.matchingCriteria ?? <String>[],
            })
        .toList();

    if (rows.isEmpty) return;
    await client.from(SupabaseConstants.matchesTable).insert(rows);
  }

  // ══════════════════ SEARCH ══════════════════

  Future<SearchResults> search({
    required String query,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return SearchResults(
        users: const [],
        projects: const [],
        investors: const [],
        total: 0,
      );
    }

    final normalizedType = type?.trim().toLowerCase();
    final pattern = '%$normalizedQuery%';
    final from = (page - 1) * limit;
    final to = page * limit - 1;
    List<app.User> users = [];
    List<Project> projects = [];
    List<Investor> investors = [];

    if (normalizedType == null ||
        normalizedType == 'user' ||
        normalizedType == 'entrepreneur') {
      dynamic userQuery = client.from(SupabaseConstants.profilesTable).select();
      if (normalizedType == null || normalizedType == 'entrepreneur') {
        userQuery = userQuery.eq('user_type', 'entrepreneur');
      }

      final r = await userQuery
          .or(
            'name.ilike.$pattern,'
            'bio.ilike.$pattern,'
            'company.ilike.$pattern,'
            'position.ilike.$pattern,'
            'location.ilike.$pattern',
          )
          .range(from, to);
      users = (r as List).map((j) => app.User.fromJson(j)).toList();
    }

    if (normalizedType == null || normalizedType == 'project') {
      final r = await client
          .from(SupabaseConstants.projectsTable)
          .select(_projectSelect)
          .or(
            'title.ilike.$pattern,'
            'description.ilike.$pattern,'
            'industry.ilike.$pattern,'
            'stage.ilike.$pattern',
          )
          .range(from, to);
      projects =
          (r as List).map((j) => Project.fromJson(_flatProject(j))).toList();
    }

    if (normalizedType == null || normalizedType == 'investor') {
      final matchedInvestorRows = <String, Map<String, dynamic>>{};

      final profileMatches = await client
          .from(SupabaseConstants.profilesTable)
          .select('id')
          .eq('user_type', 'investor')
          .or(
            'name.ilike.$pattern,'
            'company.ilike.$pattern,'
            'position.ilike.$pattern,'
            'location.ilike.$pattern',
          );

      final matchedUserIds = (profileMatches as List)
          .map((row) => row['id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();

      if (matchedUserIds.isNotEmpty) {
        final investorByProfile = await client
            .from(SupabaseConstants.investorsTable)
            .select(_investorSelect)
            .inFilter('user_id', matchedUserIds);

        for (final row in investorByProfile as List) {
          final investorJson = _flat(Map<String, dynamic>.from(row as Map));
          matchedInvestorRows[investorJson['id'] as String] = investorJson;
        }
      }

      final investorCandidates = await client
          .from(SupabaseConstants.investorsTable)
          .select(_investorSelect)
          .range(0, 499);

      for (final row in investorCandidates as List) {
        final investorJson = _flat(Map<String, dynamic>.from(row as Map));
        final investor = Investor.fromJson(investorJson);
        final description =
            (investor.criteria?.additionalNotes ?? '').trim().toLowerCase();

        if (description.contains(normalizedQuery.toLowerCase())) {
          matchedInvestorRows[investor.id] = investorJson;
        }
      }

      final mergedInvestors = matchedInvestorRows.values
          .map(Investor.fromJson)
          .toList()
        ..sort((a, b) {
          final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      investors = mergedInvestors.skip(from).take(limit).toList();
    }

    return SearchResults(
        users: users,
        projects: projects,
        investors: investors,
        total: users.length + projects.length + investors.length);
  }

  // ══════════════════ LIKES ══════════════════

  Future<Like> createLike(
      {required String targetId, required String targetType}) async {
    final uid = client.auth.currentUser!.id;
    final d = await client
        .from(SupabaseConstants.likesTable)
        .insert(
            {'user_id': uid, 'target_id': targetId, 'target_type': targetType})
        .select()
        .single();
    return Like.fromJson(d);
  }

  Future<void> deleteLike(String id) =>
      client.from(SupabaseConstants.likesTable).delete().eq('id', id);

  Future<List<Like>> getMyLikes() async {
    final uid = client.auth.currentUser!.id;
    final res = await client
        .from(SupabaseConstants.likesTable)
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (res as List).map((j) => Like.fromJson(j)).toList();
  }

  // ══════════════════ RATINGS ══════════════════

  Future<Rating> createRating({
    required String targetId,
    required String targetType,
    required int score,
    String? comment,
  }) async {
    final uid = client.auth.currentUser!.id;
    final profile = await getCurrentUserProfile();
    final d = await client
        .from(SupabaseConstants.ratingsTable)
        .insert({
          'user_id': uid,
          'user_name': profile?.name ?? '',
          'user_avatar': profile?.avatar,
          'target_id': targetId,
          'target_type': targetType,
          'score': score,
          if (comment != null) 'comment': comment,
        })
        .select()
        .single();
    return Rating.fromJson(d);
  }

  Future<RatingSummary> getRatingSummary(String targetId) async {
    final res = await client
        .from(SupabaseConstants.ratingsTable)
        .select('score')
        .eq('target_id', targetId);
    final scores = (res as List).map((r) => r['score'] as int).toList();
    final total = scores.length;
    final avg = total > 0 ? scores.reduce((a, b) => a + b) / total : 0.0;
    final dist = <int, int>{};
    for (final s in scores) {
      dist[s] = (dist[s] ?? 0) + 1;
    }
    return RatingSummary(
        targetId: targetId,
        averageRating: avg.toDouble(),
        totalRatings: total,
        distribution: dist);
  }

  Future<List<Rating>> getRatingsForTarget(String targetId) async {
    final res = await client
        .from(SupabaseConstants.ratingsTable)
        .select()
        .eq('target_id', targetId)
        .order('created_at', ascending: false);
    return (res as List).map((j) => Rating.fromJson(j)).toList();
  }

  // ══════════════════ MESSAGES ══════════════════

  /// ✅ جلب المحادثات مع بيانات المستخدم الآخر الكاملة
  Future<List<Conversation>> getConversations() async {
    final uid = client.auth.currentUser!.id;

    final res = await client
        .from(SupabaseConstants.convParticipants)
        .select('conversation_id, conversations(id, created_at, updated_at)')
        .eq('user_id', uid);

    final List<Conversation> conversations = [];

    for (final row in res as List) {
      final convMap = row['conversations'] as Map<String, dynamic>;
      final convId = convMap['id'] as String;

      // ✅ جلب المشارك الآخر
      final otherParticipantRes = await client
          .from(SupabaseConstants.convParticipants)
          .select(
              'user_id, profiles:user_id(id, name, avatar, user_type, email)')
          .eq('conversation_id', convId)
          .neq('user_id', uid)
          .maybeSingle();

      app.User? otherUser;
      if (otherParticipantRes != null) {
        final profileData = otherParticipantRes['profiles'];
        if (profileData != null) {
          otherUser = app.User.fromJson(profileData as Map<String, dynamic>);
        }
      }

      // ✅ جلب آخر رسالة
      final lastMsgRes = await client
          .from(SupabaseConstants.messagesTable)
          .select()
          .eq('conversation_id', convId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      Message? lastMessage;
      if (lastMsgRes != null) {
        lastMessage = Message.fromJson(lastMsgRes);
      }

      // ✅ عدد الرسائل غير المقروءة
      final unreadRes = await client
          .from(SupabaseConstants.messagesTable)
          .select('id')
          .eq('conversation_id', convId)
          .eq('is_read', false)
          .neq('sender_id', uid);

      final unreadCount = (unreadRes as List).length;

      conversations.add(Conversation(
        id: convId,
        participantIds: [uid],
        otherParticipant: otherUser,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        createdAt: _parseDateTime(convMap['created_at']),
        updatedAt: _parseDateTime(convMap['updated_at']),
      ));
    }

    // ترتيب من الأحدث
    conversations.sort((a, b) {
      final aTime = a.lastMessage?.createdAt ?? a.createdAt ?? DateTime(2000);
      final bTime = b.lastMessage?.createdAt ?? b.createdAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return conversations;
  }

  Future<List<Message>> getMessages(String conversationId) async {
    final res = await client
        .from(SupabaseConstants.messagesTable)
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    return (res as List).map((j) => Message.fromJson(j)).toList();
  }

  Future<void> markConversationMessagesAsRead(String conversationId) async {
    final uid = client.auth.currentUser!.id;
    await client
        .from(SupabaseConstants.messagesTable)
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .eq('is_read', false)
        .neq('sender_id', uid);
  }

  Future<void> deleteConversationForCurrentUser(String conversationId) async {
    final uid = client.auth.currentUser!.id;
    await client
        .from(SupabaseConstants.convParticipants)
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', uid);
  }

  Stream<List<Message>> messagesStream(String conversationId) {
    return client
        .from(SupabaseConstants.messagesTable)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map((j) => Message.fromJson(j)).toList());
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final uid = client.auth.currentUser!.id;
    final d = await client
        .from(SupabaseConstants.messagesTable)
        .insert({
          'conversation_id': conversationId,
          'sender_id': uid,
          'content': content,
          'is_read': false,
        })
        .select()
        .single();
    return Message.fromJson(d);
  }

  /// ✅ إنشاء محادثة أو العودة للموجودة إذا كانت موجودة مسبقاً
  Future<String> getOrCreateConversation(String recipientId) async {
    final uid = client.auth.currentUser!.id;

    final participantRows = await client
        .from(SupabaseConstants.convParticipants)
        .select('conversation_id, user_id')
        .inFilter('user_id', [uid, recipientId]);

    final participantsByConversation = <String, Set<String>>{};
    for (final row in participantRows as List) {
      final conversationId = row['conversation_id']?.toString();
      final userId = row['user_id']?.toString();
      if (conversationId == null || userId == null) continue;

      participantsByConversation
          .putIfAbsent(conversationId, () => <String>{})
          .add(userId);
    }

    for (final entry in participantsByConversation.entries) {
      if (entry.value.contains(uid) && entry.value.contains(recipientId)) {
        return entry.key;
      }
    }

    // إنشاء محادثة جديدة
    final convData = await client
        .from(SupabaseConstants.conversationsTable)
        .insert({'created_at': DateTime.now().toIso8601String()})
        .select()
        .single();

    final convId = convData['id'] as String;
    await client.from(SupabaseConstants.convParticipants).insert([
      {'conversation_id': convId, 'user_id': uid},
      {'conversation_id': convId, 'user_id': recipientId},
    ]);

    return convId;
  }

  // ══════════════════ HELPER ══════════════════

  Map<String, dynamic> _flat(Map<String, dynamic> json) {
    final p = json['profiles'] as Map<String, dynamic>?;
    if (p == null) return json;
    return {
      ...json,
      'name': p['name'] ?? json['name'],
      'avatar': p['avatar'] ?? json['avatar'],
      'bio': p['bio'] ?? json['bio'],
      'industries': p['industries'] ?? json['industries'],
      'company': p['company'] ?? json['company'],
      'position': p['position'] ?? json['position'],
      'location': p['location'] ?? json['location'],
      'website': p['website'] ?? json['website'],
      'linkedin': p['linkedin'] ?? json['linkedin'],
    };
  }

  Map<String, dynamic> _flatProject(Map<String, dynamic> json) {
    final p = json['profiles'] as Map<String, dynamic>?;
    if (p == null) return json;
    return {
      ...json,
      'owner_name': p['name'] ?? json['owner_name'],
      'owner_avatar': p['avatar'] ?? json['owner_avatar'],
    };
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  Future<void> _ensureInvestorRecord({
    required String userId,
  }) async {
    await client.from(SupabaseConstants.investorsTable).upsert({
      'user_id': userId,
    }, onConflict: 'user_id', ignoreDuplicates: true);
  }
}

class SearchResults {
  final List<app.User> users;
  final List<Project> projects;
  final List<Investor> investors;
  final int total;

  SearchResults(
      {required this.users,
      required this.projects,
      required this.investors,
      required this.total});
}
