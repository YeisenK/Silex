// ignore: unused_import
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/local_db.dart';
import '../core/storage_service.dart';
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
import 'privacy_policy_screen.dart';

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

// ══════════════════════════════════════════
// Chats Tab
// ══════════════════════════════════════════

class ChatsTab extends ConsumerStatefulWidget {
  const ChatsTab({super.key});

  @override
  ConsumerState<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends ConsumerState<ChatsTab> {
  List<Contact> _contacts = [];
  List<_ChatPreview> _dbPreviews = [];
  final Map<String, _SenderProfile> _profileCache = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadContacts();
    await _loadDbPreviews();
    await _loadCachedAvatars();
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

  Future<void> _loadCachedAvatars() async {
    final cached = await LocalDb.getAllCachedAvatars();
    for (final entry in cached.entries) {
      _profileCache[entry.key] = _SenderProfile(avatarBase64: entry.value);
    }
    if (mounted) setState(() {});
  }

  Contact? _findContact(String userId) {
    try {
      return _contacts.firstWhere((c) => c.id == userId);
    } catch (_) {
      return null;
    }
  }

  String _resolveName(String userId) {
    final contact = _findContact(userId);
    if (contact != null) return contact.name;
    final profile = _profileCache[userId];
    if (profile?.displayName != null) return profile!.displayName!;
    return userId.substring(0, 8);
  }

  Future<_SenderProfile> _fetchProfile(String userId) async {
    if (_profileCache.containsKey(userId) &&
        _profileCache[userId]!.avatarBase64 != null) {
      return _profileCache[userId]!;
    }

    final cachedAvatar = await LocalDb.getCachedAvatar(userId);
    if (cachedAvatar != null && !_profileCache.containsKey(userId)) {
      final result = _SenderProfile(avatarBase64: cachedAvatar);
      _profileCache[userId] = result;
    }

    try {
      final profile = await ProfileService.getProfile(userId);
      final avatar = profile['avatarBase64'] as String?;
      final name = profile['displayName'] as String?;
      if (avatar != null) {
        await LocalDb.cacheAvatar(userId, avatar);
      }
      final result = _SenderProfile(displayName: name, avatarBase64: avatar);
      _profileCache[userId] = result;
      return result;
    } catch (_) {
      return _profileCache[userId] ?? _SenderProfile();
    }
  }

  void _promptAddContact(BuildContext context, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) {
        final nameController = TextEditingController(text: name);
        return AlertDialog(
          backgroundColor: AppTheme.backgroundSecondary,
          title: const Text('Add to contacts?',
              style: TextStyle(color: AppTheme.textPrimary)),
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
                  borderSide: BorderSide.none),
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
                    id: userId, name: contactName, avatar: '', phoneNumber: ''));
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

    var sortedChats = chatPreviews.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // filter by search
    if (_searchQuery.isNotEmpty) {
      sortedChats = sortedChats.where((preview) {
        final name = _resolveName(preview.userId).toLowerCase();
        return name.contains(_searchQuery);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundSecondary,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: const Text('Chats', style: TextStyle(color: AppTheme.textPrimary)),
      ),
      body: Column(
        children: [
          // search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixIcon:
                      const Icon(Icons.search, color: AppTheme.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close,
                              color: AppTheme.textSecondary, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: sortedChats.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'No chats matching "$_searchQuery"'
                          : 'No chats yet.\nStart a conversation from Contacts.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 16),
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
          ),
        ],
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
          avatarPath: avatarPath, name: name, avatarBase64: avatarBase64),
      title: Text(name,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontStyle: isUnknown ? FontStyle.italic : FontStyle.normal,
          )),
      subtitle: Text(preview.lastMessage,
          style:
              const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(timeStr,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          if (preview.unread > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: AppTheme.accentColor, shape: BoxShape.circle),
              child: Text(preview.unread.toString(),
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chat: Chat(
                id: preview.userId,
                name: name,
                avatar: avatarPath,
                lastMessage: preview.lastMessage,
                time: timeStr,
                unreadCount: 0,
                messages: [],
                avatarBase64: avatarBase64,
              ),
            ),
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
  _ChatPreview(
      {required this.userId,
      required this.lastMessage,
      required this.timestamp,
      required this.unread});
}

class _SenderProfile {
  final String? displayName;
  final String? avatarBase64;
  _SenderProfile({this.displayName, this.avatarBase64});
}

// ══════════════════════════════════════════
// Settings Tab
// ══════════════════════════════════════════

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
        title: const Text('Settings',
            style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor))
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
                          color: AppTheme.textSecondary.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _SettingItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const _NotificationsScreen())),
                ),
                _SettingItem(
                  icon: Icons.lock_outline,
                  title: 'Privacy',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const _PrivacySettingsScreen())),
                ),
                _SettingItem(
                  icon: Icons.storage_outlined,
                  title: 'Storage and data',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const _StorageScreen())),
                ),
                _SettingItem(
                  icon: Icons.help_outline,
                  title: 'Help',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const _HelpScreen())),
                ),
                _SettingItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                ),
              ],
            ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}

