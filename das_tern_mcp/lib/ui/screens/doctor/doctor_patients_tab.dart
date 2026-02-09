import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/connection_provider.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_spacing.dart';

/// Doctor patients tab – list of connected patients.
class DoctorPatientsTab extends StatefulWidget {
  const DoctorPatientsTab({super.key});

  @override
  State<DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends State<DoctorPatientsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionProvider>().fetchConnections(status: 'ACCEPTED');
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConnectionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchConnections(status: 'ACCEPTED'),
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.acceptedConnections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: AppColors.neutral300),
                        const SizedBox(height: AppSpacing.md),
                        Text('No patients yet',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Connected patients will appear here.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: provider.acceptedConnections.length,
                    itemBuilder: (context, index) {
                      final conn = provider.acceptedConnections[index];
                      final patient = conn.patient;
                      final name = patient != null
                          ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'
                          : 'Patient';
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primaryBlue.withValues(alpha: 0.1),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text(patient?['phoneNumber'] ?? ''),
                          trailing:
                              const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: Navigate to patient detail
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
