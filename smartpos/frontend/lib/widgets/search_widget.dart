import 'package:flutter/material.dart';

class SearchDelegate extends StatefulWidget {
  final String hintText;
  final Function(String) onSearchChanged;
  final Function()? onClearSearch;

  const SearchDelegate({
    Key? key,
    required this.hintText,
    required this.onSearchChanged,
    this.onClearSearch,
  }) : super(key: key);

  @override
  _SearchDelegateState createState() => _SearchDelegateState();
}

class _SearchDelegateState extends State<SearchDelegate> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    widget.onSearchChanged('');
    if (widget.onClearSearch != null) {
      widget.onClearSearch!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: _isSearching
          ? Card(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _stopSearch,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                ),
                onChanged: widget.onSearchChanged,
              ),
            )
          : Card(
              child: ListTile(
                leading: const Icon(Icons.search),
                title: Text(
                  widget.hintText,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                onTap: _startSearch,
              ),
            ),
    );
  }
}

class SearchBar extends StatefulWidget {
  final String hintText;
  final Function(String) onSearchChanged;
  final bool showFilterButton;
  final Function()? onFilterTap;

  const SearchBar({
    Key? key,
    required this.hintText,
    required this.onSearchChanged,
    this.showFilterButton = false,
    this.onFilterTap,
  }) : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      widget.onSearchChanged('');
                      setState(() {});
                    },
                  ),
                if (widget.showFilterButton)
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: widget.onFilterTap,
                  ),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 15.0,
            ),
          ),
          onChanged: (value) {
            widget.onSearchChanged(value);
            setState(() {});
          },
        ),
      ),
    );
  }
}

// Filter Bottom Sheet for search
class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersApplied;

  const FilterBottomSheet({
    Key? key,
    required this.currentFilters,
    required this.onFiltersApplied,
  }) : super(key: key);

  @override
  _FilterBottomSheetState createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _tempFilters;

  @override
  void initState() {
    super.initState();
    _tempFilters = Map.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempFilters.clear();
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const Divider(),
          
          // Category Filter (for products)
          if (_tempFilters.containsKey('category')) ...[
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: [
                'All',
                'Grocery',
                'Snacks',
                'Beverages',
                'Electronics',
                'Stationery',
                'Cosmetics',
                'Clothing',
                'Others',
              ].map((category) {
                final isSelected = _tempFilters['category'] == category ||
                    (_tempFilters['category'] == null && category == 'All');
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _tempFilters['category'] = 
                          category == 'All' ? null : category;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Stock Status Filter (for inventory)
          if (_tempFilters.containsKey('stockStatus')) ...[
            Text(
              'Stock Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: [
                'All',
                'In Stock',
                'Low Stock',
                'Out of Stock',
              ].map((status) {
                final isSelected = _tempFilters['stockStatus'] == status ||
                    (_tempFilters['stockStatus'] == null && status == 'All');
                return FilterChip(
                  label: Text(status),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _tempFilters['stockStatus'] = 
                          status == 'All' ? null : status;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Price Range Filter
          if (_tempFilters.containsKey('priceRange')) ...[
            Text(
              'Price Range',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: RangeValues(
                _tempFilters['priceRange']?['min']?.toDouble() ?? 0.0,
                _tempFilters['priceRange']?['max']?.toDouble() ?? 1000.0,
              ),
              min: 0.0,
              max: 1000.0,
              divisions: 20,
              labels: RangeLabels(
                '₹${(_tempFilters['priceRange']?['min'] ?? 0).toString()}',
                '₹${(_tempFilters['priceRange']?['max'] ?? 1000).toString()}',
              ),
              onChanged: (values) {
                setState(() {
                  _tempFilters['priceRange'] = {
                    'min': values.start.round(),
                    'max': values.end.round(),
                  };
                });
              },
            ),
            const SizedBox(height: 16),
          ],

          // Apply and Cancel buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFiltersApplied(_tempFilters);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}