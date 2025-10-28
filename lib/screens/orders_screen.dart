import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import '../providers/user_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with TickerProviderStateMixin {
  Future<List<Order>>? _ordersFuture;
  late AnimationController _refreshController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isRefreshing = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _ordersFuture = _loadOrdersAndTrackChanges();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<List<Order>> _loadOrdersAndTrackChanges() async {
    try {
      final userEmail = Provider.of<UserProvider>(context, listen: false).user?.email ?? "";

      if (userEmail.isEmpty) {
        return <Order>[];
      }

      final orders = await ApiService().getOrders(userEmail: userEmail);
      await _trackOrderStatusChanges(orders);
      return orders;
    } catch (e) {
      final langCode = Localizations.localeOf(context).languageCode;
      throw Exception(langCode == 'ar'
          ? 'فشل في تحميل الطلبات. يرجى المحاولة مرة أخرى.'
          : 'Failed to load orders. Please try again.');
    }
  }

  Future<void> _refreshOrders() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    _refreshController.repeat();

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Minimum loading time for better UX
      setState(() {
        _ordersFuture = _loadOrdersAndTrackChanges();
      });

      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(isAr ? 'تم تحديث الطلبات بنجاح' : 'Orders refreshed successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF6FE0DA),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(isAr ? 'فشل في تحديث الطلبات' : 'Failed to refresh orders'),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      _refreshController.stop();
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _trackOrderStatusChanges(List<Order> orders) async {
    if (!mounted) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedStatuses = prefs.getString('order_statuses') ?? '{}';
    final Map<String, String> oldStatuses = Map<String, String>.from(json.decode(storedStatuses));
    final notifications = prefs.getStringList('notifications') ?? [];
    int unreadCount = prefs.getInt('unread_notifications') ?? 0;

    if (!mounted) {
      return;
    }

    final langCode = Localizations.localeOf(context).languageCode;

    for (final order in orders) {
      final orderId = order.id.toString();
      final currentStatus = order.status;
      final previousStatus = oldStatuses[orderId];

      if (previousStatus != null && previousStatus != currentStatus) {
        final previousText = _translateStatus(previousStatus, langCode);
        final currentText = _translateStatus(currentStatus, langCode);

        final notification = {
          'title': langCode == 'ar' ? 'تحديث حالة الطلب' : 'Order Status Update',
          'body': langCode == 'ar'
              ? 'تم تغيير حالة طلبك رقم #$orderId من "$previousText" إلى "$currentText"'
              : 'Your order #$orderId status changed from "$previousText" to "$currentText"',
          'time': DateTime.now().toIso8601String(),
          'type': 'order_update',
          'orderId': orderId,
          'orderStatus': currentStatus,
          'isRead': false,
        };

        notifications.insert(0, jsonEncode(notification));
        unreadCount++;
      }

      oldStatuses[orderId] = currentStatus;
    }

    await prefs.setStringList('notifications', notifications);
    await prefs.setInt('unread_notifications', unreadCount);
    await prefs.setString('order_statuses', json.encode(oldStatuses));
  }

  String _translateStatus(String status, String langCode) {
    final ar = {
      'pending': 'قيد المعالجة',
      'processing': 'قيد التنفيذ',
      'completed': 'مكتمل',
      'cancelled': 'ملغي',
      'on-hold': 'قيد الانتظار',
      'refunded': 'مسترد',
      'failed': 'فشل',
    };

    final en = {
      'pending': 'Pending',
      'processing': 'Processing',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'on-hold': 'On Hold',
      'refunded': 'Refunded',
      'failed': 'Failed',
    };

    final map = langCode == 'ar' ? ar : en;
    return map[status.toLowerCase()] ?? status;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'processing':
        return const Color(0xFF6FE0DA);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'cancelled':
      case 'failed':
        return const Color(0xFFF44336);
      case 'on-hold':
        return const Color(0xFF9E9E9E);
      case 'refunded':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF6FE0DA);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.autorenew;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      case 'failed':
        return Icons.error;
      case 'on-hold':
        return Icons.pause_circle;
      case 'refunded':
        return Icons.keyboard_return;
      default:
        return Icons.shopping_bag;
    }
  }

  List<Order> _getFilteredOrders(List<Order> orders) {
    if (_selectedFilter == 'all') return orders;
    return orders.where((order) => order.status.toLowerCase() == _selectedFilter).toList();
  }

  Widget _buildFilterChips() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final filters = [
      {
        'key': 'all',
        'label': isAr ? 'الكل' : 'All',
        'icon': Icons.all_inclusive,
      },
      {
        'key': 'pending',
        'label': isAr ? 'قيد المعالجة' : 'Pending',
        'icon': Icons.schedule,
      },
      {
        'key': 'processing',
        'label': isAr ? 'قيد التنفيذ' : 'Processing',
        'icon': Icons.autorenew,
      },
      {
        'key': 'completed',
        'label': isAr ? 'مكتمل' : 'Completed',
        'icon': Icons.check_circle,
      },
      {
        'key': 'cancelled',
        'label': isAr ? 'ملغي' : 'Cancelled',
        'icon': Icons.cancel,
      },
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['key'];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['key'] as String;
                });
              },
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF1A2543),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF1A2543),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF6FE0DA),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFF6FE0DA) : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF6FE0DA).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: Color(0xFF6FE0DA),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isAr ? 'لا توجد طلبات حتى الآن' : 'No orders yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2543),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'ستظهر طلباتك هنا بمجرد إجراء أول عملية شراء'
                  : 'Your orders will appear here after your first purchase',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshOrders,
              icon: const Icon(Icons.refresh),
              label: Text(isAr ? 'تحديث' : 'Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FE0DA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'حدث خطأ في تحميل الطلبات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2543),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _ordersFuture = _loadOrdersAndTrackChanges();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6FE0DA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(
          isAr ? "طلباتي" : "My Orders",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1A2543),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          AnimatedBuilder(
            animation: _refreshController,
            builder: (context, child) {
              return IconButton(
                onPressed: _isRefreshing ? null : _refreshOrders,
                icon: Transform.rotate(
                  angle: _refreshController.value * 2.0 * 3.14159,
                  child: const Icon(Icons.refresh),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A2543), Color(0xFF2A3A5A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                _buildFilterChips(),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Orders content
          Expanded(
            child: _ordersFuture == null
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6FE0DA)))
                : FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6FE0DA)),
                  );
                } else if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final allOrders = snapshot.data!;
                final filteredOrders = _getFilteredOrders(allOrders);

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAr ? 'لا توجد طلبات لهذا التصنيف' : 'No orders for this filter',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _refreshOrders,
                    color: const Color(0xFF6FE0DA),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _buildOrderCard(order, index);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, int index) {
    final langCode = Localizations.localeOf(context).languageCode;
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);

    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, const Color(0xFFF9FBFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showOrderDetails(order, langCode),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Header row
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Icon(statusIcon, color: statusColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (langCode == 'ar' ? "طلب رقم:" : "Order #") + " #${order.id}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Color(0xFF1A2543),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      _translateStatus(order.status, langCode),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (order.canBeCancelled)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  elevation: 0,
                                ),
                                onPressed: () => _confirmCancelOrder(order.id),
                                child: const Text(
                                  'إلغاء',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              )
                            else
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF1A2543),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Details row
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                Icons.calendar_today_outlined,
                                langCode == 'ar' ? 'التاريخ' : 'Date',
                                order.dateCreated.substring(0, 10),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade300,
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                Icons.attach_money,
                                langCode == 'ar' ? 'المقدم' : 'Down Payment',
                                order.metaData.containsKey('custom_installment')
                                    ? "${(double.tryParse(jsonDecode(order.metaData['custom_installment'])['downPayment'].toString()) ?? 0).toInt()} ${langCode == 'ar' ? 'ر.ق' : 'QAR'}"
                                    : "${order.total} ${langCode == 'ar' ? 'ر.ق' : 'QAR'}",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6FE0DA), size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2543),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancelOrder(int orderId) async {
    final langCode = Localizations.localeOf(context).languageCode;
    final isAr = langCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Text(isAr ? 'تأكيد الإلغاء' : 'Confirm Cancellation'),
          ],
        ),
        content: Text(
          isAr
              ? 'هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟ لا يمكن التراجع عن هذا الإجراء.'
              : 'Are you sure you want to cancel this order? This action cannot be undone.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(isAr ? 'تأكيد الإلغاء' : 'Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6FE0DA)),
        ),
      );

      try {
        final success = await ApiService().cancelOrder(orderId);
        Navigator.pop(context); // Close loading

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(isAr ? 'تم إلغاء الطلب بنجاح' : 'Order cancelled successfully'),
                ],
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
          setState(() {
            _ordersFuture = _loadOrdersAndTrackChanges();
          });
        } else {
          throw Exception(isAr ? 'فشل في إلغاء الطلب' : 'Failed to cancel order');
        }
      } catch (e) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(isAr ? 'فشل في إلغاء الطلب. يرجى المحاولة مرة أخرى.' : 'Failed to cancel the order. Please try again.'),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showOrderDetails(Order order, String langCode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: _buildOrderDetailsContent(order, langCode),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderDetailsContent(Order order, String langCode) {
    final Color primaryColor = const Color(0xFF1A2543);
    final Color accentColor = const Color(0xFF6FE0DA);
    final statusColor = _getStatusColor(order.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(_getStatusIcon(order.status), color: statusColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (langCode == 'ar' ? "تفاصيل الطلب" : "Order Details") + " #${order.id}",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _translateStatus(order.status, langCode),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Order Information Card
        Container(
          decoration: BoxDecoration(

            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                langCode == 'ar' ? "معلومات الطلب" : "Order Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              _buildIconInfoRow(
                Icons.calendar_today_outlined,
                langCode == 'ar' ? "تاريخ الإنشاء" : "Created Date",
                order.dateCreated.substring(0, 10),
                primaryColor,
                accentColor,
              ),

              _buildIconInfoRow(
                Icons.attach_money,
                langCode == 'ar' ? "المقدم" : "Down Payment",
                order.metaData.containsKey('custom_installment')
                    ? "${(double.tryParse(jsonDecode(order.metaData['custom_installment'])['downPayment'].toString()) ?? 0).toInt()} ${langCode == 'ar' ? 'ر.ق' : 'QAR'}"
                    : "${order.total} ${langCode == 'ar' ? 'ر.ق' : 'QAR'}",
                primaryColor,
                accentColor,
              ),

              _buildIconInfoRow(
                Icons.info_outline,
                langCode == 'ar' ? "الحالة الحالية" : "Current Status",
                _translateStatus(order.status, langCode),
                primaryColor,
                statusColor,
              ),
            ],
          ),
        ),

        // Installment Plan (if exists)
        if (order.metaData.containsKey('custom_installment')) ...[
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(

              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.payment, color: primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      langCode == 'ar' ? "خطة التقسيط" : "Installment Plan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Builder(
                  builder: (context) {
                    final plan = jsonDecode(order.metaData['custom_installment']);
                    return Column(
                      children: [
                        _buildIconInfoRow(
                          Icons.payment,
                          langCode == 'ar' ? "الدفعة الأولى" : "First Payment",
                          "${(double.tryParse(plan['downPayment'].toString()) ?? 0).toInt()} ${langCode == 'ar' ? 'ر.ق' : 'QAR'}",
                          primaryColor,
                          accentColor,
                        ),

                        _buildIconInfoRow(
                          Icons.account_balance_wallet,
                          langCode == 'ar' ? "المبلغ المتبقي" : "Remaining Amount",
                          "${(double.tryParse(plan['remainingAmount'].toString()) ?? 0).toInt()} ${langCode == 'ar' ? 'ر.ق' : 'QAR'}",
                          primaryColor,
                          accentColor,
                        ),

                        _buildIconInfoRow(
                          Icons.calendar_view_month,
                          langCode == 'ar' ? "قيمة القسط الشهري" : "Monthly Installment",
                          "${(double.tryParse(plan['monthlyPayment'].toString()) ?? 0).toInt()} ${langCode == 'ar' ? 'ر.ق' : 'QAR'}",
                          primaryColor,
                          accentColor,
                        ),

                        _buildIconInfoRow(
                          Icons.timelapse,
                          langCode == 'ar' ? "عدد الأشهر" : "Months",
                          "${plan['numberOfInstallments']}",
                          primaryColor,
                          accentColor,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: Text(langCode == 'ar' ? "إغلاق" : "Close"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (order.status.toLowerCase() == 'completed') ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Handle reorder functionality
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(langCode == 'ar' ? 'سيتم إضافة إعادة الطلب قريباً' : 'Reorder will be available soon'),
                          ],
                        ),
                        backgroundColor: accentColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(langCode == 'ar' ? "إعادة الطلب" : "Reorder"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildIconInfoRow(IconData icon, String label, String value, Color primaryColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: primaryColor,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}