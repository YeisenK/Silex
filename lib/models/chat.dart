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

    Chat({
      required this.id,
      required this.name,
      required this.avatar,
      required this.lastMessage,
      required this.time,
      required this.unreadCount,
      this.isOnline = false,
      required this.messages,
    });


    Chat.fromJson(Map<String, dynamic> json):
      id = json['id'] as String,
      name = json['name'] as String,
      avatar = json['avatar'] as String,
      lastMessage = json['lastMessage'] as String,
      time = json['time'] as String,
      unreadCount = json['unreadCount'] as int,
      isOnline = json['isOnline'] as bool,
      messages = json['messages'] as List<Message>;

      Map<String, dynamic> toJson() {
        return{
          'id': id,
          'name': name,
          'avatar': avatar,
          'lastMessage': lastMessage,
          'time': time,
          'unreadCount': unreadCount,
          'isOnline': isOnline,
          'messages': messages,
        };
      } 


  }