import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  final String id;
  final String title;
  final String time;
  final int xp;
  bool isCompleted;
  bool isCompletable;
  String? libraryId;

  Task({
    required this.id,
    required this.title,
    required this.time,
    required this.xp,
    this.isCompleted = false,
    this.isCompletable = false,
    this.libraryId,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}
