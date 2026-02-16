import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../../config/theme.dart';
import '../../models/user.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddFriendDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email or Phone',
            hintText: 'Enter email or phone number',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = emailController.text.trim();
              if (value.isEmpty) return;

              final friendProvider =
                  Provider.of<FriendProvider>(context, listen: false);

              final success = await friendProvider.sendFriendRequest(
                email: value.contains('@') ? value : null,
                phone: !value.contains('@') ? value : null,
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Friend request sent!'
                          : friendProvider.error ?? 'Failed to send request',
                    ),
                    backgroundColor:
                        success ? AppTheme.successColor : AppTheme.dangerColor,
                  ),
                );
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddFriendDialog,
          ),
        ],
      ),
      body: Consumer<FriendProvider>(
        builder: (context, friendProvider, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await friendProvider.fetchFriends();
              await friendProvider.fetchPendingRequests();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pending Requests
                  if (friendProvider.receivedRequests.isNotEmpty) ...[
                    const Text(
                      'Friend Requests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...friendProvider.receivedRequests.map((request) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              request.user?.name.substring(0, 1).toUpperCase() ??
                                  '?',
                            ),
                          ),
                          title: Text(request.user?.name ?? 'Unknown'),
                          subtitle: Text(request.user?.email ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: AppTheme.successColor),
                                onPressed: () async {
                                  await friendProvider.acceptRequest(request.id);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: AppTheme.dangerColor),
                                onPressed: () async {
                                  await friendProvider.rejectRequest(request.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Friends List
                  const Text(
                    'My Friends',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (friendProvider.friends.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline,
                                  size: 48, color: AppTheme.textSecondary),
                              SizedBox(height: 8),
                              Text(
                                'No friends yet',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              Text(
                                'Tap + to add friends',
                                style: TextStyle(
                                    color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...friendProvider.friends.map((friend) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              friend.name.substring(0, 1).toUpperCase(),
                            ),
                          ),
                          title: Text(friend.name),
                          subtitle: Text(friend.email),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(Icons.person_remove,
                                        color: AppTheme.dangerColor),
                                    SizedBox(width: 8),
                                    Text('Remove'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'remove') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Remove Friend'),
                                    content: Text(
                                        'Remove ${friend.name} from friends?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.dangerColor,
                                        ),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await friendProvider.removeFriend(friend.id);
                                }
                              }
                            },
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
