import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/connection_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';
import '../../widgets/common_widgets.dart';

/// Shows connection history with filter options.
class ConnectionHistoryScreen extends StatefulWidget {
  const ConnectionHistoryScreen({super.key});

  @override
  State<ConnectionHistoryScreen> createState() =>
      _ConnectionHistoryScreenState();
}

class _ConnectionHistoryScreenState extends State<ConnectionHistoryScreen> {
  String _filter = 'all';
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<ConnectionProvider>();
      final result = await provider.getConnectionHistory(
        filter: _filter == 'all' ? null : _filter,
      );
      if (mounted) {
        setState(() {
          _history = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ប្រវត្តិការតភ្ជាប់'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _buildFilterChip('all', 'ទាំងអស់'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('ACCEPTED', 'បានទទួល'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('REVOKED', 'បានដកហូត'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('PENDING', 'រង់ចាំ'),
              ],
            ),
          ),

          // History list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history,
                                size: 48, color: AppColors.neutral300),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'មិនមានប្រវត្តិ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          itemCount: _history.length,
                          itemBuilder: (context, index) {
                            return _buildHistoryItem(
                                context, _history[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label, style: TextStyle(fontSize: 12)),
      onSelected: (_) {
        setState(() => _filter = value);
        _loadHistory();
      },
      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primaryBlue,
    );
  }

  Widget _buildHistoryItem(
      BuildContext context, Map<String, dynamic> item) {
    final status = item['status'] ?? 'PENDING';
    final createdAt = item['createdAt'] != null
        ? DateTime.parse(item['createdAt'])
        : DateTime.now();

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'ACCEPTED':
        statusColor = AppColors.successGreen;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'REVOKED':
        statusColor = AppColors.alertRed;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppColors.warningOrange;
        statusIcon = Icons.pending_outlined;
    }

    final initiator = item['initiator'] ?? {};
    final recipient = item['recipient'] ?? {};
    final initiatorName =
        '${initiator['firstName'] ?? ''} ${initiator['lastName'] ?? ''}'
            .trim();
    final recipientName =
        '${recipient['firstName'] ?? ''} ${recipient['lastName'] ?? ''}'
            .trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    initiatorName.isNotEmpty
                        ? '$initiatorName → $recipientName'
                        : 'Connection',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
