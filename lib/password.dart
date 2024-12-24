class Password {
  int? id;
  String title;
  String account;
  String password;
  String comment;
  DateTime createdAt;
  DateTime updatedAt;

  Password({
    this.id,
    required this.title,
    required this.account,
    required this.password,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'account': account,
      'password': password,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Password.fromMap(Map<String, dynamic> map) {
    return Password(
      id: map['id'],
      title: map['title'],
      account: map['account'],
      password: map['password'],
      comment: map['comment'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
