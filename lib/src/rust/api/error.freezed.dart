// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MarmotError {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarmotError()';
}


}

/// @nodoc
class $MarmotErrorCopyWith<$Res>  {
$MarmotErrorCopyWith(MarmotError _, $Res Function(MarmotError) __);
}


/// Adds pattern-matching-related methods to [MarmotError].
extension MarmotErrorPatterns on MarmotError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MarmotError_NotInitialised value)?  notInitialised,TResult Function( MarmotError_NoIdentity value)?  noIdentity,TResult Function( MarmotError_InvalidNsec value)?  invalidNsec,TResult Function( MarmotError_InvalidPublicKey value)?  invalidPublicKey,TResult Function( MarmotError_InvalidRelayUrl value)?  invalidRelayUrl,TResult Function( MarmotError_InvalidEvent value)?  invalidEvent,TResult Function( MarmotError_GroupNotFound value)?  groupNotFound,TResult Function( MarmotError_WelcomeNotFound value)?  welcomeNotFound,TResult Function( MarmotError_NotAdmin value)?  notAdmin,TResult Function( MarmotError_Keyring value)?  keyring,TResult Function( MarmotError_Unsupported value)?  unsupported,TResult Function( MarmotError_Lock value)?  lock,TResult Function( MarmotError_Media value)?  media,TResult Function( MarmotError_Mdk value)?  mdk,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MarmotError_NotInitialised() when notInitialised != null:
return notInitialised(_that);case MarmotError_NoIdentity() when noIdentity != null:
return noIdentity(_that);case MarmotError_InvalidNsec() when invalidNsec != null:
return invalidNsec(_that);case MarmotError_InvalidPublicKey() when invalidPublicKey != null:
return invalidPublicKey(_that);case MarmotError_InvalidRelayUrl() when invalidRelayUrl != null:
return invalidRelayUrl(_that);case MarmotError_InvalidEvent() when invalidEvent != null:
return invalidEvent(_that);case MarmotError_GroupNotFound() when groupNotFound != null:
return groupNotFound(_that);case MarmotError_WelcomeNotFound() when welcomeNotFound != null:
return welcomeNotFound(_that);case MarmotError_NotAdmin() when notAdmin != null:
return notAdmin(_that);case MarmotError_Keyring() when keyring != null:
return keyring(_that);case MarmotError_Unsupported() when unsupported != null:
return unsupported(_that);case MarmotError_Lock() when lock != null:
return lock(_that);case MarmotError_Media() when media != null:
return media(_that);case MarmotError_Mdk() when mdk != null:
return mdk(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MarmotError_NotInitialised value)  notInitialised,required TResult Function( MarmotError_NoIdentity value)  noIdentity,required TResult Function( MarmotError_InvalidNsec value)  invalidNsec,required TResult Function( MarmotError_InvalidPublicKey value)  invalidPublicKey,required TResult Function( MarmotError_InvalidRelayUrl value)  invalidRelayUrl,required TResult Function( MarmotError_InvalidEvent value)  invalidEvent,required TResult Function( MarmotError_GroupNotFound value)  groupNotFound,required TResult Function( MarmotError_WelcomeNotFound value)  welcomeNotFound,required TResult Function( MarmotError_NotAdmin value)  notAdmin,required TResult Function( MarmotError_Keyring value)  keyring,required TResult Function( MarmotError_Unsupported value)  unsupported,required TResult Function( MarmotError_Lock value)  lock,required TResult Function( MarmotError_Media value)  media,required TResult Function( MarmotError_Mdk value)  mdk,}){
final _that = this;
switch (_that) {
case MarmotError_NotInitialised():
return notInitialised(_that);case MarmotError_NoIdentity():
return noIdentity(_that);case MarmotError_InvalidNsec():
return invalidNsec(_that);case MarmotError_InvalidPublicKey():
return invalidPublicKey(_that);case MarmotError_InvalidRelayUrl():
return invalidRelayUrl(_that);case MarmotError_InvalidEvent():
return invalidEvent(_that);case MarmotError_GroupNotFound():
return groupNotFound(_that);case MarmotError_WelcomeNotFound():
return welcomeNotFound(_that);case MarmotError_NotAdmin():
return notAdmin(_that);case MarmotError_Keyring():
return keyring(_that);case MarmotError_Unsupported():
return unsupported(_that);case MarmotError_Lock():
return lock(_that);case MarmotError_Media():
return media(_that);case MarmotError_Mdk():
return mdk(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MarmotError_NotInitialised value)?  notInitialised,TResult? Function( MarmotError_NoIdentity value)?  noIdentity,TResult? Function( MarmotError_InvalidNsec value)?  invalidNsec,TResult? Function( MarmotError_InvalidPublicKey value)?  invalidPublicKey,TResult? Function( MarmotError_InvalidRelayUrl value)?  invalidRelayUrl,TResult? Function( MarmotError_InvalidEvent value)?  invalidEvent,TResult? Function( MarmotError_GroupNotFound value)?  groupNotFound,TResult? Function( MarmotError_WelcomeNotFound value)?  welcomeNotFound,TResult? Function( MarmotError_NotAdmin value)?  notAdmin,TResult? Function( MarmotError_Keyring value)?  keyring,TResult? Function( MarmotError_Unsupported value)?  unsupported,TResult? Function( MarmotError_Lock value)?  lock,TResult? Function( MarmotError_Media value)?  media,TResult? Function( MarmotError_Mdk value)?  mdk,}){
final _that = this;
switch (_that) {
case MarmotError_NotInitialised() when notInitialised != null:
return notInitialised(_that);case MarmotError_NoIdentity() when noIdentity != null:
return noIdentity(_that);case MarmotError_InvalidNsec() when invalidNsec != null:
return invalidNsec(_that);case MarmotError_InvalidPublicKey() when invalidPublicKey != null:
return invalidPublicKey(_that);case MarmotError_InvalidRelayUrl() when invalidRelayUrl != null:
return invalidRelayUrl(_that);case MarmotError_InvalidEvent() when invalidEvent != null:
return invalidEvent(_that);case MarmotError_GroupNotFound() when groupNotFound != null:
return groupNotFound(_that);case MarmotError_WelcomeNotFound() when welcomeNotFound != null:
return welcomeNotFound(_that);case MarmotError_NotAdmin() when notAdmin != null:
return notAdmin(_that);case MarmotError_Keyring() when keyring != null:
return keyring(_that);case MarmotError_Unsupported() when unsupported != null:
return unsupported(_that);case MarmotError_Lock() when lock != null:
return lock(_that);case MarmotError_Media() when media != null:
return media(_that);case MarmotError_Mdk() when mdk != null:
return mdk(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  notInitialised,TResult Function()?  noIdentity,TResult Function()?  invalidNsec,TResult Function()?  invalidPublicKey,TResult Function( String field0)?  invalidRelayUrl,TResult Function( String field0)?  invalidEvent,TResult Function()?  groupNotFound,TResult Function()?  welcomeNotFound,TResult Function()?  notAdmin,TResult Function( String field0)?  keyring,TResult Function( String field0)?  unsupported,TResult Function()?  lock,TResult Function( String field0)?  media,TResult Function( String field0)?  mdk,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MarmotError_NotInitialised() when notInitialised != null:
return notInitialised();case MarmotError_NoIdentity() when noIdentity != null:
return noIdentity();case MarmotError_InvalidNsec() when invalidNsec != null:
return invalidNsec();case MarmotError_InvalidPublicKey() when invalidPublicKey != null:
return invalidPublicKey();case MarmotError_InvalidRelayUrl() when invalidRelayUrl != null:
return invalidRelayUrl(_that.field0);case MarmotError_InvalidEvent() when invalidEvent != null:
return invalidEvent(_that.field0);case MarmotError_GroupNotFound() when groupNotFound != null:
return groupNotFound();case MarmotError_WelcomeNotFound() when welcomeNotFound != null:
return welcomeNotFound();case MarmotError_NotAdmin() when notAdmin != null:
return notAdmin();case MarmotError_Keyring() when keyring != null:
return keyring(_that.field0);case MarmotError_Unsupported() when unsupported != null:
return unsupported(_that.field0);case MarmotError_Lock() when lock != null:
return lock();case MarmotError_Media() when media != null:
return media(_that.field0);case MarmotError_Mdk() when mdk != null:
return mdk(_that.field0);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  notInitialised,required TResult Function()  noIdentity,required TResult Function()  invalidNsec,required TResult Function()  invalidPublicKey,required TResult Function( String field0)  invalidRelayUrl,required TResult Function( String field0)  invalidEvent,required TResult Function()  groupNotFound,required TResult Function()  welcomeNotFound,required TResult Function()  notAdmin,required TResult Function( String field0)  keyring,required TResult Function( String field0)  unsupported,required TResult Function()  lock,required TResult Function( String field0)  media,required TResult Function( String field0)  mdk,}) {final _that = this;
switch (_that) {
case MarmotError_NotInitialised():
return notInitialised();case MarmotError_NoIdentity():
return noIdentity();case MarmotError_InvalidNsec():
return invalidNsec();case MarmotError_InvalidPublicKey():
return invalidPublicKey();case MarmotError_InvalidRelayUrl():
return invalidRelayUrl(_that.field0);case MarmotError_InvalidEvent():
return invalidEvent(_that.field0);case MarmotError_GroupNotFound():
return groupNotFound();case MarmotError_WelcomeNotFound():
return welcomeNotFound();case MarmotError_NotAdmin():
return notAdmin();case MarmotError_Keyring():
return keyring(_that.field0);case MarmotError_Unsupported():
return unsupported(_that.field0);case MarmotError_Lock():
return lock();case MarmotError_Media():
return media(_that.field0);case MarmotError_Mdk():
return mdk(_that.field0);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  notInitialised,TResult? Function()?  noIdentity,TResult? Function()?  invalidNsec,TResult? Function()?  invalidPublicKey,TResult? Function( String field0)?  invalidRelayUrl,TResult? Function( String field0)?  invalidEvent,TResult? Function()?  groupNotFound,TResult? Function()?  welcomeNotFound,TResult? Function()?  notAdmin,TResult? Function( String field0)?  keyring,TResult? Function( String field0)?  unsupported,TResult? Function()?  lock,TResult? Function( String field0)?  media,TResult? Function( String field0)?  mdk,}) {final _that = this;
switch (_that) {
case MarmotError_NotInitialised() when notInitialised != null:
return notInitialised();case MarmotError_NoIdentity() when noIdentity != null:
return noIdentity();case MarmotError_InvalidNsec() when invalidNsec != null:
return invalidNsec();case MarmotError_InvalidPublicKey() when invalidPublicKey != null:
return invalidPublicKey();case MarmotError_InvalidRelayUrl() when invalidRelayUrl != null:
return invalidRelayUrl(_that.field0);case MarmotError_InvalidEvent() when invalidEvent != null:
return invalidEvent(_that.field0);case MarmotError_GroupNotFound() when groupNotFound != null:
return groupNotFound();case MarmotError_WelcomeNotFound() when welcomeNotFound != null:
return welcomeNotFound();case MarmotError_NotAdmin() when notAdmin != null:
return notAdmin();case MarmotError_Keyring() when keyring != null:
return keyring(_that.field0);case MarmotError_Unsupported() when unsupported != null:
return unsupported(_that.field0);case MarmotError_Lock() when lock != null:
return lock();case MarmotError_Media() when media != null:
return media(_that.field0);case MarmotError_Mdk() when mdk != null:
return mdk(_that.field0);case _:
  return null;

}
}

}