// ══════════════════════════════════════════
// Notifications Screen
// ══════════════════════════════════════════

class _NotificationsScreen extends StatefulWidget {
  const _NotificationsScreen();

  @override
  State<_NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<_NotificationsScreen> {
  bool _messageNotifications = true;
  bool _showPreviews = true;
  bool _vibrate = true;
  bool _sound = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final msg = await StorageService.getKey('pref_notif_messages');
    final prev = await StorageService.getKey('pref_notif_previews');
    final vib = await StorageService.getKey('pref_notif_vibrate');
    final snd = await StorageService.getKey('pref_notif_sound');
    if (mounted) {
      setState(() {
        _messageNotifications = msg != 'false';
        _showPreviews = prev != 'false';
        _vibrate = vib != 'false';
        _sound = snd != 'false';
      });
    }
  }

  Future<void> _save(String key, bool value) async {
    await StorageService.saveKey(key, value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundSecondary,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: const Text('Notifications',
            style: TextStyle(color: AppTheme.textPrimary)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Message notifications',
                style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: const Text('Show notifications for new messages',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            value: _messageNotifications,
            activeColor: AppTheme.accentColor,
            onChanged: (v) {
              setState(() => _messageNotifications = v);
              _save('pref_notif_messages', v);
            },
          ),
          SwitchListTile(
            title: const Text('Show previews',
                style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: const Text('Show message content in notifications',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            value: _showPreviews,
            activeColor: AppTheme.accentColor,
            onChanged: (v) {
              setState(() => _showPreviews = v);
              _save('pref_notif_previews', v);
            },
          ),
          const Divider(color: AppTheme.textSecondary, height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: const Text('Vibrate',
                style: TextStyle(color: AppTheme.textPrimary)),
            value: _vibrate,
            activeColor: AppTheme.accentColor,
            onChanged: (v) {
              setState(() => _vibrate = v);
              _save('pref_notif_vibrate', v);
            },
          ),
          SwitchListTile(
            title: const Text('Sound',
                style: TextStyle(color: AppTheme.textPrimary)),
            value: _sound,
            activeColor: AppTheme.accentColor,
            onChanged: (v) {
              setState(() => _sound = v);
              _save('pref_notif_sound', v);
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// Privacy Settings Screen
// ══════════════════════════════════════════

class _PrivacySettingsScreen extends StatefulWidget {
  const _PrivacySettingsScreen();

  @override
  State<_PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<_PrivacySettingsScreen> {
  bool _readReceipts = true;
  bool _typingIndicators = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final rr = await StorageService.getKey('pref_privacy_read_receipts');
    final ti = await StorageService.getKey('pref_privacy_typing');
    if (mounted) {
      setState(() {
        _readReceipts = rr != 'false';
        _typingIndicators = ti != 'false';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundSecondary,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: const Text('Privacy',
            style: TextStyle(color: AppTheme.textPrimary)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Read receipts',
                style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: const Text(
                'Let others see when you\'ve read their messages',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            value: _readReceipts,
            activeColor: AppTheme.accentColor,
            onChanged: (v) {
              setState(() => _readReceipts = v);
              StorageService.saveKey('pref_privacy_read_receipts', v.toString());
            },
          ),
          SwitchListTile(
            title: const Text('Typing indicators',
                style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: const Text(
                'Let others see when you\'re typing',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            value: _typingIndicators,
            activeColor: AppTheme.accentColor,
            onChanged: (v) {
              setState(() => _typingIndicators = v);
              StorageService.saveKey('pref_privacy_typing', v.toString());
            },
          ),
          const Divider(color: AppTheme.textSecondary, height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.shield_outlined, color: AppTheme.textSecondary),
            title: const Text('Privacy policy',
                style: TextStyle(color: AppTheme.textPrimary)),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: AppTheme.accentColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All messages are end-to-end encrypted. Not even Silex can read them.',
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// Storage Screen
// ══════════════════════════════════════════

class _StorageScreen extends StatefulWidget {
  const _StorageScreen();

  @override
  State<_StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<_StorageScreen> {
  int _messageCount = 0;
  int _chatCount = 0;
  int _avatarCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final db = await LocalDb.database;
      final msgResult =
          await db.rawQuery('SELECT COUNT(*) AS c FROM messages');
      final chatResult = await db
          .rawQuery('SELECT COUNT(DISTINCT chat_id) AS c FROM messages');
      final avatarResult =
          await db.rawQuery('SELECT COUNT(*) AS c FROM avatar_cache');

      if (mounted) {
        setState(() {
          _messageCount = (msgResult.first['c'] as int?) ?? 0;
          _chatCount = (chatResult.first['c'] as int?) ?? 0;
          _avatarCount = (avatarResult.first['c'] as int?) ?? 0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: const Text('Clear all chat history?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
            'This will delete all local messages. This cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear',
                style: TextStyle(color: Color(0xFFE57373))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LocalDb.clearAll();
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat history cleared'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundSecondary,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: const Text('Storage and data',
            style: TextStyle(color: AppTheme.textPrimary)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor))
          : ListView(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Local storage',
                      style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                _StorageStat(
                    label: 'Messages stored', value: '$_messageCount'),
                _StorageStat(
                    label: 'Active chats', value: '$_chatCount'),
                _StorageStat(
                    label: 'Cached avatars', value: '$_avatarCount'),
                const SizedBox(height: 24),
                const Divider(
                    color: AppTheme.textSecondary,
                    height: 1,
                    indent: 16,
                    endIndent: 16),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Color(0xFFE57373)),
                  title: const Text('Clear chat history',
                      style: TextStyle(color: Color(0xFFE57373))),
                  subtitle: const Text('Delete all local messages',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  onTap: _clearHistory,
                ),
              ],
            ),
    );
  }
}

class _StorageStat extends StatelessWidget {
  final String label;
  final String value;
  const _StorageStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontFamily: 'ShareTechMono',
                  fontSize: 14)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// Help Screen
// ══════════════════════════════════════════

class _HelpScreen extends StatelessWidget {
  const _HelpScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundSecondary,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title:
            const Text('Help', style: TextStyle(color: AppTheme.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Frequently Asked Questions',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _HelpItem(
              question: 'How does end-to-end encryption work?',
              answer:
                  'Messages are encrypted on your device before sending. Only the recipient\'s device can decrypt them. The server only sees encrypted data it cannot read.',
            ),
            _HelpItem(
              question: 'What is a Safety Number?',
              answer:
                  'A unique code derived from both users\' identity keys. Compare it in person or via QR scan to verify you\'re messaging the right person with no interception.',
            ),
            _HelpItem(
              question: 'What happens if I forget my PIN?',
              answer:
                  'Your PIN encrypts your private keys. If forgotten, you\'ll need to re-register, which generates new keys. Previous messages cannot be recovered.',
            ),
            _HelpItem(
              question: 'Can Silex read my messages?',
              answer:
                  'No. The server has zero knowledge of message content. It only relays encrypted data. Even if the server is compromised, your messages remain private.',
            ),
            _HelpItem(
              question: 'How do I add a contact?',
              answer:
                  'Go to Contacts tab → tap the + button → enter their phone number. If they\'re on Silex, they\'ll appear and you can start chatting.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.mail_outline,
                      color: AppTheme.accentColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For more help, contact the developer through the project\'s official channel.',
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final String question;
  final String answer;
  const _HelpItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(answer,
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 12,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
                height: 1.6,
              )),
        ],
      ),
    );
  }
}