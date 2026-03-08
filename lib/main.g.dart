// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
  title: json['title'] as String,
  time: json['time'] as String,
  xp: (json['xp'] as num).toInt(),
  isCompleted: json['isCompleted'] as bool? ?? false,
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'title': instance.title,
  'time': instance.time,
  'xp': instance.xp,
  'isCompleted': instance.isCompleted,
};
