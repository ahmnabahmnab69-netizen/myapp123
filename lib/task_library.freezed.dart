// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_library.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TaskLibrary _$TaskLibraryFromJson(Map<String, dynamic> json) {
  return _TaskLibrary.fromJson(json);
}

/// @nodoc
mixin _$TaskLibrary {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<String> get taskIds => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TaskLibraryCopyWith<TaskLibrary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskLibraryCopyWith<$Res> {
  factory $TaskLibraryCopyWith(
          TaskLibrary value, $Res Function(TaskLibrary) then) =
      _$TaskLibraryCopyWithImpl<$Res, TaskLibrary>;
  @useResult
  $Res call({String id, String name, List<String> taskIds});
}

/// @nodoc
class _$TaskLibraryCopyWithImpl<$Res, $Val extends TaskLibrary>
    implements $TaskLibraryCopyWith<$Res> {
  _$TaskLibraryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? taskIds = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      taskIds: null == taskIds
          ? _value.taskIds
          : taskIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TaskLibraryImplCopyWith<$Res>
    implements $TaskLibraryCopyWith<$Res> {
  factory _$$TaskLibraryImplCopyWith(
          _$TaskLibraryImpl value, $Res Function(_$TaskLibraryImpl) then) =
      __$$TaskLibraryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, List<String> taskIds});
}

/// @nodoc
class __$$TaskLibraryImplCopyWithImpl<$Res>
    extends _$TaskLibraryCopyWithImpl<$Res, _$TaskLibraryImpl>
    implements _$$TaskLibraryImplCopyWith<$Res> {
  __$$TaskLibraryImplCopyWithImpl(
      _$TaskLibraryImpl _value, $Res Function(_$TaskLibraryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? taskIds = null,
  }) {
    return _then(_$TaskLibraryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      taskIds: null == taskIds
          ? _value._taskIds
          : taskIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskLibraryImpl implements _TaskLibrary {
  _$TaskLibraryImpl(
      {required this.id,
      required this.name,
      final List<String> taskIds = const []})
      : _taskIds = taskIds;

  factory _$TaskLibraryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskLibraryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final List<String> _taskIds;
  @override
  @JsonKey()
  List<String> get taskIds {
    if (_taskIds is EqualUnmodifiableListView)
      return _taskIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_taskIds);
  }

  @override
  String toString() {
    return 'TaskLibrary(id: $id, name: $name, taskIds: $taskIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskLibraryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._taskIds, _taskIds));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, const DeepCollectionEquality().hash(_taskIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskLibraryImplCopyWith<_$TaskLibraryImpl> get copyWith =>
      __$$TaskLibraryImplCopyWithImpl<_$TaskLibraryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskLibraryImplToJson(
      this,
    );
  }
}

abstract class _TaskLibrary implements TaskLibrary {
  factory _TaskLibrary(
      {required final String id,
      required final String name,
      final List<String> taskIds}) = _$TaskLibraryImpl;

  factory _TaskLibrary.fromJson(Map<String, dynamic> json) =
      _$TaskLibraryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  List<String> get taskIds;
  @override
  @JsonKey(ignore: true)
  _$$TaskLibraryImplCopyWith<_$TaskLibraryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
