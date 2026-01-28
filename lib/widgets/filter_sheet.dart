import 'package:flutter/material.dart';
import '../models/explore_filter_model.dart';
import '../models/category_model.dart';

class FilterSheet extends StatefulWidget {
  final ExploreFilterModel currentFilter;
  final List<CategoryModel> categories;
  final Function(ExploreFilterModel) onApply;

  const FilterSheet({
    super.key,
    required this.currentFilter,
    required this.categories,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late ExploreFilterModel _filter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    _searchController.text = _filter.searchQuery ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _filter = ExploreFilterModel();
      _searchController.clear();
    });
  }

  void _apply() {
    final updatedFilter = _filter.copyWith(
      searchQuery: _searchController.text.isEmpty
          ? null
          : _searchController.text,
    );
    widget.onApply(updatedFilter);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Skill',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
              const SizedBox(height: 20),

              // Search field
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Cari skill',
                  hintText: 'Nama atau deskripsi skill...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 20),

              // Category dropdown
              DropdownButtonFormField<int>(
                value: _filter.kategoriId,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Semua Kategori'),
                  ),
                  ...widget.categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.namaKategori),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _filter = _filter.copyWith(kategoriId: value);
                  });
                },
              ),
              const SizedBox(height: 20),

              // Tipe section
              const Text(
                'Tipe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildChoiceChip('Semua', null),
                  _buildChoiceChip('Dikuasai', 'dikuasai'),
                  _buildChoiceChip('Dicari', 'dicari'),
                ],
              ),
              const SizedBox(height: 20),

              // Tingkat section
              const Text(
                'Tingkat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildTingkatChip('Semua', null),
                  _buildTingkatChip('Pemula', 'pemula'),
                  _buildTingkatChip('Menengah', 'menengah'),
                  _buildTingkatChip('Mahir', 'mahir'),
                  _buildTingkatChip('Ahli', 'ahli'),
                ],
              ),
              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Terapkan Filter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, String? value) {
    final isSelected = _filter.tipe == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = _filter.copyWith(tipe: selected ? value : null);
        });
      },
    );
  }

  Widget _buildTingkatChip(String label, String? value) {
    final isSelected = _filter.tingkat == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = _filter.copyWith(tingkat: selected ? value : null);
        });
      },
    );
  }
}
