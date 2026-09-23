import 'package:json_annotation/json_annotation.dart';

part 'task_library.g.dart';

@JsonSerializable()
class TaskLibrary {
  final String id;
  final String name;

  TaskLibrary({required this.id, required this.name});

  factory TaskLibrary.fromJson(Map<String, dynamic> json) =>
      _$TaskLibraryFromJson(json);

  Map<String, dynamic> toJson() => _$TaskLibraryToJson(this);
}
