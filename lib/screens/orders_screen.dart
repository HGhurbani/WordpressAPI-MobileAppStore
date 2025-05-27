import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../Models/order.dart';
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
      final orders = await ApiService().getOrders(userEmail: userEmail);
      await _trackOrderStatusChanges(orders);
      return orders;
    } catch (e) {
      throw Exception('فشل في تحميل الطلبات. يرجى المحاولة مرة أخرى.');
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('تم تحديث الطلبات بنجاح'),
            ],
          ),
          backgroundColor: const Color(0xFF6FE0DA),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('فشل في تحديث الطلبات'),
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
    final prefs = await SharedPreferences.getInstance();
    final storedStatuses = prefs.getString('order_statuses') ?? '{}';
    final Map<String, String> oldStatuses = Map<String, String>.from(json.decode(storedStatuses));
    final notifications = prefs.getStringList('notifications') ?? [];
    int unreadCount = prefs.getInt('unread_notifications') ?? 0;

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
    final filters = [
      {'key': 'all', 'label': 'الكل', 'icon': Icons.all_inclusive},
      {'key': 'pending', 'label': 'قيد المعالجة', 'icon': Icons.schedule},
      {'key': 'processing', 'label': 'قيد التنفيذ', 'icon': Icons.autorenew},
      {'key': 'completed', 'label': 'مكتمل', 'icon': Icons.check_circle},
      {'key': 'cancelled', 'label': 'ملغي', 'icon': Icons.cancel},
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
            const Text(
              'لا توجد طلبات حتى الآن',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2543),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ستظهر طلباتك هنا بمجرد إجراء أول عملية شراء',
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
              label: const Text('تحديث'),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text(
          "طلباتي",
          style: TextStyle(fontWeight: FontWeight.w600),
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
                          'لا توجد طلبات لهذا التصنيف',
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
                                    "طلب رقم: #${order.id}",
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
                                'التاريخ',
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
                                'الإجمالي',
                                '${order.total} ر.ق',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('تأكيد الإلغاء'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في إلغاء هذا الطلب؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الإلغاء'),
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
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('تم إلغاء الطلب بنجاح'),
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
          throw Exception('فشل في إلغاء الطلب');
        }
      } catch (e) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('فشل في إلغاء الطلب. يرجى المحاولة مرة أخرى.'),
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
                    "تفاصيل الطلب #${order.id}",
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
                "معلومات الطلب",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              _buildIconInfoRow(
                Icons.calendar_today_outlined,
                "تاريخ الإنشاء",
                order.dateCreated.substring(0, 10),
                primaryColor,
                accentColor,
              ),

              _buildIconInfoRow(
                Icons.attach_money,
                "المقدم",
                "${order.total} ر.ق",
                primaryColor,
                accentColor,
              ),

              _buildIconInfoRow(
                Icons.info_outline,
                "الحالة الحالية",
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
                      "خطة التقسيط",
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
                          "الدفعة الأولى",
                          "${(double.tryParse(plan['downPayment'].toString()) ?? 0).toInt()} ر.ق",
                          primaryColor,
                          accentColor,
                        ),

                        _buildIconInfoRow(
                          Icons.account_balance_wallet,
                          "المبلغ المتبقي",
                          "${(double.tryParse(plan['remainingAmount'].toString()) ?? 0).toInt()} ر.ق",
                          primaryColor,
                          accentColor,
                        ),

                        _buildIconInfoRow(
                          Icons.calendar_view_month,
                          "قيمة القسط الشهري",
                          "${(double.tryParse(plan['monthlyPayment'].toString()) ?? 0).toInt()} ر.ق",
                          primaryColor,
                          accentColor,
                        ),

                        _buildIconInfoRow(
                          Icons.timelapse,
                          "عدد الأشهر",
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
                label: const Text("إغلاق"),
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
                        content: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('سيتم إضافة إعادة الطلب قريباً'),
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
                  label: const Text("إعادة الطلب"),
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