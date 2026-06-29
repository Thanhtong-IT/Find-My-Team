import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/constants.dart';
import '../../../core/events/event_bus.dart';
import '../../../core/websocket/websocket_client.dart';
import '../../community/screens/community_chat_screen.dart';
import '../../community/screens/create_community_screen.dart';
import '../../community/data/community_repository.dart';
import '../../community/models/community_model.dart';
import '../../community/models/chat_message.dart';
import '../../notification/screens/notification_screen.dart';
import '../bloc/team_bloc.dart';
import '../bloc/team_event.dart';
import '../bloc/team_state.dart';
import '../models/team_model.dart';
import '../services/team_chat_api_service.dart';
import '../../profile/models/game_model.dart';
import '../../profile/services/user_api_service.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../profile/bloc/profile_event.dart';
import '../../profile/screens/user_profile_screen.dart';
import 'invite_member_screen.dart';
import '../../../core/di/injection.dart';
import '../../../core/voice/voice_chat_service.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  int _selectedTabIndex = 1;
  StreamSubscription? _navigateSub;
  StreamSubscription? _wsSubscription;
  List<CommunityModel> _communities = [];
  bool _isChatOpen = false;
  bool _hasUnreadMessage = false;
  String? _currentTeamId;

  @override
  void initState() {
    super.initState();
    context.read<TeamBloc>().add(const TeamLoadRequested());
    _loadCommunities();
    _navigateSub = AppEventBus.instance.navigateToTabStream.listen((tabIndex) {
      if (mounted) {
        setState(() => _selectedTabIndex = tabIndex);
      }
    });
    _setupGlobalWebSocketListener();
  }

  void _setupGlobalWebSocketListener() {
    _wsSubscription = WebSocketClient.instance.eventStream.listen((event) {
      if (event.type == WsEventType.teamMessageCreated) {
        if (!_isChatOpen) {
          final senderId = event.data['senderId']?.toString();
          final myUserId = context.read<ProfileBloc>().state.profile?.id ?? '';
          if (senderId != myUserId) {
            setState(() => _hasUnreadMessage = true);
          }
        }
      }
    });
  }

  Future<void> _loadCommunities() async {
    try {
      final communities = await CommunityRepository().getCommunities();
      if (mounted) {
        setState(() {
          _communities = communities;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _communities = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _navigateSub?.cancel();
    _wsSubscription?.cancel();
    getIt<VoiceChatService>().leaveVoiceRoom();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFullScreenChat(TeamModel team, String currentUserId, String currentUserName) {
    setState(() {
      _isChatOpen = true;
      _hasUnreadMessage = false;
    });
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _TeamChatFullScreen(
            team: team,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
            onClose: () {
              if (mounted) setState(() => _isChatOpen = false);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;

    return BlocConsumer<TeamBloc, TeamState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          _showSnackBar(state.errorMessage!, isError: true);
        }
        if (state.successMessage != null) {
          _showSnackBar(state.successMessage!);
        }

        // Sync voice room membership and mute state
        final currentTeam = state.currentTeam;
        final myUserId = context.read<ProfileBloc>().state.profile?.id ?? '';
        final voiceService = getIt<VoiceChatService>();

        if (currentTeam != null && myUserId.isNotEmpty) {
          if (!voiceService.isInCall) {
            voiceService.joinVoiceRoom(currentTeam.id, myUserId).then((success) {
              if (success) {
                final myMember = currentTeam.members.firstWhere(
                  (m) => m.userId == myUserId,
                  orElse: () => TeamMemberModel(id: '', userId: myUserId, displayName: ''),
                );
                voiceService.toggleMute(!myMember.isMicEnabled);
              }
            });
          } else {
            final myMember = currentTeam.members.firstWhere(
              (m) => m.userId == myUserId,
              orElse: () => TeamMemberModel(id: '', userId: myUserId, displayName: ''),
            );
            voiceService.toggleMute(!myMember.isMicEnabled);
          }
        } else if (currentTeam == null && voiceService.isInCall) {
          voiceService.leaveVoiceRoom();
        }
      },
      builder: (context, state) {
        final hasTeam = state.currentTeam != null;
        final myUserId = context.read<ProfileBloc>().state.profile?.id ?? '';
        final myUserName = context.read<ProfileBloc>().state.profile?.displayName ?? '';
        final isLeader = state.currentTeam?.ownerId == myUserId;

        // Cập nhật team ID hiện tại
        if (hasTeam) _currentTeamId = state.currentTeam!.id;

        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            surfaceTintColor: AppColors.white,
            automaticallyImplyLeading: false,
            titleSpacing: 20,
            title: const Text(
              'Nhóm',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            actions: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!_isChatOpen && hasTeam) {
                        _showFullScreenChat(state.currentTeam!, myUserId, myUserName);
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isChatOpen ? AppColors.primary : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: _isChatOpen ? AppColors.white : AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  if (_hasUnreadMessage)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.person, color: AppColors.white, size: 20),
              ),
              const SizedBox(width: 20),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _TeamTopTabs(
                      selectedIndex: _selectedTabIndex,
                      isSmallScreen: isSmallScreen,
                      onTabSelected: (index) {
                        setState(() => _selectedTabIndex = index);
                        if (index == 0 && hasTeam) {
                          context.read<TeamBloc>().add(const TeamJoinRequestsLoadRequested());
                        }
                      },
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          context.read<TeamBloc>().add(const TeamLoadRequested());
                          await Future.delayed(const Duration(milliseconds: 500));
                        },
                        color: AppColors.primary,
                        child: state.status == TeamStatus.loading
                            ? const Center(child: CircularProgressIndicator())
                            : IndexedStack(
                                index: _selectedTabIndex,
                                children: [
                                  _RequestTab(
                                    requests: state.joinRequests,
                                    hasTeam: hasTeam,
                                    isSmallScreen: isSmallScreen,
                                    onRefresh: () {
                                      context.read<TeamBloc>().add(const TeamJoinRequestsLoadRequested());
                                    },
                                    onAccept: (reqId) {
                                      context.read<TeamBloc>().add(JoinRequestAccepted(reqId));
                                    },
                                    onReject: (reqId) {
                                      context.read<TeamBloc>().add(JoinRequestRejected(reqId));
                                    },
                                    onViewProfile: (userId) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UserProfileScreen(userId: userId),
                                        ),
                                      );
                                    },
                                  ),
                                  _TeamTab(
                                    hasTeam: hasTeam,
                                    team: state.currentTeam,
                                    myUserId: myUserId,
                                    myUserName: myUserName,
                                    isSmallScreen: isSmallScreen,
                                    onCreateTeam: (name, gameId, size, requiredRank, description) {
                                      context.read<TeamBloc>().add(TeamCreateRequested(
                                            name: name,
                                            gameId: gameId,
                                            maxMembers: size,
                                            requiredRank: requiredRank,
                                            description: description,
                                          ));
                                    },
                                    onDisbandTeam: () {
                                      context.read<TeamBloc>().add(const TeamDisbandRequested());
                                    },
                                    onLeaveTeam: () {
                                      context.read<TeamBloc>().add(const TeamLeaveRequested());
                                    },
                                    onReadyToggled: (ready) {
                                      context.read<TeamBloc>().add(TeamReadyToggled(ready));
                                    },
                                    onMicToggled: () {
                                      final member = state.currentTeam!.members.firstWhere(
                                        (m) => m.userId == myUserId,
                                        orElse: () => TeamMemberModel(id: '', userId: myUserId, displayName: ''),
                                      );
                                      context.read<TeamBloc>().add(TeamMicToggled(
                                        userId: myUserId,
                                        isMicEnabled: !member.isMicEnabled,
                                      ));
                                    },
                                    onViewProfile: (userId) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => UserProfileScreen(userId: userId),
                                        ),
                                      );
                                    },
                                    onKickMember: (memberId) {
                                      context.read<TeamBloc>().add(TeamMemberKickRequested(memberId));
                                    },
                                  ),
                                  _CommunityTab(communities: _communities, isSmallScreen: isSmallScreen),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          floatingActionButton: _buildFab(hasTeam, isLeader, state.currentTeam, _isChatOpen),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget? _buildFab(bool hasTeam, bool isLeader, TeamModel? currentTeam, bool showChatPanel) {
    if (showChatPanel) return null;
    if (_selectedTabIndex == 0) return null;
    if (_selectedTabIndex == 1 && !hasTeam) return null;
    if (_selectedTabIndex == 1 && hasTeam) {
      // Chỉ cho phép mời người chơi nếu mình là leader
      if (!isLeader) return null;
      return FloatingActionButton.extended(
        heroTag: 'team_invite_member_fab',
        onPressed: () => _navigateToInviteMember(currentTeam!),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Mời người', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    if (_selectedTabIndex == 2) {
      return FloatingActionButton.extended(
        heroTag: 'team_create_community_fab',
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
          );
          // Reload profile when returning from create community
          if (result == true && mounted) {
            context.read<ProfileBloc>().add(const ProfileLoadRequested());
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Tạo cộng đồng', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return null;
  }

  void _navigateToInviteMember(TeamModel team) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InviteMemberScreen(team: team)),
    );
  }
}

class _TeamTopTabs extends StatelessWidget {
  final int selectedIndex;
  final bool isSmallScreen;
  final ValueChanged<int> onTabSelected;

  const _TeamTopTabs({required this.selectedIndex, required this.isSmallScreen, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Yêu cầu', 'Nhóm', 'Cộng đồng'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: index < tabs.length - 1 ? 8 : 0),
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RequestTab extends StatelessWidget {
  final List<JoinRequestModel> requests;
  final bool hasTeam;
  final bool isSmallScreen;
  final VoidCallback onRefresh;
  final void Function(String) onAccept;
  final void Function(String) onReject;
  final void Function(String userId) onViewProfile;

  const _RequestTab({
    required this.requests,
    required this.hasTeam,
    required this.isSmallScreen,
    required this.onRefresh,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasTeam) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: RefreshIndicator(
          onRefresh: () async => onRefresh(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.inbox_rounded, size: isSmallScreen ? 60 : 72, color: AppColors.textLight),
                const SizedBox(height: 16),
                Text('Bạn chưa có nhóm', style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('Hãy tạo nhóm trước để nhận yêu cầu tham gia.', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Yêu cầu tham gia (${requests.length})', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            if (requests.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: isSmallScreen ? 48 : 56, color: AppColors.success),
                    const SizedBox(height: 12),
                    Text('Không có yêu cầu nào', style: TextStyle(fontSize: isSmallScreen ? 14 : 15, color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              ...requests.map((request) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _JoinRequestCard(
                      request: request,
                      isSmallScreen: isSmallScreen,
                      onAccept: () => onAccept(request.id),
                      onReject: () => onReject(request.id),
                      onViewProfile: () => onViewProfile(request.userId),
                    ),
                  )),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  final JoinRequestModel request;
  final bool isSmallScreen;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewProfile;

  const _JoinRequestCard({
    required this.request,
    required this.isSmallScreen,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onViewProfile,
            child: CircleAvatar(
              radius: isSmallScreen ? 22 : 26,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: request.userAvatarUrl != null ? NetworkImage(request.userAvatarUrl!) : null,
              child: request.userAvatarUrl == null
                  ? Icon(Icons.person, color: AppColors.primary, size: isSmallScreen ? 22 : 26)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onViewProfile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.userDisplayName, style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  if (request.message != null && request.message!.isNotEmpty)
                    Text(
                      'Lời nhắn: "${request.message}"',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    )
                  else
                    Text(
                      'Không có lời nhắn',
                      style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: AppColors.textLight),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              SizedBox(
                width: isSmallScreen ? 80 : 90,
                height: isSmallScreen ? 32 : 36,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: AppColors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero),
                  child: Text('Chấp nhận', style: TextStyle(fontSize: isSmallScreen ? 10 : 11, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: isSmallScreen ? 80 : 90,
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: index < tabs.length - 1 ? 8 : 0),
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RequestTab extends StatelessWidget {
  final List<JoinRequestModel> requests;
  final bool hasTeam;
  final bool isSmallScreen;
  final VoidCallback onRefresh;
  final void Function(String) onAccept;
  final void Function(String) onReject;
  final void Function(String userId) onViewProfile;

  const _RequestTab({
    required this.requests,
    required this.hasTeam,
    required this.isSmallScreen,
    required this.onRefresh,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasTeam) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: RefreshIndicator(
          onRefresh: () async => onRefresh(),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.inbox_rounded, size: isSmallScreen ? 60 : 72, color: AppColors.textLight),
                const SizedBox(height: 16),
                Text('Bạn chưa có nhóm', style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('Hãy tạo nhóm trước để nhận yêu cầu tham gia.', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Yêu cầu tham gia (${requests.length})', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            if (requests.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: isSmallScreen ? 48 : 56, color: AppColors.success),
                    const SizedBox(height: 12),
                    Text('Không có yêu cầu nào', style: TextStyle(fontSize: isSmallScreen ? 14 : 15, color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              ...requests.map((request) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _JoinRequestCard(
                      request: request,
                      isSmallScreen: isSmallScreen,
                      onAccept: () => onAccept(request.id),
                      onReject: () => onReject(request.id),
                      onViewProfile: () => onViewProfile(request.userId),
                    ),
                  )),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  final JoinRequestModel request;
  final bool isSmallScreen;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onViewProfile;

  const _JoinRequestCard({
    required this.request,
    required this.isSmallScreen,
    required this.onAccept,
    required this.onReject,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onViewProfile,
            child: CircleAvatar(
              radius: isSmallScreen ? 22 : 26,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: request.userAvatarUrl != null ? NetworkImage(request.userAvatarUrl!) : null,
              child: request.userAvatarUrl == null
                  ? Icon(Icons.person, color: AppColors.primary, size: isSmallScreen ? 22 : 26)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onViewProfile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.userDisplayName, style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  if (request.message != null && request.message!.isNotEmpty)
                    Text(
                      'Lời nhắn: "${request.message}"',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    )
                  else
                    Text(
                      'Không có lời nhắn',
                      style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: AppColors.textLight),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              SizedBox(
                width: isSmallScreen ? 80 : 90,
                height: isSmallScreen ? 32 : 36,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: AppColors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero),
                  child: Text('Chấp nhận', style: TextStyle(fontSize: isSmallScreen ? 10 : 11, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: isSmallScreen ? 80 : 90,
                height: isSmallScreen ? 32 : 36,
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: EdgeInsets.zero),
                  child: Text('Từ chối', style: TextStyle(fontSize: isSmallScreen ? 10 : 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamTab extends StatelessWidget {
  final bool hasTeam;
  final TeamModel? team;
  final String myUserId;
  final String myUserName;
  final bool isSmallScreen;
  final void Function(String name, String gameId, int size, String requiredRank, String description) onCreateTeam;
  final VoidCallback onDisbandTeam;
  final VoidCallback onLeaveTeam;
  final void Function(bool) onReadyToggled;
  final VoidCallback onMicToggled;
  final void Function(String userId) onViewProfile;
  final void Function(String memberId) onKickMember;

  const _TeamTab({
    required this.hasTeam,
    this.team,
    required this.myUserId,
    required this.myUserName,
    required this.isSmallScreen,
    required this.onCreateTeam,
    required this.onDisbandTeam,
    required this.onLeaveTeam,
    required this.onReadyToggled,
    required this.onMicToggled,
    required this.onViewProfile,
    required this.onKickMember,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasTeam || team == null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _CreateTeamForm(isSmallScreen: isSmallScreen, onSubmit: onCreateTeam),
      );
    }

    final currentTeam = team!;
    final members = currentTeam.members;
    final teamSize = currentTeam.maxMembers;
    final emptySlots = teamSize - members.length;
    final isLeader = currentTeam.ownerId == myUserId;

    final myMember = members.firstWhere(
      (m) => m.userId == myUserId,
      orElse: () => TeamMemberModel(id: '', userId: myUserId, displayName: ''),
    );
    final isMyReady = myMember.isReady;
    final isMyMicEnabled = myMember.isMicEnabled;

    return StreamBuilder<Set<String>>(
      stream: getIt<VoiceChatService>().activeSpeakersStream,
      initialData: const {},
      builder: (context, activeSpeakersSnapshot) {
        final activeSpeakers = activeSpeakersSnapshot.data ?? const {};

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _WaitingRoomHeader(
                members: members,
                teamSize: teamSize,
                createdGame: currentTeam.gameName,
                createdRank: currentTeam.requiredRank,
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(height: 16),
              Text('Danh sách thành viên', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ...members.map((member) {
                final isActiveSpeaker = member.userId == myUserId
                    ? (getIt<VoiceChatService>().isInCall && member.isMicEnabled)
                    : (activeSpeakers.contains(member.userId) && member.isMicEnabled);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MemberRow(
                    member: member,
                    isLeader: member.isLeader || member.userId == currentTeam.ownerId,
                    isSmallScreen: isSmallScreen,
                    myUserId: myUserId,
                    myUserName: myUserName,
                    isTeamLeader: isLeader,
                    onTap: () => onViewProfile(member.userId),
                    onKick: member.userId != myUserId ? () => onKickMember(member.userId) : null,
                    isActiveSpeaker: isActiveSpeaker,
                  ),
                );
              }),
              ...List.generate(emptySlots, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _EmptySlotRow(isSmallScreen: isSmallScreen),
                  )),
              const SizedBox(height: 20),
              if (!isLeader) ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: isSmallScreen ? 44 : 48,
                        child: ElevatedButton(
                          onPressed: () => onReadyToggled(!isMyReady),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isMyReady ? AppColors.success : AppColors.primary.withValues(alpha: 0.8),
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isMyReady ? Icons.check_rounded : Icons.radio_button_unchecked_rounded, size: 18),
                              const SizedBox(width: 6),
                              Text(isMyReady ? 'Đã sẵn sàng (Click để hủy)' : 'Sẵn sàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 13 : 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: isSmallScreen ? 44 : 48,
                child: ElevatedButton.icon(
                  onPressed: onMicToggled,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMyMicEnabled ? AppColors.success : AppColors.textSecondary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(isMyMicEnabled ? Icons.mic_rounded : Icons.mic_off_rounded, size: 18),
                  label: Text(
                    isMyMicEnabled ? 'Mic đang bật (Nhấn để tắt)' : 'Mic đang tắt (Nhấn để bật)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 12 : 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (!isLeader)
                    Expanded(
                      child: SizedBox(
                        height: isSmallScreen ? 40 : 44,
                        child: OutlinedButton(
                          onPressed: onLeaveTeam,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.divider),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Rời nhóm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 12 : 13)),
                        ),
                      ),
                    ),
                  if (isLeader)
                    Expanded(
                      child: SizedBox(
                        height: isSmallScreen ? 40 : 44,
                        child: OutlinedButton(
                          onPressed: onDisbandTeam,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Giải tán nhóm', style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 12 : 13)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }
}



class _WaitingRoomHeader extends StatelessWidget {
  final List<TeamMemberModel> members;
  final int teamSize;
  final String? createdGame;
  final String? createdRank;
  final bool isSmallScreen;

  const _WaitingRoomHeader({required this.members, required this.teamSize, this.createdGame, this.createdRank, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 48 : 56,
                height: isSmallScreen ? 48 : 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.groups_rounded, color: AppColors.primary, size: isSmallScreen ? 26 : 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phòng chờ nhóm', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('${createdGame ?? "Chưa chọn game"} \u2022 Yêu cầu: ${createdRank ?? "Không yêu cầu"}', style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 12, vertical: isSmallScreen ? 5 : 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_alt_1_rounded, size: isSmallScreen ? 14 : 16, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'ĐANG TUYỂN (${members.length}/$teamSize)',
                      style: TextStyle(fontSize: isSmallScreen ? 10 : 11, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _StatItem(label: 'Tổng thành viên', value: '${members.length}/$teamSize', icon: Icons.people_rounded, isSmallScreen: isSmallScreen),
                const SizedBox(width: 16),
                _StatItem(label: 'Slot trống', value: '${teamSize - members.length}', icon: Icons.add_circle_outline, isSmallScreen: isSmallScreen),
                const SizedBox(width: 16),
                _StatItem(label: 'Sẵn sàng', value: '${members.where((m) => m.isReady).length}', icon: Icons.check_circle_outline, isSmallScreen: isSmallScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isSmallScreen;

  const _StatItem({required this.label, required this.value, required this.icon, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: isSmallScreen ? 18 : 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(label, style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final TeamMemberModel member;
  final bool isLeader;
  final bool isSmallScreen;
  final String myUserId;
  final String myUserName;
  final bool isTeamLeader;

  final VoidCallback onTap;
  final VoidCallback? onKick;
  final bool isActiveSpeaker;

  const _MemberRow({
    required this.member,
    required this.isLeader,
    required this.isSmallScreen,
    required this.myUserId,
    required this.myUserName,
    required this.isTeamLeader,
    required this.onTap,
    this.onKick,
    required this.isActiveSpeaker,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = isSmallScreen ? 40.0 : 46.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 14 : 16, vertical: isSmallScreen ? 12 : 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActiveSpeaker ? AppColors.success : AppColors.divider,
            width: isActiveSpeaker ? 2.0 : 1.0,
          ),
          boxShadow: isActiveSpeaker
              ? [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActiveSpeaker ? AppColors.success : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                    child: member.avatarUrl == null
                        ? Icon(Icons.person, color: AppColors.primary, size: avatarSize / 2)
                        : null,
                  ),
                ),
                if (member.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: isSmallScreen ? 12 : 14,
                      height: isSmallScreen ? 12 : 14,
                      decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 2)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.displayName == 'Unknown' && member.userId == myUserId && myUserName.isNotEmpty
                            ? myUserName
                            : member.displayName,
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      if (isLeader) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, size: isSmallScreen ? 10 : 12, color: AppColors.primary),
                              const SizedBox(width: 2),
                              Text('Chủ nhóm', style: TextStyle(fontSize: isSmallScreen ? 9 : 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.isReady ? "Đã sẵn sàng" : "Chưa sẵn sàng",
                    style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: member.isReady ? AppColors.success : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        isActiveSpeaker
                            ? Icons.volume_up_rounded
                            : (member.isMicEnabled ? Icons.mic_rounded : Icons.mic_off_rounded),
                        size: isSmallScreen ? 12 : 14,
                        color: member.isMicEnabled ? AppColors.success : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActiveSpeaker
                            ? 'Đang nói...'
                            : (member.isMicEnabled ? 'Mic đang bật' : 'Mic đang tắt'),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 11,
                          color: member.isMicEnabled ? AppColors.success : AppColors.textSecondary,
          ],
        ),
      ),
    );
  }
}

class _EmptySlotRow extends StatelessWidget {
  final bool isSmallScreen;
  const _EmptySlotRow({required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 14 : 16, vertical: isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 40 : 46,
            height: isSmallScreen ? 40 : 46,
            decoration: BoxDecoration(
              color: AppColors.divider,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
            ),
            child: Icon(Icons.add, color: AppColors.textLight, size: isSmallScreen ? 20 : 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Đang tìm người chơi...',
              style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textLight, fontStyle: FontStyle.italic),
            ),
          ),
          Icon(Icons.hourglass_empty_rounded, color: AppColors.textLight, size: isSmallScreen ? 18 : 20),
        ],
      ),
    );
  }
}

class _CreateTeamForm extends StatefulWidget {
  final bool isSmallScreen;
  final void Function(String name, String gameId, int size, String requiredRank, String description) onSubmit;

  const _CreateTeamForm({required this.isSmallScreen, required this.onSubmit});

  @override
  State<_CreateTeamForm> createState() => _CreateTeamFormState();
}

class _CreateTeamFormState extends State<_CreateTeamForm> {
  List<GameModel> _games = [];
  bool _isLoadingGames = true;

  GameModel? _selectedGame;
  String? _selectedRank;
  int _selectedSize = 5;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  Future<void> _fetchGames() async {
    try {
      final games = await UserApiService().getPopularGames();
      if (!mounted) return;
      setState(() {
        _games = games;
        _isLoadingGames = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingGames = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? AppColors.error : AppColors.primary, behavior: SnackBarBehavior.floating),
    );
  }

  void _handleSubmit() {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập tên nhóm', isError: true);
      return;
    }
    if (_selectedGame == null) {
      _showSnackBar('Vui lòng chọn tựa game', isError: true);
      return;
    }
    if (_selectedRank == null) {
      _showSnackBar('Vui lòng chọn rank yêu cầu', isError: true);
      return;
    }
    if (_descController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập mô tả nhóm', isError: true);
      return;
    }
    widget.onSubmit(
      _nameController.text.trim(),
      _selectedGame!.id,
      _selectedSize,
      _selectedRank!,
      _descController.text.trim(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingGames) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Tạo Nhóm Mới', style: TextStyle(fontSize: widget.isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        _buildTextField(label: 'Tên nhóm', hint: 'Ví dụ: Team leo rank vui vẻ...', controller: _nameController, maxLines: 1),
        const SizedBox(height: 14),
        _buildDropdownGame(
          label: 'Tựa game',
          hint: 'Chọn tựa game',
          value: _selectedGame,
          items: _games,
          icon: Icons.sports_esports_rounded,
          onChanged: (GameModel? g) {
            setState(() {
              _selectedGame = g;
              _selectedRank = null; // reset rank khi đổi game
            });
          },
        ),
        const SizedBox(height: 14),
        _buildDropdownRank(
          label: 'Rank yêu cầu',
          hint: 'Chọn rank',
          value: _selectedRank,
          items: _selectedGame != null ? ['Không yêu cầu', ..._selectedGame!.ranks] : [],
          icon: Icons.emoji_events_rounded,
          onChanged: _selectedGame == null ? null : (v) => setState(() => _selectedRank = v),
        ),
        const SizedBox(height: 14),
        _buildSizeSelector(),
        const SizedBox(height: 14),
        _buildTextField(label: 'Mô tả nhóm', hint: 'Ví dụ: Team leo rank buổi tối, không toxic...', controller: _descController, maxLines: 3),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: widget.isSmallScreen ? 48 : 52,
          child: ElevatedButton.icon(
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Đăng Tin Tuyển Đội', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildSizeSelector() {
    final sizes = [2, 3, 4, 5];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Số lượng thành viên', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: sizes.map((size) {
            final isSelected = size == _selectedSize;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSize = size),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: size < sizes.last ? 8 : 0),
                  padding: EdgeInsets.symmetric(vertical: widget.isSmallScreen ? 12 : 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$size',
                    style: TextStyle(
                      fontSize: widget.isSmallScreen ? 14 : 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDropdownGame({
    required String label,
    required String hint,
    required GameModel? value,
    required List<GameModel> items,
    required IconData icon,
    required ValueChanged<GameModel?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: widget.isSmallScreen ? 12 : 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<GameModel>(
              value: value,
              hint: Text(hint, style: TextStyle(fontSize: widget.isSmallScreen ? 13 : 14, color: AppColors.textLight)),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              style: TextStyle(fontSize: widget.isSmallScreen ? 13 : 14, color: AppColors.textPrimary),
              dropdownColor: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              items: items.map((game) => DropdownMenuItem<GameModel>(value: game, child: Text(game.name))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRank({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: widget.isSmallScreen ? 12 : 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: TextStyle(fontSize: widget.isSmallScreen ? 13 : 14, color: AppColors.textLight)),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              style: TextStyle(fontSize: widget.isSmallScreen ? 13 : 14, color: AppColors.textPrimary),
              dropdownColor: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              items: items.map((rank) => DropdownMenuItem<String>(value: rank, child: Text(rank))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller, required int maxLines}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(fontSize: widget.isSmallScreen ? 13 : 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: widget.isSmallScreen ? 13 : 14, color: AppColors.textLight),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: EdgeInsets.all(widget.isSmallScreen ? 12 : 14),
          ),
        ),
      ],
    );
  }
}

class _CommunityTab extends StatelessWidget {
  final List<CommunityModel> communities;
  final bool isSmallScreen;

  const _CommunityTab({required this.communities, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Cộng đồng đã tham gia', style: TextStyle(fontSize: isSmallScreen ? 15 : 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...communities.map((comm) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _CommunityCard(community: comm, isSmallScreen: isSmallScreen))),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final CommunityModel community;
  final bool isSmallScreen;

  const _CommunityCard({required this.community, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CommunityChatScreen(community: community)));
      },
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: isSmallScreen ? 44 : 50,
              height: isSmallScreen ? 44 : 50,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.forum_rounded, color: AppColors.primary, size: isSmallScreen ? 22 : 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(community.name, style: TextStyle(fontSize: isSmallScreen ? 14 : 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('${community.memberCount} thành viên', style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('${community.onlineCount} online', style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: AppColors.success)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textLight, size: isSmallScreen ? 22 : 26),
          ],
        ),
      ),
    );
  }
}

class _TeamChatPanel extends StatefulWidget {
  final TeamModel team;
  final VoidCallback onClose;
  final String currentUserId;
  final String currentUserName;

  const _TeamChatPanel({
    required this.team,
    required this.onClose,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<_TeamChatPanel> createState() => _TeamChatPanelState();
}

class _TeamChatPanelState extends State<_TeamChatPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final TeamChatApiService _chatApiService = TeamChatApiService();
  bool _isLoading = false;
  String? _typingUserId;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupWebSocket();
  }

  void _setupWebSocket() {
    _wsSubscription = WebSocketClient.instance.eventStream.listen((event) {
      if (event.type == WsEventType.teamMessageCreated) {
        final teamId = event.data['teamId']?.toString();
        if (teamId == widget.team.id) {
          final messageId = event.data['messageId']?.toString() ?? '';
          final clientMessageId = event.data['clientMessageId']?.toString() ?? messageId;

          // Tránh duplicate: kiểm tra cả clientMessageId (optimistic) và serverMessageId
          final exists = _messages.any((m) =>
            m.clientMessageId == clientMessageId || m.serverMessageId == messageId);
          if (exists) return;

          // Parse server timestamp (UTC) và convert sang local time
          DateTime timestamp = DateTime.now();
          if (event.data['createdAt'] != null) {
            try {
              timestamp = DateTime.parse(event.data['createdAt'].toString()).toLocal();
            } catch (_) {}
          }

          final message = ChatMessage(
            clientMessageId: clientMessageId,
            serverMessageId: messageId,
            channelId: teamId,
            senderId: event.data['senderId']?.toString() ?? '',
            senderName: event.data['senderName'] as String? ?? 'Unknown',
            content: event.data['content'] as String? ?? '',
            timestamp: timestamp,
            status: MessageStatus.sent,
          );
          if (mounted) {
            setState(() {
              _messages.insert(0, message);
            });
            _scrollToBottom();
          }
        }
      }
    });

    // Subscribe to team room
    WebSocketClient.instance.subscribeRoom(widget.team.id, 'team');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _wsSubscription?.cancel();
    WebSocketClient.instance.unsubscribeRoom(widget.team.id, 'team');
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _chatApiService.getMessages(teamId: widget.team.id);
      if (mounted) {
        setState(() {
          _messages.addAll(messages);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Dùng UUID để tránh race condition với timestamp
    final clientMessageId = const Uuid().v4();
    final now = DateTime.now();
    final tempMessage = ChatMessage(
      clientMessageId: clientMessageId,
      channelId: widget.team.id,
      senderId: widget.currentUserId,
      senderName: 'Bạn',
      content: text,
      timestamp: now,
      status: MessageStatus.sending,
    );

    _messageController.clear();
    setState(() {
      _messages.insert(0, tempMessage);
    });

    try {
      final result = await _chatApiService.sendMessage(
        teamId: widget.team.id,
        clientMessageId: clientMessageId,
        content: text,
      );
      if (result != null && mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.clientMessageId == clientMessageId);
          if (index != -1) {
            _messages[index] = result;
          }
        });
      }
    } catch (_) {
      // Message failed, could show error indicator
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth < 500 ? screenWidth * 0.85 : 380.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: panelWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF313338),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E1F22), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.tag, color: Color(0xFF949BA4), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.team.name,
                    style: const TextStyle(
                      color: Color(0xFFF2F3F5),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close, color: Color(0xFF949BA4), size: 20),
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5865F2)),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có tin nhắn nào',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hãy gửi tin nhắn đầu tiên!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == widget.currentUserId;
                          return _ChatMessageBubble(
                            message: msg,
                            isMe: isMe,
                            currentUserName: widget.currentUserName,
                          );
                        },
                      ),
          ),
          // Typing indicator
          if (_typingUserId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '$_typingUserId đang nhập...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF313338),
              border: Border(
                top: BorderSide(color: Color(0xFF1E1F22), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Color(0xFFF2F3F5), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Nhắn tin trong ${widget.team.name}',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                      filled: true,
                      fillColor: const Color(0xFF383A40),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5865F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String? currentUserName;

  const _ChatMessageBubble({
    required this.message,
    required this.isMe,
    this.currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMe) const Spacer(),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF5865F2) : const Color(0xFF383A40),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      message.senderName == 'Unknown' && currentUserName != null && currentUserName!.isNotEmpty
                          ? currentUserName!
                          : message.senderName,
                      style: const TextStyle(
                        color: Color(0xFF949BA4),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Text(
                  message.content,
                  style: const TextStyle(
                    color: Color(0xFFF2F3F5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (!isMe) const Spacer(),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TeamChatFullScreen extends StatefulWidget {
  final TeamModel team;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback onClose;

  const _TeamChatFullScreen({
    required this.team,
    required this.currentUserId,
    required this.currentUserName,
    required this.onClose,
  });

  @override
  State<_TeamChatFullScreen> createState() => _TeamChatFullScreenState();
}

class _TeamChatFullScreenState extends State<_TeamChatFullScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final TeamChatApiService _chatApiService = TeamChatApiService();
  bool _isLoading = false;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupWebSocket();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _wsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs = await _chatApiService.getMessages(teamId: widget.team.id);
      if (mounted) {
        setState(() {
          _messages.addAll(msgs);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupWebSocket() {
    _wsSubscription = WebSocketClient.instance.eventStream.listen((event) {
      if (event.type == WsEventType.teamMessageCreated) {
        final teamId = event.data['teamId']?.toString();
        if (teamId == widget.team.id) {
          final messageId = event.data['messageId']?.toString() ?? '';
          final clientMessageId = event.data['clientMessageId']?.toString() ?? messageId;

          final exists = _messages.any((m) =>
            m.clientMessageId == clientMessageId || m.serverMessageId == messageId);
          if (exists) return;

          DateTime timestamp = DateTime.now();
          if (event.data['createdAt'] != null) {
            try {
              timestamp = DateTime.parse(event.data['createdAt'].toString()).toLocal();
            } catch (_) {}
          }

          final message = ChatMessage(
            clientMessageId: clientMessageId,
            serverMessageId: messageId,
            channelId: teamId,
            senderId: event.data['senderId']?.toString() ?? '',
            senderName: event.data['senderName'] as String? ?? 'Unknown',
            content: event.data['content'] as String? ?? '',
            timestamp: timestamp,
            status: MessageStatus.sent,
          );
          if (mounted) {
            setState(() {
              _messages.insert(0, message);
            });
            _scrollToBottom();
          }
        }
      }
    });

    WebSocketClient.instance.subscribeRoom(widget.team.id, 'team');
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      await _chatApiService.sendMessage(
        teamId: widget.team.id,
        clientMessageId: tempId,
        content: content,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi tin nhắn thất bại')),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          widget.onClose();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF313338),
        body: SafeArea(
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF949BA4).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF313338),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF1E1F22), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tag, color: Color(0xFF949BA4), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.team.name,
                        style: const TextStyle(
                          color: Color(0xFFF2F3F5),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close, color: Color(0xFF949BA4), size: 20),
                      ),
                    ),
                  ],
                ),
                          ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF5865F2)))
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                                const SizedBox(height: 12),
                                Text('Chưa có tin nhắn nào', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMe = msg.senderId == widget.currentUserId;
                              return _ChatMessageBubble(
                                message: msg,
                                isMe: isMe,
                                currentUserName: widget.currentUserName,
                              );
                            },
                          ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF313338),
                  border: Border(top: BorderSide(color: Color(0xFF1E1F22), width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Color(0xFFF2F3F5)),
                        decoration: InputDecoration(
                          hintText: 'Nhắn tin...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                          filled: true,
                          fillColor: const Color(0xFF383A40),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF5865F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
