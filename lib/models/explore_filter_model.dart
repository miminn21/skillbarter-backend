class ExploreFilterModel {
  final int? kategoriId;
  final String? tipe; // 'dikuasai', 'dicari', or null for all
  final String? tingkat; // 'pemula', 'menengah', 'mahir', 'ahli'
  final String? searchQuery;
  final int page;
  final int limit;

  ExploreFilterModel({
    this.kategoriId,
    this.tipe,
    this.tingkat,
    this.searchQuery,
    this.page = 1,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (kategoriId != null) params['kategori'] = kategoriId.toString();
    if (tipe != null) params['tipe'] = tipe;
    if (tingkat != null) params['tingkat'] = tingkat;
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      params['search'] = searchQuery;
    }

    return params;
  }

  ExploreFilterModel copyWith({
    int? kategoriId,
    String? tipe,
    String? tingkat,
    String? searchQuery,
    int? page,
    int? limit,
  }) {
    return ExploreFilterModel(
      kategoriId: kategoriId ?? this.kategoriId,
      tipe: tipe ?? this.tipe,
      tingkat: tingkat ?? this.tingkat,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  void reset() {
    // Returns a new instance with default values
  }

  bool get hasActiveFilters {
    return kategoriId != null ||
        tipe != null ||
        tingkat != null ||
        (searchQuery != null && searchQuery!.isNotEmpty);
  }
}
