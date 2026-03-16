import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/local_db.dart';
import '../theme/app_theme.dart';
import '../models/chat.dart';
import '../models/contact.dart';
import '../services/contacts_service.dart';
import '../services/profile_service.dart';
import '../providers/message_provider.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';
import 'edit_profile_screen.dart';

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

// ── Chats Tab ──

class ChatsTab extends ConsumerStatefulWidget {
  const ChatsTab({super.key});

  @override
  ConsumerState<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends ConsumerState<ChatsTab> {
  List<Contact> _contacts = [];
  List<_ChatPreview> _dbPreviews = [];
  final Map<String, _SenderProfile> _profileCache = {};

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadDbPreviews();
  }

  Future<void> _loadContacts() async {
    final contacts = await ContactsService.loadContacts();
    if (mounted) setState(() => _contacts = contacts);
  }

  Future<void> _loadDbPreviews() async {
    final rows = await LocalDb.getChatPreviews();
    final previews = rows.map((row) {
      return _ChatPreview(
        userId: row['chat_id'] as String,
        lastMessage: row['last_message'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(row['last_timestamp'] as int),
        unread: 0,
      );
    }).toList();

    if (mounted) setState(() => _dbPreviews = previews);
  }

  Contact? _findContact(String userId) {
    try {
      return _contacts.firstWhere((c) => c.id == userId);
    } catch (_) {
      return null;
    }
  }

  Future<_SenderProfile> _fetchProfile(String userId) async {
    if (_profileCache.containsKey(userId)) {
      return _profileCache[userId]!;
    }
    try {
      final profile = await ProfileService.getProfile(userId);
      final result = _SenderProfile(
        displayName: profile['displayName'] as String?,
        avatarBase64: profile['avatarBase64'] as String?,
      );
      _profileCache[userId] = result;
      return result;
    } catch (_) {
      final fallback = _SenderProfile();
      _profileCache[userId] = fallback;
      return fallback;
    }
  }

  void _promptAddContact(BuildContext context, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) {
        final nameController = TextEditingController(text: name);
        return AlertDialog(
          backgroundColor: AppTheme.backgroundSecondary,
          title: const Text(
            'Add to contacts?',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.backgroundPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final contactName = nameController.text.trim();
                if (contactName.isEmpty) return;
                await ContactsService.addContact(Contact(
                  id: userId,
                  name: contactName,
                  avatar: '',
                  phoneNumber: '',
                ));
                await _loadContacts();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save',
                  style: TextStyle(color: AppTheme.accentColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final incoming = ref.watch(messagesProvider);
    final sent = ref.watch(sentMessagesProvider);

    final Map<String, _ChatPreview> chatPreviews = {};

    for (final p in _dbPreviews) {
      chatPreviews[p.userId] = p;
    }

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
                final isUnknown = contact == null;
                final timeStr =
                    '${preview.timestamp.hour}:${preview.timestamp.minute.toString().padLeft(2, '0')}';

                return FutureBuilder<_SenderProfile>(
                  future: _fetchProfile(preview.userId),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    final name = contact?.name ??
                        profile?.displayName ??
                        preview.userId.substring(0, 8);
                    final avatarB64 = profile?.avatarBase64;

                    return _buildChatTile(
                      context: context,
                      preview: preview,
                      name: name,
                      avatarBase64: avatarB64,
                      avatarPath: contact?.avatar ?? '',
                      timeStr: timeStr,
                      isUnknown: isUnknown,
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

  Widget _buildChatTile({
    required BuildContext context,
    required _ChatPreview preview,
    required String name,
    String? avatarBase64,
    required String avatarPath,
    required String timeStr,
    required bool isUnknown,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: UserAvatar(
        avatarPath: avatarPath,
        name: name,
        avatarBase64: avatarBase64,
      ),
      title: Text(
        name,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontStyle: isUnknown ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      subtitle: Text(
        preview.lastMessage,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
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
                color: AppTheme.textSecondary, fontSize: 12),
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
          avatar: avatarPath,
          lastMessage: preview.lastMessage,
          time: timeStr,
          unreadCount: 0,
          messages: [],
          avatarBase64: avatarBase64,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      },
      onLongPress: isUnknown
          ? () => _promptAddContact(context, preview.userId, name)
          : null,
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

class _SenderProfile {
  final String? displayName;
  final String? avatarBase64;
  _SenderProfile({this.displayName, this.avatarBase64});
}

// ── Settings Tab ──

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String? _displayName;
  String? _avatarBase64;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.getMyProfile();
      if (mounted) {
        setState(() {
          _displayName = profile['displayName'] as String?;
          _avatarBase64 = profile['avatarBase64'] as String?;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openEditProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          currentName: _displayName,
          currentAvatarBase64: _avatarBase64,
        ),
      ),
    );
    if (result == true) _loadProfile();
  }

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
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.accentColor))
          : ListView(
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _openEditProfile,
                  child: Column(
                    children: [
                      UserAvatar(
                        avatarPath: '',
                        name: _displayName ?? '?',
                        radius: 40,
                        avatarBase64: _avatarBase64,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _displayName ?? 'Set your name',
                        style: TextStyle(
                          color: _displayName != null
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontStyle: _displayName != null
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to edit profile',
                        style: TextStyle(
                          color:
                              AppTheme.textSecondary.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSettingItem(
                    Icons.notifications_outlined, 'Notifications'),
                _buildSettingItem(Icons.lock_outline, 'Privacy'),
                _buildSettingItem(
                    Icons.storage_outlined, 'Storage and data'),
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
      trailing:
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: () {},
    );
  }
}