/// @nodoc


class MarmotError_NotInitialised extends MarmotError {
  const MarmotError_NotInitialised(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_NotInitialised);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarmotError.notInitialised()';
}


}




/// @nodoc


class MarmotError_NoIdentity extends MarmotError {
  const MarmotError_NoIdentity(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_NoIdentity);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarmotError.noIdentity()';
}


}




/// @nodoc


class MarmotError_InvalidNsec extends MarmotError {
  const MarmotError_InvalidNsec(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_InvalidNsec);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarmotError.invalidNsec()';
}


}




/// @nodoc


class MarmotError_InvalidPublicKey extends MarmotError {
  const MarmotError_InvalidPublicKey(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_InvalidPublicKey);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarmotError.invalidPublicKey()';
}


}




/// @nodoc


class MarmotError_InvalidRelayUrl extends MarmotError {
  const MarmotError_InvalidRelayUrl(this.field0): super._();
  

 final  String field0;

/// Create a copy of MarmotError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarmotError_InvalidRelayUrlCopyWith<MarmotError_InvalidRelayUrl> get copyWith => _$MarmotError_InvalidRelayUrlCopyWithImpl<MarmotError_InvalidRelayUrl>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_InvalidRelayUrl&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'MarmotError.invalidRelayUrl(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $MarmotError_InvalidRelayUrlCopyWith<$Res> implements $MarmotErrorCopyWith<$Res> {
  factory $MarmotError_InvalidRelayUrlCopyWith(MarmotError_InvalidRelayUrl value, $Res Function(MarmotError_InvalidRelayUrl) _then) = _$MarmotError_InvalidRelayUrlCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$MarmotError_InvalidRelayUrlCopyWithImpl<$Res>
    implements $MarmotError_InvalidRelayUrlCopyWith<$Res> {
  _$MarmotError_InvalidRelayUrlCopyWithImpl(this._self, this._then);

  final MarmotError_InvalidRelayUrl _self;
  final $Res Function(MarmotError_InvalidRelayUrl) _then;

/// Create a copy of MarmotError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(MarmotError_InvalidRelayUrl(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MarmotError_InvalidEvent extends MarmotError {
  const MarmotError_InvalidEvent(this.field0): super._();
  

 final  String field0;

/// Create a copy of MarmotError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarmotError_InvalidEventCopyWith<MarmotError_InvalidEvent> get copyWith => _$MarmotError_InvalidEventCopyWithImpl<MarmotError_InvalidEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_InvalidEvent&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'MarmotError.invalidEvent(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $MarmotError_InvalidEventCopyWith<$Res> implements $MarmotErrorCopyWith<$Res> {
  factory $MarmotError_InvalidEventCopyWith(MarmotError_InvalidEvent value, $Res Function(MarmotError_InvalidEvent) _then) = _$MarmotError_InvalidEventCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$MarmotError_InvalidEventCopyWithImpl<$Res>
    implements $MarmotError_InvalidEventCopyWith<$Res> {
  _$MarmotError_InvalidEventCopyWithImpl(this._self, this._then);

  final MarmotError_InvalidEvent _self;
  final $Res Function(MarmotError_InvalidEvent) _then;

/// Create a copy of MarmotError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(MarmotError_InvalidEvent(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MarmotError_GroupNotFound extends MarmotError {
  const MarmotError_GroupNotFound(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_GroupNotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarmotError.groupNotFound()';
}


}




/// @nodoc


class MarmotError_WelcomeNotFound extends MarmotError {
  const MarmotError_WelcomeNotFound(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_WelcomeNotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarmotError.welcomeNotFound()';
}


}




/// @nodoc


class MarmotError_NotAdmin extends MarmotError {
  const MarmotError_NotAdmin(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_NotAdmin);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarmotError.notAdmin()';
}


}




/// @nodoc


class MarmotError_Keyring extends MarmotError {
  const MarmotError_Keyring(this.field0): super._();
  

