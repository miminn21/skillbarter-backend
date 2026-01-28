import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/skill_provider.dart';
import '../../models/skill_model.dart';
import '../../widgets/custom_notification.dart';
import 'add_skill_screen.dart';
import 'edit_skill_screen.dart';
import 'skill_detail_screen.dart';

class SkillListScreen extends StatefulWidget {
  const SkillListScreen({super.key});

  @override
  State<SkillListScreen> createState() => _SkillListScreenState();
}

class _SkillListScreenState extends State<SkillListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load skills on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSkills();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSkills() async {
    final skillProvider = context.read<SkillProvider>();
    await skillProvider.loadCategories();
    await skillProvider.loadUserSkills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keahlian Saya'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dikuasai'),
            Tab(text: 'Dicari'),
          ],
        ),
      ),
      body: Consumer<SkillProvider>(
        builder: (context, skillProvider, _) {
          if (skillProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildSkillList(skillProvider.dikuasaiSkills, 'dikuasai'),
              _buildSkillList(skillProvider.dicariSkills, 'dicari'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSkillScreen()),
          );

          if (result == true) {
            _loadSkills();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSkillList(List<SkillModel> skills, String tipe) {
    if (skills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tipe == 'dikuasai' ? Icons.workspace_premium : Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              tipe == 'dikuasai'
                  ? 'Belum ada skill yang dikuasai'
                  : 'Belum ada skill yang dicari',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddSkillScreen(initialTipe: tipe),
                  ),
                );

                if (result == true) {
                  _loadSkills();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Skill'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSkills,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: skills.length,
        itemBuilder: (context, index) {
          final skill = skills[index];
          return _buildSkillCard(skill);
        },
      ),
    );
  }

  Widget _buildSkillCard(SkillModel skill) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SkillDetailScreen(skillId: skill.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(skill.kategoriIkon),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Skill Name & Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill.namaKeahlian,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          skill.namaKategori ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Verified Badge
                  if (skill.statusVerifikasi)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Tingkat & Harga
              Row(
                children: [
                  _buildChip(
                    _getTingkatLabel(skill.tingkat),
                    _getTingkatColor(skill.tingkat),
                  ),
                  const SizedBox(width: 8),
                  _buildChip('${skill.hargaPerJam} SC/jam', Colors.amber),
                ],
              ),

              // Deskripsi
              if (skill.deskripsi != null && skill.deskripsi!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  skill.deskripsi!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],

              // Actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditSkillScreen(skill: skill),
                        ),
                      );

                      if (result == true) {
                        _loadSkills();
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(skill),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Hapus'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color.withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? icon) {
    switch (icon) {
      case 'computer':
        return Icons.computer;
      case 'palette':
        return Icons.palette;
      case 'language':
        return Icons.language;
      case 'music_note':
        return Icons.music_note;
      default:
        return Icons.star;
    }
  }

  String _getTingkatLabel(String tingkat) {
    switch (tingkat) {
      case 'pemula':
        return 'Pemula';
      case 'menengah':
        return 'Menengah';
      case 'mahir':
        return 'Mahir';
      case 'ahli':
        return 'Ahli';
      default:
        return tingkat;
    }
  }

  Color _getTingkatColor(String tingkat) {
    switch (tingkat) {
      case 'pemula':
        return Colors.blue;
      case 'menengah':
        return Colors.green;
      case 'mahir':
        return Colors.orange;
      case 'ahli':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmDelete(SkillModel skill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Skill'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${skill.namaKeahlian}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final skillProvider = context.read<SkillProvider>();
      final success = await skillProvider.deleteSkill(skill.id);

      if (!mounted) return;

      if (success) {
        CustomNotification.showSuccess(context, '🗑️ Skill berhasil dihapus');
      } else {
        CustomNotification.showError(
          context,
          skillProvider.error ?? 'Gagal menghapus skill',
        );
      }
    }
  }
}
