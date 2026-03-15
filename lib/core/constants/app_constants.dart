class AppConstants {
  static const String appName    = 'VentureBridge';
  static const String appVersion = '1.0.0';

  static const String userTypeEntrepreneur = 'entrepreneur';
  static const String userTypeInvestor     = 'investor';

  static const int defaultPageSize = 20;

  static const String searchTypeInvestor    = 'investor';
  static const String searchTypeEntrepreneur = 'entrepreneur';
  static const String searchTypeProject     = 'project';

  static const String sortNewest       = 'newest';
  static const String sortHighestRated = 'highest_rated';
  static const String sortMostLiked    = 'most_liked';

  static const List<String> investmentStages = [
    'Pre-Seed', 'Seed', 'Series A', 'Series B', 'Series C', 'Growth',
  ];

  static const List<String> industries = [
    'Technology', 'Healthcare', 'Finance', 'E-commerce', 'Education',
    'Real Estate', 'Manufacturing', 'Energy', 'Entertainment',
    'Food & Beverage', 'Transportation', 'Other',
  ];
}
