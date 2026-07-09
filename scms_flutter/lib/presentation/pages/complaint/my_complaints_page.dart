import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';


import '../../bloc/complaint/complaint_bloc.dart';
import '../../bloc/complaint/complaint_event.dart';
import '../../bloc/complaint/complaint_state.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/scms_chip.dart';
import '../../widgets/complaint/complaint_card.dart';

class MyComplaintsPage extends StatefulWidget {
  const MyComplaintsPage({super.key});

  @override
  State<MyComplaintsPage> createState() => _MyComplaintsPageState();
}

class _MyComplaintsPageState extends State<MyComplaintsPage> {
  String? _activeFilter;
  final _filters = const ['All', 'PENDING_SR_REVIEW', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'COMPLETED', 'CLOSED'];

  @override
  void initState() {
    super.initState();
    context.read<ComplaintBloc>().add(LoadMyComplaints());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('My Complaints')),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final filter = _filters[i];
                final isSelected = (filter == 'All' && _activeFilter == null) || filter == _activeFilter;
                return ScmsChip(
                  label: filter == 'All' ? 'All' : filter.replaceAll('_', ' '),
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _activeFilter = filter == 'All' ? null : filter);
                    context.read<ComplaintBloc>().add(LoadMyComplaints(statusFilter: _activeFilter));
                  },
                );
              },
            ),
          ),
          // List
          Expanded(
            child: BlocBuilder<ComplaintBloc, ComplaintState>(
              builder: (context, state) {
                if (state is ComplaintLoading) return const Center(child: CircularProgressIndicator());
                if (state is ComplaintError) return ScmsErrorWidget(message: state.message, onRetry: () => context.read<ComplaintBloc>().add(RefreshComplaints()));
                if (state is MyComplaintsLoaded && state.complaints.isEmpty) {
                  return const EmptyStateWidget(title: 'No complaints found', icon: Icons.search_off_rounded);
                }
                if (state is MyComplaintsLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async => context.read<ComplaintBloc>().add(RefreshComplaints()),
                    child: ListView.builder(
                      itemCount: state.complaints.length,
                      itemBuilder: (_, i) => ComplaintCard(
                        complaint: state.complaints[i],
                        onTap: () => context.push('/complaint/${state.complaints[i].id}'),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
