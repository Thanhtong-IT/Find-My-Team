import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../bloc/community_bloc.dart';
import '../bloc/community_event.dart';
import '../bloc/community_state.dart';
import 'create_community_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CommunityBloc()..add(const CommunityLoadRequested()),
      child: const _CommunityScreenBody(),
    );
  }
}

class _CommunityScreenBody extends StatelessWidget {
  const _CommunityScreenBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cộng đồng', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCommunityScreen())),
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: BlocBuilder<CommunityBloc, CommunityState>(
        builder: (context, state) {
          if (state.status == CommunityStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == CommunityStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 56, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(state.errorMessage ?? 'Không thể tải danh sách cộng đồng'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => context.read<CommunityBloc>().add(const CommunityLoadRequested()), child: const Text('Thử lại')),
                ],
              ),
            );
          }
          final communities = state.communities;
          if (communities.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_rounded, size: 64, color: AppColors.textLight),
                  SizedBox(height: 12),
                  Text('Chưa có cộng đồng nào', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(community.name.isNotEmpty ? community.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(community.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${community.description}\nThành viên: ${community.memberCount}'),
                  isThreeLine: true,
                  trailing: FilledButton(
                    onPressed: () {
                      context.read<CommunityBloc>().add(CommunityJoinRequested(community.id));
                    },
                    child: const Text('Tham gia'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
