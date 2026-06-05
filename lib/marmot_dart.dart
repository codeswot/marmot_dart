library;

export 'src/marmot.dart';
export 'src/identity.dart';

// Pure functions (no dbPath needed)
export 'src/key_packages.dart' show signEvent;
export 'src/messages.dart' show buildUnsignedRumor;

// Models & config
export 'src/rust/state.dart' show StorageConfig;
export 'src/rust/api/identity.dart' show NostrKeypair;
export 'src/rust/api/key_packages.dart' show KeyPackageEventData;
export 'src/rust/api/groups.dart'
    show
      CreateGroupParams,
      GroupCreateResult,
      MarmotGroup,
      MarmotMember,
      PendingWelcome,
      MemberChangeResult,
      GroupMetadataUpdate,
      GroupImagePrepared;
export 'src/rust/api/messages.dart' show MarmotMessage, MarmotMediaRef;
export 'src/rust/api/media.dart' show EncryptedMediaOutput, MediaRefInput;
export 'src/rust/api/error.dart' show MarmotError;
