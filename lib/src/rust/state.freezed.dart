// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StorageConfig {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageConfig);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StorageConfig()';
}


}

/// @nodoc
class $StorageConfigCopyWith<$Res>  {
$StorageConfigCopyWith(StorageConfig _, $Res Function(StorageConfig) __);
}


/// Adds pattern-matching-related methods to [StorageConfig].
extension StorageConfigPatterns on StorageConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StorageConfig_Memory value)?  memory,TResult Function( StorageConfig_Sqlite value)?  sqlite,TResult Function( StorageConfig_SqliteWithKey value)?  sqliteWithKey,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StorageConfig_Memory() when memory != null:
return memory(_that);case StorageConfig_Sqlite() when sqlite != null:
return sqlite(_that);case StorageConfig_SqliteWithKey() when sqliteWithKey != null:
return sqliteWithKey(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StorageConfig_Memory value)  memory,required TResult Function( StorageConfig_Sqlite value)  sqlite,required TResult Function( StorageConfig_SqliteWithKey value)  sqliteWithKey,}){
final _that = this;
switch (_that) {
case StorageConfig_Memory():
return memory(_that);case StorageConfig_Sqlite():
return sqlite(_that);case StorageConfig_SqliteWithKey():
return sqliteWithKey(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StorageConfig_Memory value)?  memory,TResult? Function( StorageConfig_Sqlite value)?  sqlite,TResult? Function( StorageConfig_SqliteWithKey value)?  sqliteWithKey,}){
final _that = this;
switch (_that) {
case StorageConfig_Memory() when memory != null:
return memory(_that);case StorageConfig_Sqlite() when sqlite != null:
return sqlite(_that);case StorageConfig_SqliteWithKey() when sqliteWithKey != null:
return sqliteWithKey(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  memory,TResult Function( String dbPath,  String serviceId,  String keyId)?  sqlite,TResult Function( String dbPath,  Uint8List dbKey)?  sqliteWithKey,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StorageConfig_Memory() when memory != null:
return memory();case StorageConfig_Sqlite() when sqlite != null:
return sqlite(_that.dbPath,_that.serviceId,_that.keyId);case StorageConfig_SqliteWithKey() when sqliteWithKey != null:
return sqliteWithKey(_that.dbPath,_that.dbKey);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  memory,required TResult Function( String dbPath,  String serviceId,  String keyId)  sqlite,required TResult Function( String dbPath,  Uint8List dbKey)  sqliteWithKey,}) {final _that = this;
switch (_that) {
case StorageConfig_Memory():
return memory();case StorageConfig_Sqlite():
return sqlite(_that.dbPath,_that.serviceId,_that.keyId);case StorageConfig_SqliteWithKey():
return sqliteWithKey(_that.dbPath,_that.dbKey);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  memory,TResult? Function( String dbPath,  String serviceId,  String keyId)?  sqlite,TResult? Function( String dbPath,  Uint8List dbKey)?  sqliteWithKey,}) {final _that = this;
switch (_that) {
case StorageConfig_Memory() when memory != null:
return memory();case StorageConfig_Sqlite() when sqlite != null:
return sqlite(_that.dbPath,_that.serviceId,_that.keyId);case StorageConfig_SqliteWithKey() when sqliteWithKey != null:
return sqliteWithKey(_that.dbPath,_that.dbKey);case _:
  return null;

}
}

}

/// @nodoc


class StorageConfig_Memory extends StorageConfig {
  const StorageConfig_Memory(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageConfig_Memory);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StorageConfig.memory()';
}


}




/// @nodoc


class StorageConfig_Sqlite extends StorageConfig {
  const StorageConfig_Sqlite({required this.dbPath, required this.serviceId, required this.keyId}): super._();
  

