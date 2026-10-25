import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/shelf_model.dart';
import '../../providers/shelf_provider.dart';

class StaffShelvesScreen extends StatefulWidget {
  const StaffShelvesScreen({super.key});

  @override
  State<StaffShelvesScreen> createState() => _StaffShelvesScreenState();
}

class _StaffShelvesScreenState extends State<StaffShelvesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShelfProvider>().fetchShelves();
    });
  }

  void _showAddShelfDialog() {
    final codeController = TextEditingController();
    final locationController =
        TextEditingController(text: 'Tầng 1 - Thư viện chính');
    final capacityController = TextEditingController(text: '20');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_box_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Thêm kệ lưu trữ mới',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Mã kệ (Ví dụ: A1, B1)',
                    hintText: 'Nhập mã kệ...',
                    prefixIcon: Icon(Icons.grid_view_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập mã kệ.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Vị trí kệ',
                    hintText: 'Nhập vị trí đặt kệ...',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập vị trí đặt kệ.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sức chứa tối đa (đơn hàng)',
                    hintText: '20',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    final numVal = int.tryParse(val ?? '');
                    if (numVal == null || numVal <= 0) {
                      return 'Sức chứa tối đa phải lớn hơn 0.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final code = codeController.text.trim().toUpperCase();
              final location = locationController.text.trim();
              final capacity = int.parse(capacityController.text.trim());

              final provider = context.read<ShelfProvider>();
              final result = await provider.createShelf(
                shelfCode: code,
                location: location,
                maxCapacity: capacity,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor:
                        result.success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Tạo kệ'),
          ),
        ],
      ),
    );
  }

  void _showEditShelfDialog(ShelfModel shelf) {
    final codeController = TextEditingController(text: shelf.shelfCode);
    final locationController = TextEditingController(text: shelf.location);
    final capacityController =
        TextEditingController(text: shelf.maxCapacity.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Chỉnh sửa kệ ${shelf.shelfCode}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Mã kệ',
                    prefixIcon: Icon(Icons.grid_view_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập mã kệ.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Vị trí kệ',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập vị trí đặt kệ.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Sức chứa tối đa (đơn hàng)',
                    helperText:
                        'Đang chứa: ${shelf.currentCount} đơn. Không được giảm nhỏ hơn số này.',
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    final numVal = int.tryParse(val ?? '');
                    if (numVal == null || numVal <= 0) {
                      return 'Sức chứa tối đa phải lớn hơn 0.';
                    }
                    if (numVal < shelf.currentCount) {
                      return 'Không thể giảm nhỏ hơn số đơn đang lưu (${shelf.currentCount} đơn).';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final code = codeController.text.trim().toUpperCase();
              final location = locationController.text.trim();
              final capacity = int.parse(capacityController.text.trim());

              final provider = context.read<ShelfProvider>();
              final result = await provider.updateShelf(
                id: shelf.id,
                shelfCode: code,
                location: location,
                maxCapacity: capacity,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor:
                        result.success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteShelf(ShelfModel shelf) {
    if (shelf.currentCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Không thể xóa kệ'),
          content: Text(
            'Kệ ${shelf.shelfCode} hiện đang lưu trữ ${shelf.currentCount} đơn hàng. Bạn cần giao hết các đơn hàng trên kệ này trước khi xóa.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa kệ'),
        content: Text(
          'Bạn có chắc chắn muốn xóa kệ ${shelf.shelfCode} không? Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<ShelfProvider>();
              final result = await provider.deleteShelf(shelf.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor:
                        result.success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa kệ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản Lý Kệ Lưu Trữ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Sơ đồ vị trí & Sức chứa kho in',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => context.read<ShelfProvider>().fetchShelves(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm Kệ'),
        onPressed: _showAddShelfDialog,
      ),
      body: Consumer<ShelfProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.shelves.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.shelves.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.fetchShelves(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchShelves(),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildOverviewCard(provider),
                const SizedBox(height: 16),
                const Text(
                  'Danh Sách Kệ Lưu Trữ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (provider.shelves.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text(
                        'Chưa có kệ lưu trữ nào trong hệ thống.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...provider.shelves.map((shelf) => _buildShelfCard(shelf)),
                const SizedBox(height: 80), // spacing for FAB
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(ShelfProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Tổng quan sức chứa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _buildStatItem(
                'Tổng số kệ',
                provider.totalShelves.toString(),
                Colors.blue.shade700,
                Icons.shelves,
              ),
              _buildStatItem(
                'Còn chỗ',
                provider.availableShelvesCount.toString(),
                Colors.green.shade700,
                Icons.check_circle_outline,
              ),
              _buildStatItem(
                'Đã đầy',
                provider.fullShelvesCount.toString(),
                Colors.red.shade700,
                Icons.do_not_disturb_on_outlined,
              ),
              _buildStatItem(
                'Tổng đơn lưu',
                '${provider.totalStoredOrders}/${provider.totalCapacity}',
                Colors.purple.shade700,
                Icons.inventory_2_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShelfCard(ShelfModel shelf) {
    final isFull = !shelf.isAvailable;
    final progressColor = isFull
        ? Colors.red
        : (shelf.occupancyRatio >= 0.75 ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isFull ? Colors.red.shade200 : Colors.grey.shade200,
          width: isFull ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kệ ${shelf.shelfCode}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFull
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isFull ? 'Đã đầy' : 'Còn chỗ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isFull
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditShelfDialog(shelf);
                    } else if (val == 'delete') {
                      _confirmDeleteShelf(shelf);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Xóa kệ', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.place, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  shelf.location,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đang lưu: ${shelf.currentCount} / ${shelf.maxCapacity} đơn',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Còn trống ${shelf.availableSlots} chỗ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isFull ? Colors.red : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: shelf.occupancyRatio,
                backgroundColor: Colors.grey.shade200,
                color: progressColor,
                minHeight: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
