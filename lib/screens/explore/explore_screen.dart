import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/explore_provider.dart';
import '../../providers/skill_provider.dart';
import '../../widgets/skill_card.dart';
import '../../widgets/filter_sheet.dart';
import '../skills/skill_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late TabController _tabController;
  late AnimationController _headerController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _searchSlideAnimation;
  late Animation<double> _searchFadeAnimation;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    // Initialize Header Animation
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Header: Slide from Top (-1.0)
    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart),
          ),
        );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Search Bar: Slide from Bottom (slightly)
    _searchSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutQuart),
          ),
        );

    _searchFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _headerController.forward();

    // Load data after build completes to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadData();
    }
  }

  void _loadData() {
    final exploreProvider = context.read<ExploreProvider>();
    final tipe = _tabController.index == 0 ? 'dikuasai' : 'dicari';
    exploreProvider.applyFilter(
      exploreProvider.currentFilter.copyWith(tipe: tipe),
    );

    // Load categories for filter
    final skillProvider = context.read<SkillProvider>();
    if (skillProvider.categories.isEmpty) {
      skillProvider.loadCategories();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<ExploreProvider>().loadMoreSkills();
    }
  }

  void _showFilterSheet() {
    final exploreProvider = context.read<ExploreProvider>();
    final skillProvider = context.read<SkillProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterSheet(
        currentFilter: exploreProvider.currentFilter,
        categories: skillProvider.categories,
        onApply: (filter) {
          exploreProvider.applyFilter(filter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        children: [
          // Custom Gradient Header with Animation
          SlideTransition(
            position: _headerSlideAnimation,
            child: FadeTransition(
              opacity: _headerFadeAnimation,
              child: Container(
                padding: const EdgeInsets.only(
                  top: 50,
                  left: 24,
                  right: 24,
                  bottom: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      const Color(0xFF1E88E5),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Jelajah Skill',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isGridView
                                  ? Icons.view_list_rounded
                                  : Icons.grid_view_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isGridView = !_isGridView;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Custom Tab Bar
                    Container(
                      height: 50,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.white.withOpacity(0.9),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.workspace_premium_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Dikuasai'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Dicari'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search bar
          SlideTransition(
            position: _searchSlideAnimation,
            child: FadeTransition(
              opacity: _searchFadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari skill...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Colors.grey,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      context
                                          .read<ExploreProvider>()
                                          .searchSkills('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                          onSubmitted: (value) {
                            context.read<ExploreProvider>().searchSkills(value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_list_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: _showFilterSheet,
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Active filters chips
          Consumer<ExploreProvider>(
            builder: (context, provider, _) {
              if (!provider.currentFilter.hasActiveFilters) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (provider.currentFilter.searchQuery != null)
                      _buildFilterChip(
                        'Pencarian: ${provider.currentFilter.searchQuery}',
                        () => provider.searchSkills(''),
                      ),
                    if (provider.currentFilter.tipe != null)
                      _buildFilterChip(
                        'Tipe: ${provider.currentFilter.tipe}',
                        () => provider.applyFilter(
                          provider.currentFilter.copyWith(tipe: null),
                        ),
                      ),
                    if (provider.currentFilter.tingkat != null)
                      _buildFilterChip(
                        'Tingkat: ${provider.currentFilter.tingkat}',
                        () => provider.applyFilter(
                          provider.currentFilter.copyWith(tingkat: null),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () => provider.clearFilter(),
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Hapus Semua'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Skills grid/list
          Expanded(
            child: Consumer<ExploreProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.exploreSkills.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.exploreSkills.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(provider.error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.exploreSkills.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada skill ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => provider.clearFilter(),
                          child: const Text('Hapus Filter'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadExploreSkills(refresh: true),
                  child: _isGridView
                      ? _buildGridView(provider)
                      : _buildListView(provider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(ExploreProvider provider) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount:
          provider.exploreSkills.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.exploreSkills.length) {
          return const Center(child: CircularProgressIndicator());
        }

        final skill = provider.exploreSkills[index];
        return SkillCard(
          skill: skill,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SkillDetailScreen(skillId: skill.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(ExploreProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount:
          provider.exploreSkills.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.exploreSkills.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final skill = provider.exploreSkills[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkillCard(
            skill: skill,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SkillDetailScreen(skillId: skill.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDelete,
      ),
    );
  }
}