 final  String dbPath;
 final  String serviceId;
 final  String keyId;

/// Create a copy of StorageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorageConfig_SqliteCopyWith<StorageConfig_Sqlite> get copyWith => _$StorageConfig_SqliteCopyWithImpl<StorageConfig_Sqlite>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageConfig_Sqlite&&(identical(other.dbPath, dbPath) || other.dbPath == dbPath)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.keyId, keyId) || other.keyId == keyId));
}


@override
int get hashCode => Object.hash(runtimeType,dbPath,serviceId,keyId);

@override
String toString() {
  return 'StorageConfig.sqlite(dbPath: $dbPath, serviceId: $serviceId, keyId: $keyId)';
}


}

/// @nodoc
abstract mixin class $StorageConfig_SqliteCopyWith<$Res> implements $StorageConfigCopyWith<$Res> {
  factory $StorageConfig_SqliteCopyWith(StorageConfig_Sqlite value, $Res Function(StorageConfig_Sqlite) _then) = _$StorageConfig_SqliteCopyWithImpl;
@useResult
$Res call({
 String dbPath, String serviceId, String keyId
});




}
/// @nodoc
class _$StorageConfig_SqliteCopyWithImpl<$Res>
    implements $StorageConfig_SqliteCopyWith<$Res> {
  _$StorageConfig_SqliteCopyWithImpl(this._self, this._then);

  final StorageConfig_Sqlite _self;
  final $Res Function(StorageConfig_Sqlite) _then;

/// Create a copy of StorageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dbPath = null,Object? serviceId = null,Object? keyId = null,}) {
  return _then(StorageConfig_Sqlite(
dbPath: null == dbPath ? _self.dbPath : dbPath // ignore: cast_nullable_to_non_nullable
as String,serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String,keyId: null == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class StorageConfig_SqliteWithKey extends StorageConfig {
  const StorageConfig_SqliteWithKey({required this.dbPath, required this.dbKey}): super._();
  

 final  String dbPath;
 final  Uint8List dbKey;

/// Create a copy of StorageConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StorageConfig_SqliteWithKeyCopyWith<StorageConfig_SqliteWithKey> get copyWith => _$StorageConfig_SqliteWithKeyCopyWithImpl<StorageConfig_SqliteWithKey>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StorageConfig_SqliteWithKey&&(identical(other.dbPath, dbPath) || other.dbPath == dbPath)&&const DeepCollectionEquality().equals(other.dbKey, dbKey));
}


@override
int get hashCode => Object.hash(runtimeType,dbPath,const DeepCollectionEquality().hash(dbKey));

@override
String toString() {
  return 'StorageConfig.sqliteWithKey(dbPath: $dbPath, dbKey: $dbKey)';
}


}

/// @nodoc
abstract mixin class $StorageConfig_SqliteWithKeyCopyWith<$Res> implements $StorageConfigCopyWith<$Res> {
  factory $StorageConfig_SqliteWithKeyCopyWith(StorageConfig_SqliteWithKey value, $Res Function(StorageConfig_SqliteWithKey) _then) = _$StorageConfig_SqliteWithKeyCopyWithImpl;
@useResult
$Res call({
 String dbPath, Uint8List dbKey
});




}
/// @nodoc
class _$StorageConfig_SqliteWithKeyCopyWithImpl<$Res>
    implements $StorageConfig_SqliteWithKeyCopyWith<$Res> {
  _$StorageConfig_SqliteWithKeyCopyWithImpl(this._self, this._then);

  final StorageConfig_SqliteWithKey _self;
  final $Res Function(StorageConfig_SqliteWithKey) _then;

/// Create a copy of StorageConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dbPath = null,Object? dbKey = null,}) {
  return _then(StorageConfig_SqliteWithKey(
dbPath: null == dbPath ? _self.dbPath : dbPath // ignore: cast_nullable_to_non_nullable
as String,dbKey: null == dbKey ? _self.dbKey : dbKey // ignore: cast_nullable_to_non_nullable
as Uint8List,
  ));
}


}

// dart format on
