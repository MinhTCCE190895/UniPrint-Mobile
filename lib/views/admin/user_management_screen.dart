import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_management_provider.dart';

/// Task 5: Màn hình quản lý người dùng dành cho Quản trị viên (Admin):
/// - Xem danh sách người dùng với tìm kiếm, lọc vai trò và trạng thái
/// - Phân quyền vai trò (Role: Sinh viên, Nhân viên, Quản trị viên)
/// - Khóa / Mở khóa tài khoản (IsActive)
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRoleDialog(UserModel user) {
    int selectedRole = user.role;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<UserManagementProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.security, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Phân quyền: ${user.fullName}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email: ${user.email}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chọn vai trò mới trong hệ thống:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildRoleOption(
                title: 'Sinh viên (Student)',
                subtitle: 'Tải tài liệu, tạo đơn in, xem tiến trình',
                roleValue: 1,
                selectedRole: selectedRole,
                onTap: () => setDialogState(() => selectedRole = 1),
              ),
              _buildRoleOption(
                title: 'Nhân viên (Staff)',
                subtitle: 'Xem hàng đợi in, in ấn, xếp kệ, quét QR',
                roleValue: 2,
                selectedRole: selectedRole,
                onTap: () => setDialogState(() => selectedRole = 2),
              ),
              _buildRoleOption(
                title: 'Quản trị viên (Admin)',
                subtitle: 'Toàn quyền quản lý người dùng, bảng giá',
                roleValue: 3,
                selectedRole: selectedRole,
                onTap: () => setDialogState(() => selectedRole = 3),
              ),
            ],
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                if (selectedRole == user.role) return;

                final success = await provider.updateUserRole(user.id, selectedRole);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (provider.successMessage ?? 'Cập nhật vai trò thành công!')
                          : (provider.errorMessage ?? 'Không thể cập nhật vai trò.'),
                    ),
                    backgroundColor: success ? AppColors.statusCompleted : AppColors.statusCancelled,
                  ),
                );
              },
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required String title,
    required String subtitle,
    required int roleValue,
    required int selectedRole,
    required VoidCallback onTap,
  }) {
    final isSelected = roleValue == selectedRole;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isSelected ? AppColors.primary : AppColors.textLight,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  void _showStatusDialog(UserModel user) {
    final willLock = user.isActive;
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<UserManagementProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              willLock ? Icons.lock_outline : Icons.lock_open_outlined,
              color: willLock ? AppColors.statusCancelled : AppColors.statusCompleted,
            ),
            const SizedBox(width: 8),
            Text(
              willLock ? 'Khóa tài khoản?' : 'Mở khóa tài khoản?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          willLock
              ? 'Bạn có chắc muốn KHÓA tài khoản của "${user.fullName}" (${user.email})? Người dùng này sẽ không thể đăng nhập.'
              : 'Bạn có chắc muốn MỞ KHÓA tài khoản của "${user.fullName}" (${user.email})? Người dùng sẽ được phép đăng nhập lại bình thường.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: willLock ? AppColors.statusCancelled : AppColors.statusCompleted,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.toggleUserStatus(user.id, isActive: !willLock);

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? (provider.successMessage ?? 'Cập nhật trạng thái thành công!')
                        : (provider.errorMessage ?? 'Không thể cập nhật trạng thái.'),
                  ),
                  backgroundColor: success ? AppColors.statusCompleted : AppColors.statusCancelled,
                ),
              );
            },
            child: Text(willLock ? 'Khóa tài khoản' : 'Mở khóa'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(int role) {
    switch (role) {
      case 3:
        return AppColors.statusCancelled; // Admin: Red
      case 2:
        return AppColors.statusPending; // Staff: Amber
      default:
        return AppColors.primary; // Student: Navy
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    final provider = context.watch<UserManagementProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quản Lý Người Dùng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Tổng số: ${provider.totalCount} tài khoản',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => provider.loadUsers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Thống kê nhanh
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Sinh viên', provider.studentCount, AppColors.primary),
                _buildStatItem('Nhân viên', provider.staffCount, AppColors.statusPending),
                _buildStatItem('Admin', provider.adminCount, AppColors.statusCancelled),
                _buildStatItem('Đã khóa', provider.lockedCount, AppColors.textSecondary),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Tìm kiếm
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo họ tên, email hoặc SĐT...',
                hintStyle: const TextStyle(fontSize: 14, color: AppColors.textLight),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          provider.setSearchTerm('');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (term) => provider.setSearchTerm(term),
              onChanged: (term) {
                if (term.isEmpty) {
                  provider.setSearchTerm('');
                }
              },
            ),
          ),

          // Bộ lọc Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Vai trò: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      _buildFilterChip(
                        label: 'Tất cả',
                        isSelected: provider.selectedRole == null,
                        onSelected: () => provider.setRoleFilter(null),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Sinh viên',
                        isSelected: provider.selectedRole == 1,
                        onSelected: () => provider.setRoleFilter(1),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Nhân viên',
                        isSelected: provider.selectedRole == 2,
                        onSelected: () => provider.setRoleFilter(2),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Admin',
                        isSelected: provider.selectedRole == 3,
                        onSelected: () => provider.setRoleFilter(3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Status filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Trạng thái: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                      _buildFilterChip(
                        label: 'Tất cả',
                        isSelected: provider.selectedStatus == null,
                        onSelected: () => provider.setStatusFilter(null),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Hoạt động',
                        isSelected: provider.selectedStatus == true,
                        onSelected: () => provider.setStatusFilter(true),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Đã khóa',
                        isSelected: provider.selectedStatus == false,
                        onSelected: () => provider.setStatusFilter(false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Danh sách người dùng
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColors.statusCancelled),
                              const SizedBox(height: 12),
                              Text(provider.errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => provider.loadUsers(),
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : provider.users.isEmpty
                        ? const Center(
                            child: Text(
                              'Không tìm thấy người dùng nào phù hợp.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => provider.loadUsers(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: provider.users.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final user = provider.users[index];
                                final isSelf = user.id == currentUserId;
                                return _buildUserCard(user, isSelf);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildUserCard(UserModel user, bool isSelf) {
    final roleColor = _getRoleColor(user.role);

    return Card(
      elevation: 1,
      color: user.isActive ? Colors.white : const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelf ? AppColors.primary : AppColors.border, width: isSelf ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: roleColor,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                // Thông tin chính
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: user.isActive ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Bạn',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                        Text(
                          'SĐT: ${user.phoneNumber}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Tags: Role & Status
            Row(
              children: [
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    user.roleName,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: roleColor),
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (user.isActive ? AppColors.statusCompleted : AppColors.statusCancelled).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (user.isActive ? AppColors.statusCompleted : AppColors.statusCancelled).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user.isActive ? Icons.check_circle : Icons.lock,
                        size: 13,
                        color: user.isActive ? AppColors.statusCompleted : AppColors.statusCancelled,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.isActive ? 'Hoạt động' : 'Đã khóa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: user.isActive ? AppColors.statusCompleted : AppColors.statusCancelled,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (user.createdAt != null)
                  Text(
                    _dateFormat.format(user.createdAt!.toLocal()),
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isSelf)
                  const Text(
                    'Không thể tự đổi quyền / khóa',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textLight),
                  )
                else ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.manage_accounts, size: 16),
                    label: const Text('Phân quyền', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showRoleDialog(user),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: user.isActive ? AppColors.statusCancelled : AppColors.statusCompleted,
                      side: BorderSide(color: user.isActive ? AppColors.statusCancelled : AppColors.statusCompleted),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(user.isActive ? Icons.lock_outline : Icons.lock_open, size: 16),
                    label: Text(user.isActive ? 'Khóa' : 'Mở khóa', style: const TextStyle(fontSize: 12)),
                    onPressed: () => _showStatusDialog(user),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
