import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/chat.dart';
import '../models/contact.dart';
import '../services/contacts_service.dart';
import '../providers/message_provider.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ChatsTab(),
    const ContactsScreen(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.surfaceColor,
        selectedItemColor: AppTheme.accentColor,
        unselectedItemColor: AppTheme.textSecondary,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class ChatsTab extends ConsumerStatefulWidget {
  const ChatsTab({super.key});

  @override
  ConsumerState<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends ConsumerState<ChatsTab> {
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await ContactsService.loadContacts();
    if (mounted) setState(() => _contacts = contacts);
  }

  Contact? _findContact(String userId) {
    try {
      return _contacts.firstWhere((c) => c.id == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final incoming = ref.watch(messagesProvider);
    final sent = ref.watch(sentMessagesProvider);

    // collect all user IDs that have messages
    final Map<String, _ChatPreview> chatPreviews = {};

    for (final m in incoming) {
      final isRead = ref.read(messagesProvider.notifier).isRead(m.messageId);
      final existing = chatPreviews[m.senderId];
      if (existing == null || m.receivedAt.isAfter(existing.timestamp)) {
        chatPreviews[m.senderId] = _ChatPreview(
          userId: m.senderId,
          lastMessage: m.plaintext,
          timestamp: m.receivedAt,
          unread: (existing?.unread ?? 0) + (isRead ? 0 : 1),
        );
      } else if (!isRead) {
        chatPreviews[m.senderId] = _ChatPreview(
          userId: existing.userId,
          lastMessage: existing.lastMessage,
          timestamp: existing.timestamp,
          unread: existing.unread + 1,
        );
      }
    }

    for (final m in sent) {
      final existing = chatPreviews[m.recipientId];
      if (existing == null || m.sentAt.isAfter(existing.timestamp)) {
        chatPreviews[m.recipientId] = _ChatPreview(
          userId: m.recipientId,
          lastMessage: m.ciphertext,
          timestamp: m.sentAt,
          unread: existing?.unread ?? 0,
        );
      }
    }

    final sortedChats = chatPreviews.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundSecondary,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: const Text(
          'Chats',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: const [
          Icon(Icons.search, color: AppTheme.textPrimary),
          SizedBox(width: 12),
          Icon(Icons.more_vert, color: AppTheme.textPrimary),
          SizedBox(width: 12),
        ],
      ),
      body: sortedChats.isEmpty
          ? const Center(
              child: Text(
                'No chats yet.\nStart a conversation from Contacts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: sortedChats.length,
              itemBuilder: (context, index) {
                final preview = sortedChats[index];
                final contact = _findContact(preview.userId);
                final name = contact?.name ?? preview.userId.substring(0, 8);
                final avatar = contact?.avatar ?? '';
                final timeStr =
                    '${preview.timestamp.hour}:${preview.timestamp.minute.toString().padLeft(2, '0')}';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: UserAvatar(avatarPath: avatar, name: name),
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    preview.lastMessage,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (preview.unread > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            preview.unread.toString(),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    final chat = Chat(
                      id: preview.userId,
                      name: name,
                      avatar: avatar,
                      lastMessage: preview.lastMessage,
                      time: timeStr,
                      unreadCount: 0,
                      messages: [],
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(chat: chat),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentColor,
        onPressed: () {},
        child: const Icon(Icons.edit, color: AppTheme.textPrimary),
      ),
    );
  }
}

class _ChatPreview {
  final String userId;
  final String lastMessage;
  final DateTime timestamp;
  final int unread;

  _ChatPreview({
    required this.userId,
    required this.lastMessage,
    required this.timestamp,
    required this.unread,
  });
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundSecondary,
        title: const Text(
          'Settings',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const Center(
            child: UserAvatar(
              avatarPath: 'assets/user/pfp.jpg',
              name: 'John Doe',
              radius: 40,
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'John Doe',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              '+1 234-567-8900',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(height: 32),
          _buildSettingItem(Icons.notifications_outlined, 'Notifications'),
          _buildSettingItem(Icons.lock_outline, 'Privacy'),
          _buildSettingItem(Icons.storage_outlined, 'Storage and data'),
          _buildSettingItem(Icons.apps_outlined, 'Apps'),
          _buildSettingItem(Icons.help_outline, 'Help'),
          _buildSettingItem(Icons.info_outline, 'About'),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(
        title,
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: () {},
    );
  }
}