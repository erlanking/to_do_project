class Task {
  final int id;
  final String title;
  final bool done;

  const Task({
    required this.id,
    required this.title,
    required this.done,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      done: (json['is_done'] ?? json['done']) as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_done': done,
    };
  }

  Task copyWith({int? id, String? title, bool? done}) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
    );
  }
}