 final  String field0;

/// Create a copy of MarmotError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarmotError_KeyringCopyWith<MarmotError_Keyring> get copyWith => _$MarmotError_KeyringCopyWithImpl<MarmotError_Keyring>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_Keyring&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'MarmotError.keyring(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $MarmotError_KeyringCopyWith<$Res> implements $MarmotErrorCopyWith<$Res> {
  factory $MarmotError_KeyringCopyWith(MarmotError_Keyring value, $Res Function(MarmotError_Keyring) _then) = _$MarmotError_KeyringCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$MarmotError_KeyringCopyWithImpl<$Res>
    implements $MarmotError_KeyringCopyWith<$Res> {
  _$MarmotError_KeyringCopyWithImpl(this._self, this._then);

  final MarmotError_Keyring _self;
  final $Res Function(MarmotError_Keyring) _then;

/// Create a copy of MarmotError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(MarmotError_Keyring(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MarmotError_Unsupported extends MarmotError {
  const MarmotError_Unsupported(this.field0): super._();
  

 final  String field0;

/// Create a copy of MarmotError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarmotError_UnsupportedCopyWith<MarmotError_Unsupported> get copyWith => _$MarmotError_UnsupportedCopyWithImpl<MarmotError_Unsupported>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_Unsupported&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'MarmotError.unsupported(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $MarmotError_UnsupportedCopyWith<$Res> implements $MarmotErrorCopyWith<$Res> {
  factory $MarmotError_UnsupportedCopyWith(MarmotError_Unsupported value, $Res Function(MarmotError_Unsupported) _then) = _$MarmotError_UnsupportedCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$MarmotError_UnsupportedCopyWithImpl<$Res>
    implements $MarmotError_UnsupportedCopyWith<$Res> {
  _$MarmotError_UnsupportedCopyWithImpl(this._self, this._then);

  final MarmotError_Unsupported _self;
  final $Res Function(MarmotError_Unsupported) _then;

/// Create a copy of MarmotError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(MarmotError_Unsupported(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MarmotError_Lock extends MarmotError {
  const MarmotError_Lock(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_Lock);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MarmotError.lock()';
}


}




/// @nodoc


class MarmotError_Media extends MarmotError {
  const MarmotError_Media(this.field0): super._();
  

