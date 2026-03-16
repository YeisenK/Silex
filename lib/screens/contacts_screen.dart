import 'package:flutter/material.dart';
import 'package:silex/theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import '../models/contact.dart';
import '../models/chat.dart';
import '../services/contacts_service.dart';
import 'add_contact_screen.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> _contacts = [];
  bool _isLoading = true;

  static const Color backgroundColor = AppTheme.backgroundPrimary;
  static const Color secondaryBackground = AppTheme.backgroundSecondary;
  static const Color accentColor = AppTheme.accentColor;
  static const Color textPrimary = AppTheme.textPrimary;
  static const Color textSecondary = AppTheme.textSecondary;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await ContactsService.loadContacts();
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    }
  }

  void _openChat(Contact contact) {
    final chat = Chat(
      id: contact.id,
      name: contact.name,
      avatar: contact.avatar,
      lastMessage: '',
      time: '',
      unreadCount: 0,
      messages: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(chat: chat)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: secondaryBackground,
        iconTheme: const IconThemeData(color: textPrimary),
        title: const Text('Contacts', style: TextStyle(color: textPrimary)),
        actions: const [
          Icon(Icons.search, color: textPrimary),
          SizedBox(width: 12),
          Icon(Icons.more_vert, color: textPrimary),
          SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : _contacts.isEmpty
              ? const Center(
                  child: Text(
                    'No contacts yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: UserAvatar(
                        avatarPath: contact.avatar,
                        name: contact.name,
                      ),
                      title: Text(
                        contact.name,
                        style: const TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        contact.phoneNumber,
                        style: const TextStyle(color: textSecondary, fontSize: 14),
                      ),
                      trailing: const Icon(Icons.message_outlined, color: accentColor),
                      onTap: () => _openChat(contact),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        onPressed: () async {
          final result = await showModalBottomSheet<Contact>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddContactScreen(),
          );
          if (result != null) _loadContacts();
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}