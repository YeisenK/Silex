import 'package:flutter/material.dart';
import '../widgets/user_avatar.dart';
import '../models/mock_data.dart';
import 'add_contact_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  static const Color backgroundColor = Color(0xFF0F1E25);
  static const Color secondaryBackground = Color(0xFF162B33);
  static const Color accentColor = Color(0xFF2AABEE);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9DB2BD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: secondaryBackground,
        iconTheme: const IconThemeData(color: textPrimary),
        title: const Text(
          'Contacts',
          style: TextStyle(color: textPrimary),
        ),
        actions: const [
          Icon(Icons.search, color: textPrimary),
          SizedBox(width: 12),
          Icon(Icons.more_vert, color: textPrimary),
          SizedBox(width: 12),
        ],
      ),
      body: ListView.builder(
        itemCount: mockContacts.length,
        itemBuilder: (context, index) {
          final contact = mockContacts[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Stack(
              children: [
                UserAvatar(
                  avatarPath: contact.avatar,
                  name: contact.name,
                ),
                if (contact.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: backgroundColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
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
              style: const TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
            trailing: const Icon(
              Icons.message_outlined,
              color: accentColor,
            ),
            onTap: () {},
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddContactScreen(),
          );
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}