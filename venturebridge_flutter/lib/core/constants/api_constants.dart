class ApiConstants {
  // Base URL - Configure this to your backend
  static const String baseUrl = 'https://your-backend-api.com';
  
  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  
  // Projects Endpoints
  static const String projects = '/projects';
  static const String projectById = '/projects/{id}';
  static const String myProjects = '/projects/my';
  
  // Investors Endpoints
  static const String investors = '/investors';
  static const String investorById = '/investors/{id}';
  static const String investorCriteria = '/investors/criteria';
  
  // Matches Endpoints
  static const String matchedInvestors = '/matches/investors';
  static const String matchedProjects = '/matches/projects';
  
  // Search Endpoint
  static const String search = '/search';
  
  // Likes Endpoints
  static const String likes = '/likes';
  static const String likeById = '/likes/{id}';
  static const String myLikes = '/likes/my';
  
  // Ratings Endpoints
  static const String ratings = '/ratings';
  static const String ratingSummary = '/ratings/summary/{userId}';
  
  // Messages Endpoints
  static const String messages = '/messages';
  static const String conversations = '/messages/conversations';
  static const String conversationById = '/messages/conversations/{id}';
}
