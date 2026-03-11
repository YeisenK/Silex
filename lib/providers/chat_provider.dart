import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silex/models/chat.dart';
import 'package:silex/repositories/chat_repository.dart';
import 'package:silex/repositories/mock_chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return MockChatRepository();
});

class ChatListNotifier extends AsyncNotifier<List<Chat>> {
  @override
  Future<List<Chat>> build() async {
    final repository = ref.read(chatRepositoryProvider);
    return repository.getChats();
    
  }
}

final ChatListProvider = AsyncNotifierProvider <ChatListNotifier, List<Chat>>(
  ChatListNotifier.new,
);