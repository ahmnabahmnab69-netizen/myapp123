// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_library.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskLibraryImpl _$$TaskLibraryImplFromJson(Map<String, dynamic> json) =>
    _$TaskLibraryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      taskIds: (json['taskIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
    );

Map<String, dynamic> _$$TaskLibraryImplToJson(_$TaskLibraryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'taskIds': instance.taskIds,
    };
