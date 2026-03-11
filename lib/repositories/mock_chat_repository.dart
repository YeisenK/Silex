import 'package:silex/models/chat.dart';
import 'package:silex/models/message.dart';
import 'package:silex/repositories/chat_repository.dart';
import '../data/mock_data.dart';

class MockChatRepository implements ChatRepository{

  @override
  Future<List<Chat>> getChats() async {
    return mockChats;
  }

  @override
  Future<Chat?> getChatById(String id) async {
    try {
      return mockChats.firstWhere((chat) => chat.id == id);
    } catch (e){
      return null;
    }
  }

  @override
  Future<List<Message>> getMessagesForChat(String chatId) async {
    try {
      final chat = mockChats.firstWhere((chat) => chat.id == chatId);
      return chat.messages;
    } catch (e){
      return [];
    }
    
  }
}