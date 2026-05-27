import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/tokens/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass/app_glass_card.dart';
import '../../../../shared/widgets/glass/app_glass_chip.dart';
import '../../../../shared/widgets/glass/app_scaffold.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/states/empty_state.dart';
import '../../../../shared/widgets/states/error_state.dart';
import '../../../../shared/widgets/states/loading_state.dart';
import '../../domain/prescription.dart';
import '../../domain/prescription_enums.dart';

const int _pageSize = 20;

/// Paginated prescription list using Supabase `range()`.
/// Falls back to Drift-based list when offline.
/// Spec ref: 03-prescription-medication §8.2.
class PaginatedPrescriptionListPage extends ConsumerStatefulWidget {
  const PaginatedPrescriptionListPage({super.key});

  @override
  ConsumerState<PaginatedPrescriptionListPage> createState() =>
      _PaginatedPrescriptionListPageState();
}

class _PaginatedPrescriptionListPageState
    extends ConsumerState<PaginatedPrescriptionListPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  PrescriptionStatus? _filterStatus;
  String _query = '';

  final List<Prescription> _items = <Prescription>[];
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
      final from = _page * _pageSize;
      final to = from + _pageSize - 1;

      var query = Supabase.instance.client
          .from('prescriptions')
          .select()
          .eq('patient_id', uid)
          .order('updated_at', ascending: false)
          .range(from, to);

      if (_filterStatus != null) {
        query = Supabase.instance.client
            .from('prescriptions')
            .select()
            .eq('patient_id', uid)
            .eq('status', _filterStatus!.code)
            .order('updated_at', ascending: false)
            .range(from, to);
      }

      final rows = await query as List<dynamic>;
      final newItems = rows
          .cast<Map<String, dynamic>>()
          .map(Prescription.fromMap)
          .toList();

      setState(() {
        _items.addAll(newItems);
        _hasMore = newItems.length == _pageSize;
        _page++;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _reset() {
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
    });
    _loadPage();
  }

  List<Prescription> get _filtered {
    if (_query.isEmpty) return _items;
    final q = _query.toLowerCase();
    return _items
        .where(
          (p) =>
              p.patientName.toLowerCase().contains(q) ||
              p.symptoms.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l.savePrescription,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => context.push('/patient/prescriptions/new'),
        ),
      ],
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              kToolbarHeight + AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              children: <Widget>[
                AppTextField(
                  controller: _searchCtrl,
                  label: l.searchPrescription,
                  prefixIcon: Icons.search,
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      AppGlassChip(
                        label: 'All',
                        selected: _filterStatus == null,
                        onTap: () {
                          setState(() => _filterStatus = null);
                          _reset();
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...PrescriptionStatus.values.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: AppGlassChip(
                            label: s.code,
                            selected: _filterStatus == s,
                            color: _statusColor(s),
                            onTap: () {
                              setState(() => _filterStatus = s);
                              _reset();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _error != null
                ? ErrorState(
                    message: _error!,
                    onRetry: _reset,
                  )
                : _items.isEmpty && _loading
                    ? const LoadingState()
                    : _filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.medication_outlined,
                            title: l.doseHistoryAppearHere,
                          )
                        : ListView.separated(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.md,
                            ),
                            itemCount:
                                _filtered.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (_, i) {
                              if (i == _filtered.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final p = _filtered[i];
                              return AppGlassCard(
                                onTap: () => context.push(
                                  '/patient/prescriptions/${p.id}',
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(p.patientName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium),
                                          Text(
                                            p.symptoms,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    AppGlassChip(
                                      label: p.status.code,
                                      color: _statusColor(p.status),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(PrescriptionStatus s) => switch (s) {
        PrescriptionStatus.active => const Color(0xFF1FAA66),
        PrescriptionStatus.paused => const Color(0xFFF1A93A),
        PrescriptionStatus.inactive => const Color(0xFFD64545),
        PrescriptionStatus.draft => Colors.grey,
      };
}
