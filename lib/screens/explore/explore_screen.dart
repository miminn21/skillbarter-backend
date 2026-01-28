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
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late TabController _tabController;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    // Load data after build completes to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      appBar: AppBar(
        title: const Text('Jelajah Skill'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dikuasai'),
            Tab(text: 'Dicari'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari skill...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context.read<ExploreProvider>().searchSkills(
                                  '',
                                );
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (value) {
                      context.read<ExploreProvider>().searchSkills(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterSheet,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                  ),
                ),
              ],
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
