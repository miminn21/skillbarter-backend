import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/barter_provider.dart';
import '../../widgets/offer_card.dart';
import '../../services/app_localizations.dart';
import 'offer_detail_screen.dart';
import '../skills/add_skill_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({Key? key}) : super(key: key);

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Initialize Header Animation
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Header Slide (Top Down)
    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart),
          ),
        );

    // Header Fade
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _headerController.forward();

    // Load data after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedStatus = null;
      });
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final provider = Provider.of<BarterProvider>(context, listen: false);

    switch (_tabController.index) {
      case 0: // Sent
        await provider.fetchSentOffers(status: _selectedStatus);
        break;
      case 1: // Received (exclude ditolak)
        // Fetch all received offers, then filter out ditolak on frontend
        await provider.fetchReceivedOffersExcludingRejected(
          status: _selectedStatus,
        );
        break;
      case 2: // Rejected (ALL rejected offers - sent + received)
        await provider.fetchAllRejectedOffers();
        break;
      case 3: // History
        await provider.fetchHistory();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Soft premium background
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
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      const Color(0xFF1E88E5), // Lighter blue
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          // AppLocalizations.of(context)!.translate('trans_title'),
                          'Transaksi Barter', // Keep for now or replace if desired. Logic suggests replace.
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Custom Tab Bar
                    Container(
                      height: 55, // Increased slightly for better spacing
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
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
                          fontSize: 12,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('tab_sent'),
                                ),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_rounded, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('tab_received'),
                                ),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel_rounded, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('tab_rejected'),
                                ),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.translate('tab_history'),
                                ),
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

          // Content
          Expanded(
            child: Column(
              children: [
                // Filter chips (hide for Rejected and History tabs)
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    return (_tabController.index != 2 &&
                            _tabController.index != 3)
                        ? _buildFilterChips()
                        : const SizedBox(height: 16); // Spacing for consistency
                  },
                ),

                // Tab views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOffersList(isSent: true),
                      _buildOffersList(isSent: false),
                      _buildRejectedList(),
                      _buildHistoryList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSkillScreen()),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.translate('fab_create'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: Text(
                AppLocalizations.of(context)!.translate('filter_all'),
              ),
              selected: _selectedStatus == null,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = null;
                });
                _loadData();
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(
                AppLocalizations.of(context)!.translate('filter_waiting'),
              ),
              selected: _selectedStatus == 'menunggu',
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? 'menunggu' : null;
                });
                _loadData();
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(
                AppLocalizations.of(context)!.translate('filter_accepted'),
              ),
              selected: _selectedStatus == 'diterima',
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? 'diterima' : null;
                });
                _loadData();
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(
                AppLocalizations.of(context)!.translate('filter_ongoing'),
              ),
              selected: _selectedStatus == 'berlangsung',
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? 'berlangsung' : null;
                });
                _loadData();
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(
                AppLocalizations.of(context)!.translate('filter_completed'),
              ),
              selected: _selectedStatus == 'selesai',
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? 'selesai' : null;
                });
                _loadData();
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(
                AppLocalizations.of(context)!.translate('filter_rejected'),
              ),
              selected: _selectedStatus == 'ditolak',
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? 'ditolak' : null;
                });
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersList({required bool isSent}) {
    return Consumer<BarterProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    AppLocalizations.of(context)!.translate('btn_retry'),
                  ),
                ),
              ],
            ),
          );
        }

        final offers = isSent ? provider.sentOffers : provider.receivedOffers;

        if (offers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSent ? Icons.send_outlined : Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isSent
                      ? AppLocalizations.of(context)!.translate('empty_sent')
                      : AppLocalizations.of(
                          context,
                        )!.translate('empty_received'),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return OfferCard(
                offer: offer,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OfferDetailScreen(offerId: offer.id!),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return Consumer<BarterProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    AppLocalizations.of(context)!.translate('btn_retry'),
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.translate('empty_history'),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                if (_selectedStatus == 'ditolak')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      AppLocalizations.of(context)!.translate('empty_rejected'),
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.history.length,
            itemBuilder: (context, index) {
              final offer = provider.history[index];
              return OfferCard(
                offer: offer,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OfferDetailScreen(offerId: offer.id!),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRejectedList() {
    return Consumer<BarterProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    AppLocalizations.of(context)!.translate('btn_retry'),
                  ),
                ),
              ],
            ),
          );
        }

        final rejectedOffers = provider.receivedOffers;

        if (rejectedOffers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.translate('empty_rejected'),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rejectedOffers.length,
            itemBuilder: (context, index) {
              final offer = rejectedOffers[index];
              return OfferCard(
                offer: offer,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OfferDetailScreen(offerId: offer.id!),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
