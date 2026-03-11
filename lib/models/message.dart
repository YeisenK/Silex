  class Message {
    final String id;
    final String text;
    final String time;
    final bool isSentByMe;
    final MessageType type;
    final String? imageUrl;
    final String? linkTitle;
    final String? linkSubtitle;
    final String? linkUrl;

    Message({
      required this.id,
      required this.text,
      required this.time,
      required this.isSentByMe,
      this.type = MessageType.text,
      this.imageUrl,
      this.linkTitle,
      this.linkSubtitle,
      this.linkUrl,
    });


    Message.fromJson(Map<String, dynamic> json): 
      id = json['id'] as String,
      text = json['text'] as String,
      time = json['time'] as String,
      isSentByMe = json['isSentByMe'] as bool,
      type = MessageType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'text'),
        orElse: () => MessageType.text,
      ),
      imageUrl = json['imageUrl'] as String?,
      linkTitle = json['linkTitle'] as String?,
      linkSubtitle = json['linkSubtitle'] as String?,
      linkUrl = json['linkUrl'] as String?;


    Map<String, dynamic> toJson(){
      return{
        'id': id,
        'text': text,
        'time': time,
        'isSentByMe': isSentByMe,
        'imageUrl': imageUrl,
        'linkTitle': linkTitle,
        'linkSubtitle': linkSubtitle,
        'linkUrl': linkUrl,
      };
    }
  
  }
  enum MessageType {
    text,
    image,
    video,
    link,
  }


