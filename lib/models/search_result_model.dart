class SearchResult<T> {
  final List<T> items;
  final bool hasMore;
  final int? nextOffset;
  final int totalCount;

  SearchResult({
    required this.items,
    required this.hasMore,
    this.nextOffset,
    this.totalCount = 0,
  });

  factory SearchResult.empty() => SearchResult(
    items: [],
    hasMore: false,
    nextOffset: null,
    totalCount: 0,
  );
}

class UserSuggestion {
  final String id;
  final String username;
  final String displayName;
  final String? profileImageUrl;
  final bool isVerified;

  UserSuggestion({
    required this.id,
    required this.username,
    required this.displayName,
    this.profileImageUrl,
    required this.isVerified,
  });

  factory UserSuggestion.fromJson(Map<String, dynamic> json) {
    return UserSuggestion(
      id: json['id'],
      username: json['username'],
      displayName: json['display_name'] ?? '',
      profileImageUrl: json['profile_image_url'],
      isVerified: json['is_verified'] ?? false,
    );
  }
}

class RecentSearch {
  final String query;
  final SearchType type;
  final DateTime searchedAt;

  RecentSearch({
    required this.query,
    required this.type,
    required this.searchedAt,
  });

  factory RecentSearch.fromJson(Map<String, dynamic> json) {
    return RecentSearch(
      query: json['query'],
      type: SearchType.fromValue(json['search_type']),
      searchedAt: DateTime.parse(json['searched_at']),
    );
  }
}

enum SearchType {
  users('users'),
  posts('posts'),
  hashtags('hashtags');

  const SearchType(this.value);
  final String value;

  static SearchType fromValue(String value) {
    return SearchType.values.firstWhere((e) => e.value == value);
  }
}

enum FollowType { followers, following }