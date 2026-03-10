class AppConstants {
  // App Info
  static const String appName = 'VentureBridge';
  static const String appVersion = '1.0.0';
  
  // User Types
  static const String userTypeEntrepreneur = 'entrepreneur';
  static const String userTypeInvestor = 'investor';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String userTypeKey = 'user_type';
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Search Types
  static const String searchTypeInvestor = 'investor';
  static const String searchTypeEntrepreneur = 'entrepreneur';
  static const String searchTypeProject = 'project';
  
  // Sort Options
  static const String sortNewest = 'newest';
  static const String sortHighestRated = 'highest_rated';
  static const String sortMostLiked = 'most_liked';
  
  // Investment Stages
  static const List<String> investmentStages = [
    'Pre-Seed',
    'Seed',
    'Series A',
    'Series B',
    'Series C',
    'Growth',
  ];
  
  // Industries
  static const List<String> industries = [
    'Technology',
    'Healthcare',
    'Finance',
    'E-commerce',
    'Education',
    'Real Estate',
    'Manufacturing',
    'Energy',
    'Entertainment',
    'Food & Beverage',
    'Transportation',
    'Other',
  ];
}
