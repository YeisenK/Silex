import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/storage_service.dart';
import '../models/contact.dart';

class ContactsService {
  static final _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));

  static Future<Options> _authOptions() async {
    final token = await StorageService.getJwt();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// hash phone number with SHA-256
  static String hashPhone(String phoneNumber) {
    final normalized = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final bytes = utf8.encode(normalized);
    return sha256.convert(bytes).toString();
  }

  /// lookup user by phone number, returns userId if found
  static Future<String?> lookupByPhone(String phoneNumber) async {
    final hash = hashPhone(phoneNumber);
    final response = await _dio.post(
      '/users/lookup',
      data: {'phoneHash': hash},
      options: await _authOptions(),
    );
    final data = response.data as Map<String, dynamic>;
    if (data['found'] == true) {
      return data['userId'] as String;
    }
    return null;
  }

  /// save contacts list locally
  static Future<void> saveContacts(List<Contact> contacts) async {
    final json = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await StorageService.saveKey('contacts', json);
  }

  /// load contacts from local storage
  static Future<List<Contact>> loadContacts() async {
    final json = await StorageService.getKey('contacts');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => Contact.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// add a new contact and save
  static Future<void> addContact(Contact contact) async {
    final contacts = await loadContacts();
    contacts.removeWhere((c) => c.id == contact.id);
    contacts.add(contact);
    await saveContacts(contacts);
  }
}
