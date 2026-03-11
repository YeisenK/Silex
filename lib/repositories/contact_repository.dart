import '../models/contact.dart';  

abstract class ContactRepository {

  Future<List<Contact>> getContacts();
  Future<Contact?> getContactById(String id);
  Future<List<Contact>> searchContacts(String query);

}