 final  String field0;

/// Create a copy of MarmotError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarmotError_MediaCopyWith<MarmotError_Media> get copyWith => _$MarmotError_MediaCopyWithImpl<MarmotError_Media>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_Media&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'MarmotError.media(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $MarmotError_MediaCopyWith<$Res> implements $MarmotErrorCopyWith<$Res> {
  factory $MarmotError_MediaCopyWith(MarmotError_Media value, $Res Function(MarmotError_Media) _then) = _$MarmotError_MediaCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$MarmotError_MediaCopyWithImpl<$Res>
    implements $MarmotError_MediaCopyWith<$Res> {
  _$MarmotError_MediaCopyWithImpl(this._self, this._then);

  final MarmotError_Media _self;
  final $Res Function(MarmotError_Media) _then;

/// Create a copy of MarmotError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(MarmotError_Media(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MarmotError_Mdk extends MarmotError {
  const MarmotError_Mdk(this.field0): super._();
  

 final  String field0;

/// Create a copy of MarmotError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarmotError_MdkCopyWith<MarmotError_Mdk> get copyWith => _$MarmotError_MdkCopyWithImpl<MarmotError_Mdk>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarmotError_Mdk&&(identical(other.field0, field0) || other.field0 == field0));
}


@override
int get hashCode => Object.hash(runtimeType,field0);

@override
String toString() {
  return 'MarmotError.mdk(field0: $field0)';
}


}

/// @nodoc
abstract mixin class $MarmotError_MdkCopyWith<$Res> implements $MarmotErrorCopyWith<$Res> {
  factory $MarmotError_MdkCopyWith(MarmotError_Mdk value, $Res Function(MarmotError_Mdk) _then) = _$MarmotError_MdkCopyWithImpl;
@useResult
$Res call({
 String field0
});




}
/// @nodoc
class _$MarmotError_MdkCopyWithImpl<$Res>
    implements $MarmotError_MdkCopyWith<$Res> {
  _$MarmotError_MdkCopyWithImpl(this._self, this._then);

  final MarmotError_Mdk _self;
  final $Res Function(MarmotError_Mdk) _then;

/// Create a copy of MarmotError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? field0 = null,}) {
  return _then(MarmotError_Mdk(
null == field0 ? _self.field0 : field0 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
