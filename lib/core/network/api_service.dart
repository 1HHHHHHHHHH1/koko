import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import 'dio_client.dart';
import '../../models/user.dart';
import '../../models/project.dart';
import '../../models/investor.dart';
import '../../models/match.dart';
import '../../models/message.dart';
import '../../models/like.dart';
import '../../models/rating.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ApiService(dioClient: dioClient);
});

class ApiService {
  final DioClient dioClient;

  ApiService({required this.dioClient});

  // ==================== AUTH ====================
  
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await dioClient.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
          'user_type': userType,
        },
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await dioClient.post(ApiConstants.logout);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== PROJECTS ====================
  
  Future<List<Project>> getProjects({
    int page = 1,
    int limit = 20,
    String? sort,
    String? industry,
    String? stage,
  }) async {
    try {
      final response = await dioClient.get(
        ApiConstants.projects,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (sort != null) 'sort': sort,
          if (industry != null) 'industry': industry,
          if (stage != null) 'stage': stage,
        },
      );
      return (response.data['data'] as List)
          .map((json) => Project.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Project> getProjectById(String id) async {
    try {
      final response = await dioClient.get(
        ApiConstants.projectById.replaceFirst('{id}', id),
      );
      return Project.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Project> createProject(Project project) async {
    try {
      final response = await dioClient.post(
        ApiConstants.projects,
        data: project.toJson(),
      );
      return Project.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Project> updateProject(String id, Project project) async {
    try {
      final response = await dioClient.put(
        ApiConstants.projectById.replaceFirst('{id}', id),
        data: project.toJson(),
      );
      return Project.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await dioClient.delete(
        ApiConstants.projectById.replaceFirst('{id}', id),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Project>> getMyProjects() async {
    try {
      final response = await dioClient.get(ApiConstants.myProjects);
      return (response.data['data'] as List)
          .map((json) => Project.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== INVESTORS ====================
  
  Future<List<Investor>> getInvestors({
    int page = 1,
    int limit = 20,
    String? sort,
    String? industry,
    String? stage,
  }) async {
    try {
      final response = await dioClient.get(
        ApiConstants.investors,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (sort != null) 'sort': sort,
          if (industry != null) 'industry': industry,
          if (stage != null) 'stage': stage,
        },
      );
      return (response.data['data'] as List)
          .map((json) => Investor.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Investor> getInvestorById(String id) async {
    try {
      final response = await dioClient.get(
        ApiConstants.investorById.replaceFirst('{id}', id),
      );
      return Investor.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateInvestorCriteria(InvestmentCriteria criteria) async {
    try {
      await dioClient.put(
        ApiConstants.investorCriteria,
        data: criteria.toJson(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== MATCHES ====================
  
  Future<List<Match>> getMatchedInvestors() async {
    try {
      final response = await dioClient.get(ApiConstants.matchedInvestors);
      return (response.data['data'] as List)
          .map((json) => Match.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Match>> getMatchedProjects() async {
    try {
      final response = await dioClient.get(ApiConstants.matchedProjects);
      return (response.data['data'] as List)
          .map((json) => Match.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== SEARCH ====================
  
  Future<SearchResults> search({
    required String query,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await dioClient.get(
        ApiConstants.search,
        queryParameters: {
          'q': query,
          if (type != null) 'type': type,
          'page': page,
          'limit': limit,
        },
      );
      return SearchResults.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== LIKES ====================
  
  Future<Like> createLike({
    required String targetId,
    required String targetType,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.likes,
        data: {
          'target_id': targetId,
          'target_type': targetType,
        },
      );
      return Like.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteLike(String id) async {
    try {
      await dioClient.delete(
        ApiConstants.likeById.replaceFirst('{id}', id),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Like>> getMyLikes() async {
    try {
      final response = await dioClient.get(ApiConstants.myLikes);
      return (response.data['data'] as List)
          .map((json) => Like.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== RATINGS ====================
  
  Future<Rating> createRating({
    required String targetId,
    required String targetType,
    required int score,
    String? comment,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.ratings,
        data: {
          'target_id': targetId,
          'target_type': targetType,
          'score': score,
          if (comment != null) 'comment': comment,
        },
      );
      return Rating.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<RatingSummary> getRatingSummary(String userId) async {
    try {
      final response = await dioClient.get(
        ApiConstants.ratingSummary.replaceFirst('{userId}', userId),
      );
      return RatingSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== MESSAGES ====================
  
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await dioClient.get(ApiConstants.conversations);
      return (response.data['data'] as List)
          .map((json) => Conversation.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await dioClient.get(
        ApiConstants.conversationById.replaceFirst('{id}', conversationId),
      );
      return (response.data['data'] as List)
          .map((json) => Message.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.messages,
        data: {
          'conversation_id': conversationId,
          'content': content,
        },
      );
      return Message.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Conversation> createConversation(String recipientId) async {
    try {
      final response = await dioClient.post(
        ApiConstants.conversations,
        data: {'recipient_id': recipientId},
      );
      return Conversation.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== ERROR HANDLING ====================
  
  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Unknown error';
        
        switch (statusCode) {
          case 400:
            return 'Bad request: $message';
          case 401:
            return 'Unauthorized: Please login again.';
          case 403:
            return 'Forbidden: You do not have permission.';
          case 404:
            return 'Not found: $message';
          case 422:
            return 'Validation error: $message';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return 'Error: $message';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

// Response Models
class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final User user;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      user: User.fromJson(json['user']),
    );
  }
}

class SearchResults {
  final List<User> users;
  final List<Project> projects;
  final List<Investor> investors;
  final int total;

  SearchResults({
    required this.users,
    required this.projects,
    required this.investors,
    required this.total,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    return SearchResults(
      users: (json['users'] as List? ?? [])
          .map((j) => User.fromJson(j))
          .toList(),
      projects: (json['projects'] as List? ?? [])
          .map((j) => Project.fromJson(j))
          .toList(),
      investors: (json['investors'] as List? ?? [])
          .map((j) => Investor.fromJson(j))
          .toList(),
      total: json['total'] ?? 0,
    );
  }
}
