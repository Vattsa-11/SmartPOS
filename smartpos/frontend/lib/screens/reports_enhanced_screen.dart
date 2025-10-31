import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/sale.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class ReportsEnhancedScreen extends StatefulWidget {
  const ReportsEnhancedScreen({super.key});

  @override
  State<ReportsEnhancedScreen> createState() => _ReportsEnhancedScreenState();
}

class _ReportsEnhancedScreenState extends State<ReportsEnhancedScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _error;
  List<Sale> _sales = [];
  
  // Date filters
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  
  // Computed stats
  double _totalSales = 0;
  int _totalTransactions = 0;
  int _itemsSold = 0;
  double _avgSale = 0;
  
  // Payment method stats
  Map<String, double> _paymentStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sales = await _apiService.getSales();
      
      // Filter by date range
      final filtered = sales.where((sale) {
        final saleDate = sale.saleDate;
        return saleDate.isAfter(_fromDate.subtract(const Duration(days: 1))) &&
               saleDate.isBefore(_toDate.add(const Duration(days: 1)));
      }).toList();
      
      // Calculate stats
      double totalSales = 0;
      int itemsSold = 0;
      Map<String, double> paymentStats = {};
      
      for (var sale in filtered) {
        totalSales += sale.totalAmount;
        // Sum quantities from all items in the sale
        itemsSold += sale.items.fold(0, (sum, item) => sum + item.quantity.toInt());
        
        final method = sale.paymentMethod;
        paymentStats[method] = (paymentStats[method] ?? 0) + sale.totalAmount;
      }
      
      setState(() {
        _sales = filtered;
        _totalSales = totalSales;
        _totalTransactions = filtered.length;
        _itemsSold = itemsSold;
        _avgSale = filtered.isEmpty ? 0 : totalSales / filtered.length;
        _paymentStats = paymentStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        title: const Text('📊 Sales Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateFilters(),
                      const SizedBox(height: 20),
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildPaymentMethodChart(),
                      const SizedBox(height: 24),
                      _buildSalesTrendChart(),
                      const SizedBox(height: 24),
                      _buildSalesTable(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error ?? 'Unknown error', style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDateField(
              label: '📅 From Date',
              date: _fromDate,
              onTap: () => _selectDate(context, true),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDateField(
              label: '📅 To Date',
              date: _toDate,
              onTap: () => _selectDate(context, false),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.search),
            label: const Text('Filter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Text(
          Formatters.formatDate(date),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          emoji: '💰',
          title: 'Total Sales',
          value: Formatters.formatCurrency(_totalSales),
          subtitle: 'This period',
          gradient: const LinearGradient(
            colors: [Color(0xFF3a4a5c), Color(0xFF2c3e50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _buildSummaryCard(
          emoji: '🛒',
          title: 'Transactions',
          value: _totalTransactions.toString(),
          subtitle: 'Completed sales',
          gradient: const LinearGradient(
            colors: [Color(0xFF455a64), Color(0xFF34495e)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _buildSummaryCard(
          emoji: '📦',
          title: 'Items Sold',
          value: _itemsSold.toString(),
          subtitle: 'Total units',
          gradient: const LinearGradient(
            colors: [Color(0xFF546e7a), Color(0xFF455a64)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _buildSummaryCard(
          emoji: '💵',
          title: 'Average Sale',
          value: Formatters.formatCurrency(_avgSale),
          subtitle: 'Per transaction',
          gradient: const LinearGradient(
            colors: [Color(0xFF607d8b), Color(0xFF546e7a)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String emoji,
    required String title,
    required String value,
    required String subtitle,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFecf0f1),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodChart() {
    if (_paymentStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💳', style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Methods',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Distribution by payment type',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _paymentStats.entries.map((entry) {
                  final percentage = (_totalSales > 0) ? (entry.value / _totalSales * 100) : 0;
                  return PieChartSectionData(
                    value: entry.value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    color: entry.key == 'Cash' ? AppColors.success : AppColors.primary,
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            children: _paymentStats.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: entry.key == 'Cash' ? AppColors.success : AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.key}: ${Formatters.formatCurrency(entry.value)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrendChart() {
    if (_sales.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group sales by date
    Map<DateTime, double> dailySales = {};
    for (var sale in _sales) {
      final date = DateTime(
        sale.saleDate.year,
        sale.saleDate.month,
        sale.saleDate.day,
      );
      dailySales[date] = (dailySales[date] ?? 0) + sale.totalAmount;
    }

    final sortedDates = dailySales.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dailySales[entry.value] ?? 0);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Daily sales over time',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: _totalSales / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sortedDates.length) return const Text('');
                        final date = sortedDates[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTable() {
    if (_sales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No sales in this period',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Sales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_sales.length} transactions',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Invoice')),
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Items')),
                DataColumn(label: Text('Payment')),
                DataColumn(label: Text('Amount')),
              ],
              rows: _sales.take(10).map((sale) {
                // Calculate total items for this sale
                final totalItems = sale.items.fold<int>(0, (sum, item) => sum + item.quantity.toInt());
                
                return DataRow(
                  cells: [
                    DataCell(Text(sale.invoiceNumber)),
                    DataCell(Text(Formatters.formatDate(sale.saleDate))),
                    DataCell(Text('$totalItems')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sale.paymentMethod == 'Cash'
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sale.paymentMethod,
                          style: TextStyle(
                            fontSize: 12,
                            color: sale.paymentMethod == 'Cash'
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        Formatters.formatCurrency(sale.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
