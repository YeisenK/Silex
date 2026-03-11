  class Contact {
    final String id;
    final String name;
    final String avatar;
    final String phoneNumber;
    final bool isOnline;

    Contact({
      required this.id,
      required this.name,
      required this.avatar,
      required this.phoneNumber,
      this.isOnline = false,
    });

    Contact.fromJson(Map<String, dynamic> json):
      id = json['id'] as String,
      name = json['name'] as String,
      avatar = json['avatar'] as String,
      phoneNumber = json['phoneNumber'] as String,
      isOnline = json['isOnline'] as bool;

      Map<String, dynamic> toJson() {
        return{
          'id': id,
          'name': name,
          'avatar': avatar,
          'phoneNumber': phoneNumber,
          'isOnline': isOnline,
        };
      } 
  }
