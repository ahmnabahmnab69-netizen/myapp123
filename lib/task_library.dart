import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_library.freezed.dart';
part 'task_library.g.dart';

@freezed
class TaskLibrary with _$TaskLibrary {
  factory TaskLibrary({
    required String id,
    required String name,
    @Default([]) List<String> taskIds,
  }) = _TaskLibrary;

  factory TaskLibrary.fromJson(Map<String, dynamic> json) =>
      _$TaskLibraryFromJson(json);
}
