import 'message.dart';

class Chat {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final List<Message> messages;
  final String? avatarBase64;

  Chat({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    this.isOnline = false,
    required this.messages,
    this.avatarBase64,
  });

  Chat.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String,
        avatar = json['avatar'] as String,
        lastMessage = json['lastMessage'] as String,
        time = json['time'] as String,
        unreadCount = json['unreadCount'] as int,
        isOnline = json['isOnline'] as bool,
        messages = json['messages'] as List<Message>,
        avatarBase64 = json['avatarBase64'] as String?;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'lastMessage': lastMessage,
      'time': time,
      'unreadCount': unreadCount,
      'isOnline': isOnline,
      'messages': messages,
      'avatarBase64': avatarBase64,
    };
  }
}
