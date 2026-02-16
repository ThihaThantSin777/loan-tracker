import 'user.dart';

class Friendship {
  final int id;
  final int userId;
  final int friendId;
  final String status;
  final DateTime createdAt;
  final User? user;
  final User? friend;

  Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
    this.user,
    this.friend,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'],
      userId: json['user_id'],
      friendId: json['friend_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      friend: json['friend'] != null ? User.fromJson(json['friend']) : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
}
