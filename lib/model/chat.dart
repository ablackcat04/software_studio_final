class Chat {
  Chat({
    required this.messages,
    required this.activateFolder,
    this.uploaded = false,
    this.active = false,
  });

  List<ChatMessage> messages;
  Map<String, bool> activateFolder = {'Favorite': true, 'Mygo': true};
  bool uploaded;
  bool active;

  factory Chat.fromMap(Map<dynamic, dynamic> map) => Chat(
    messages:
        map['messages'] != null
            ? List<ChatMessage>.from(
              (map['messages'] as List).map(
                (message) => ChatMessage.fromMap(message),
              ),
            )
            : [],
    uploaded: map['uploaded'] ?? false,
    active: map['active'] ?? false,
    activateFolder: {
      'Favorite':
          map['activateFolder'] != null &&
                  map['activateFolder']['Favorite'] != null
              ? map['activateFolder']['Favorite']
              : true,
      'Mygo':
          map['activateFolder'] != null && map['activateFolder']['Mygo'] != null
              ? map['activateFolder']['Mygo']
              : true,
    },
  );

  Map<String, dynamic> toMap() => {
    'messages': messages.map((message) => message.toMap()).toList(),
    'uploaded': uploaded,
    'active': active,
    'activateFolder': {
      'Favorite': activateFolder['Favorite'] ?? true,
      'Mygo': activateFolder['Mygo'] ?? true,
    },
  };
}

class ChatMessage {
  ChatMessage({
    required this.isAI,
    required this.content,
    this.images = const [],
  });

  bool isAI;
  String content;
  List<String> images;

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) => ChatMessage(
    isAI: map['isAI'],
    content: map['content'],
    images: List<String>.from(map['images']),
  );
  Map<String, dynamic> toMap() => {
    'isAI': isAI,
    'content': content,
    'images': images,
  };
}

class ChatMeta {
  final String id;
  final String name;
  final DateTime createdAt;

  ChatMeta({required this.id, required this.name, required this.createdAt});

  factory ChatMeta.fromMap(Map<dynamic, dynamic> map) => ChatMeta(
    id: map['id'],
    name: map['name'],
    createdAt: DateTime.parse(map['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };
}
