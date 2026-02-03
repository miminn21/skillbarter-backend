import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/barter_provider.dart';
import '../../widgets/offer_card.dart';
import 'offer_detail_screen.dart';
import '../skills/add_skill_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({Key? key}) : super(key: key);

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Load data after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      backgroundColor: const Color(0xFFF8F9FD), // Soft premium background
      body: Column(
        children: [
          // Custom Gradient Header
          Container(
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
                      'Transaksi Barter',
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
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('Terkirim'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('Diterima'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('Ditolak'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('Riwayat'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
        label: const Text(
          'Buat Barter',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
              label: const Text('Semua'),
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
              label: const Text('Menunggu'),
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
              label: const Text('Diterima'),
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
              label: const Text('Berlangsung'),
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
              label: const Text('Selesai'),
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
              label: const Text('Ditolak'),
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
                  label: const Text('Coba Lagi'),
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
                      ? 'Belum ada penawaran terkirim'
                      : 'Belum ada penawaran diterima',
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
                  label: const Text('Coba Lagi'),
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
                  'Belum ada riwayat transaksi',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                if (_selectedStatus == 'ditolak')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Tidak ada penawaran yang ditolak',
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
                  label: const Text('Coba Lagi'),
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
                  'Tidak ada penawaran yang ditolak',
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
