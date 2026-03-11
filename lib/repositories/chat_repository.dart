import '../models/chat.dart';
import '../models/message.dart';

abstract class ChatRepository {

  Future<List<Chat>> getChats();
  Future<Chat?> getChatById(String id);
  Future<List<Message>> getMessagesForChat(String chatId);

}