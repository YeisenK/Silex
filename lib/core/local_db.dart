import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDb {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'silex_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            chat_id TEXT NOT NULL,
            text TEXT NOT NULL,
            time TEXT NOT NULL,
            is_sent_by_me INTEGER NOT NULL,
            timestamp INTEGER NOT NULL,
            message_type TEXT NOT NULL DEFAULT 'text'
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_messages_chat_id ON messages(chat_id)
        ''');

        await db.execute('''
          CREATE INDEX idx_messages_timestamp ON messages(timestamp)
        ''');
      },
    );
  }

  /// Insert a message
  static Future<void> insertMessage({
    required String id,
    required String chatId,
    required String text,
    required String time,
    required bool isSentByMe,
    required DateTime timestamp,
    String messageType = 'text',
  }) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'id': id,
        'chat_id': chatId,
        'text': text,
        'time': time,
        'is_sent_by_me': isSentByMe ? 1 : 0,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'message_type': messageType,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Get all messages for a chat, ordered by timestamp
  static Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
  }

  /// Get all chat IDs that have messages, with the latest message for each
  static Future<List<Map<String, dynamic>>> getChatPreviews() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        m.chat_id,
        m.text AS last_message,
        m.time AS last_time,
        m.timestamp AS last_timestamp,
        m.is_sent_by_me,
        (SELECT COUNT(*) FROM messages m2 
         WHERE m2.chat_id = m.chat_id AND m2.is_sent_by_me = 0) AS total_incoming
      FROM messages m
      INNER JOIN (
        SELECT chat_id, MAX(timestamp) AS max_ts
        FROM messages
        GROUP BY chat_id
      ) latest ON m.chat_id = latest.chat_id AND m.timestamp = latest.max_ts
      ORDER BY m.timestamp DESC
    ''');
  }

  /// Delete all messages for a chat
  static Future<void> deleteChat(String chatId) async {
    final db = await database;
    await db.delete('messages', where: 'chat_id = ?', whereArgs: [chatId]);
  }

  /// Delete all messages
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('messages');
  }
}
