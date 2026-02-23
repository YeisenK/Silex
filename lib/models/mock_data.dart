
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
}

class Message {
  final String id;
  final String text;
  final String time;
  final bool isSentByMe;
  final MessageType type;
  final String? imageUrl;
  final String? linkTitle;
  final String? linkSubtitle;
  final String? linkUrl;

  Message({
    required this.id,
    required this.text,
    required this.time,
    required this.isSentByMe,
    this.type = MessageType.text,
    this.imageUrl,
    this.linkTitle,
    this.linkSubtitle,
    this.linkUrl,
  });
}

enum MessageType {
  text,
  image,
  video,
  link,
}

class Contact {
  final String id;
  final String name;
  final String avatar;
  final String phoneNumber;
  final bool isOnline;

  Contact({
    required this.id,
    required this.name,
    required this.avatar,
    required this.phoneNumber,
    this.isOnline = false,
  });
}

final List<Chat> mockChats = [
  Chat(
    id: '1',
    name: 'PopDog',
    avatar: '../assets/avatars/popdog.jpg',
    lastMessage: 'GUAU!?',
    time: '4:30 PM',
    unreadCount: 2,
    isOnline: true,
    messages: [
      Message(
        id: 'm1',
        text: 'GUAU!?',
        time: '4:29 PM',
        isSentByMe: false,
      ),
      Message(
        id: 'm2',
        text: '¿Qué pasó?',
        time: '4:30 PM',
        isSentByMe: true,
      ),
    ],
  ),
  Chat(
    id: '2',
    name: 'Lizard the wizard',
    avatar: '../assets/avatars/lizard.jpg',
    lastMessage: 'Looks great!',
    time: '4:23 PM',
    unreadCount: 1,
    messages: [
      Message(
        id: 'm3',
        text: 'Looks great!',
        time: '4:23 PM',
        isSentByMe: false,
      ),
    ],
  ),
  Chat(
    id: '3',
    name: 'Firu',
    avatar: '../assets/avatars/firu.jpg',
    lastMessage: 'Lunch on Monday?',
    time: '4:12 PM',
    unreadCount: 0,
    messages: [
      Message(
        id: 'm4',
        text: 'Lunch on Monday?',
        time: '4:12 PM',
        isSentByMe: false,
      ),
    ],
  ),
  Chat(
    id: '4',
    name: 'Big Yahu',
    avatar: '../assets/avatars/bigyahu.jpg',
    lastMessage: 'You sent a photo.',
    time: '3:58 PM',
    unreadCount: 0,
    messages: [
      Message(
        id: 'm5',
        text: '',
        time: '3:58 PM',
        isSentByMe: true,
        type: MessageType.image,
        imageUrl: 'https://example.com/photo.jpg',
      ),
    ],
  ),
  Chat(
    id: '5',
    name: 'Eziro',
    avatar: '../assets/avatars/eziro.jpg',
    lastMessage: 'Eziro sent a photo.',
    time: '3:31 PM',
    unreadCount: 0,
    messages: [
      Message(
        id: 'm6',
        text: '',
        time: '3:31 PM',
        isSentByMe: false,
        type: MessageType.image,
        imageUrl: 'https://example.com/eziro-photo.jpg',
      ),
    ],
  ),
  Chat(
    id: '6',
    name: 'Sciurus',
    avatar: '../assets/avatars/sciurus.jpg',
    lastMessage: 'Acorn mission complete.',
    time: '3:30 PM',
    unreadCount: 0,
    messages: [
      Message(
        id: 'm7',
        text: 'Acorn mission complete.',
        time: '3:30 PM',
        isSentByMe: false,
      ),
    ],
  ),
];

final List<Contact> mockContacts = [
  Contact(
    id: '1',
    name: 'PopDog',
    avatar: '../assets/avatars/popdog.jpg',
    phoneNumber: '+52 55 1000 0001',
    isOnline: true,
  ),
  Contact(
    id: '2',
    name: 'Lizard the wizard',
    avatar: '../assets/avatars/lizard.jpg',
    phoneNumber: '+52 55 1000 0002',
    isOnline: true,
  ),
  Contact(
    id: '3',
    name: 'Firu',
    avatar: '../assets/avatars/firu.jpg',
    phoneNumber: '+52 55 1000 0003',
    isOnline: false,
  ),
  Contact(
    id: '4',
    name: 'Big Yahu',
    avatar: '../assets/avatars/bigyahu.jpg',
    phoneNumber: '+52 55 1000 0004',
    isOnline: false,
  ),
  Contact(
    id: '5',
    name: 'Eziro',
    avatar: '../assets/avatars/eziro.jpg',
    phoneNumber: '+52 55 1000 0005',
    isOnline: false,
  ),
  Contact(
    id: '6',
    name: 'Sciurus',
    avatar: '../assets/avatars/sciurus.jpg',
    phoneNumber: '+52 55 1000 0006',
    isOnline: true,
  ),
];