// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
      id: json['id'] as String,
      title: json['title'] as String,
      time: json['time'] as String,
      xp: (json['xp'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isCompletable: json['isCompletable'] as bool? ?? false,
      libraryId: json['libraryId'] as String?,
    );

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'time': instance.time,
      'xp': instance.xp,
      'isCompleted': instance.isCompleted,
      'isCompletable': instance.isCompletable,
      'libraryId': instance.libraryId,
    };
