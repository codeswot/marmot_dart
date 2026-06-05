import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:marmot_dart/marmot_dart.dart';

Uint8List ub(List<int> values) => Uint8List.fromList(values);

void main() {
  // ── CreateGroupParams ────────────────────────────────────────────────────

  group('CreateGroupParams', () {
    test('holds required fields', () {
      const params = CreateGroupParams(
        name: 'Team',
        description: 'A team',
        relayUrls: ['wss://r.example.com'],
        memberKeyPackageEventJsons: ['{}'],
      );
      expect(params.name, 'Team');
      expect(params.description, 'A team');
      expect(params.relayUrls, ['wss://r.example.com']);
      expect(params.memberKeyPackageEventJsons, ['{}']);
    });

    test('supports empty relayUrls', () {
      const params = CreateGroupParams(
        name: 'G',
        description: '',
        relayUrls: [],
        memberKeyPackageEventJsons: [],
      );
      expect(params.relayUrls, isEmpty);
      expect(params.memberKeyPackageEventJsons, isEmpty);
    });
  });

  // ── NostrKeypair ─────────────────────────────────────────────────────────

  group('NostrKeypair', () {
    test('holds all fields when nsec is present', () {
      const kp = NostrKeypair(
        npub: 'npub1abc',
        nsec: 'nsec1xyz',
        pubkeyHex: 'deadbeef',
      );
      expect(kp.npub, 'npub1abc');
      expect(kp.nsec, 'nsec1xyz');
      expect(kp.pubkeyHex, 'deadbeef');
    });

    test('nsec is nullable', () {
      const kp = NostrKeypair(npub: 'npub1abc', nsec: null, pubkeyHex: 'ff');
      expect(kp.nsec, isNull);
    });
  });

  // ── KeyPackageEventData ──────────────────────────────────────────────────

  group('KeyPackageEventData', () {
    test('holds all fields', () {
      final kp = KeyPackageEventData(
        content: 'base64...',
        tags30443: [
          ['d', 'abc'],
          ['relay', 'wss://r'],
        ],
        tags443: [
          ['d', 'abc'],
        ],
        dTag: 'abc',
        hashRef: ub([1, 2, 3]),
      );
      expect(kp.content, 'base64...');
      expect(kp.tags30443, hasLength(2));
      expect(kp.tags443, hasLength(1));
      expect(kp.dTag, 'abc');
      expect(kp.hashRef, ub([1, 2, 3]));
    });
  });

  // ── GroupCreateResult ────────────────────────────────────────────────────

  group('GroupCreateResult', () {
    test('holds group and welcomeRumors', () {
      final group = MarmotGroup(
        id: 'g1',
        nostrGroupId: 'ng1',
        name: 'Test',
        description: '',
        relayUrls: [],
        adminNpubs: [],
        memberCount: 2,
      );
      final result = GroupCreateResult(group: group, welcomeRumors: ['r1']);
      expect(result.group.name, 'Test');
      expect(result.welcomeRumors, ['r1']);
    });
  });

  // ── MarmotGroup ──────────────────────────────────────────────────────────

  group('MarmotGroup', () {
    test('holds required fields', () {
      final g = MarmotGroup(
        id: 'id1',
        nostrGroupId: 'nostr1',
        name: 'Group',
        description: 'desc',
        relayUrls: ['wss://r'],
        adminNpubs: ['npub1admin'],
        memberCount: 5,
      );
      expect(g.id, 'id1');
      expect(g.nostrGroupId, 'nostr1');
      expect(g.name, 'Group');
      expect(g.description, 'desc');
      expect(g.relayUrls, ['wss://r']);
      expect(g.adminNpubs, ['npub1admin']);
      expect(g.memberCount, 5);
    });

    test('image fields default to null', () {
      final g = MarmotGroup(
        id: 'id1',
        nostrGroupId: 'ng1',
        name: 'G',
        description: '',
        relayUrls: [],
        adminNpubs: [],
        memberCount: 1,
      );
      expect(g.imageHash, isNull);
      expect(g.imageKey, isNull);
      expect(g.imageNonce, isNull);
    });

    test('image fields accept values', () {
      final g = MarmotGroup(
        id: 'id1',
        nostrGroupId: 'ng1',
        name: 'G',
        description: '',
        relayUrls: [],
        adminNpubs: [],
        memberCount: 1,
        imageHash: ub([1, 2]),
        imageKey: ub([3, 4]),
        imageNonce: ub([5, 6]),
      );
      expect(g.imageHash, ub([1, 2]));
      expect(g.imageKey, ub([3, 4]));
      expect(g.imageNonce, ub([5, 6]));
    });
  });

  // ── MarmotMember ─────────────────────────────────────────────────────────

  group('MarmotMember', () {
    test('holds npub and pubkeyHex', () {
      const m = MarmotMember(npub: 'npub1x', pubkeyHex: 'abcdef');
      expect(m.npub, 'npub1x');
      expect(m.pubkeyHex, 'abcdef');
    });
  });

  // ── PendingWelcome ───────────────────────────────────────────────────────

  group('PendingWelcome', () {
    test('holds all fields', () {
      const pw = PendingWelcome(
        id: 'w1',
        groupName: 'My Group',
        inviterNpub: 'npub1inviter',
        memberCount: 3,
      );
      expect(pw.id, 'w1');
      expect(pw.groupName, 'My Group');
      expect(pw.inviterNpub, 'npub1inviter');
      expect(pw.memberCount, 3);
    });
  });

  // ── MemberChangeResult ──────────────────────────────────────────────────

  group('MemberChangeResult', () {
    test('holds evolution event and welcome rumors', () {
      const result = MemberChangeResult(
        evolutionEventJson: '{"kind":445}',
        welcomeRumors: ['rumor1', 'rumor2'],
      );
      expect(result.evolutionEventJson, '{"kind":445}');
      expect(result.welcomeRumors, hasLength(2));
    });

    test('welcomeRumors can be empty', () {
      const result = MemberChangeResult(
        evolutionEventJson: '{}',
        welcomeRumors: [],
      );
      expect(result.welcomeRumors, isEmpty);
    });
  });

  // ── GroupMetadataUpdate ──────────────────────────────────────────────────

  group('GroupMetadataUpdate', () {
    test('all fields nullable — empty update', () {
      const update = GroupMetadataUpdate();
      expect(update.name, isNull);
      expect(update.description, isNull);
      expect(update.relayUrls, isNull);
      expect(update.adminNpubs, isNull);
    });

    test('partial update sets some fields', () {
      const update = GroupMetadataUpdate(
        name: 'New',
        adminNpubs: ['npub1a'],
      );
      expect(update.name, 'New');
      expect(update.description, isNull);
      expect(update.adminNpubs, ['npub1a']);
    });
  });

  // ── GroupImagePrepared ──────────────────────────────────────────────────

  group('GroupImagePrepared', () {
    test('holds required fields without optionals', () {
      final prep = GroupImagePrepared(
        encryptedData: ub([1, 2, 3]),
        imageHash: ub([4, 5, 6]),
        imageKey: ub([7, 8]),
        imageNonce: ub([9, 10]),
        imageUploadKey: ub([11, 12]),
        uploadNsec: 'nsec1up',
        uploadPubkeyHex: 'ff',
        mimeType: 'image/png',
      );
      expect(prep.encryptedData, ub([1, 2, 3]));
      expect(prep.imageHash, ub([4, 5, 6]));
      expect(prep.imageKey, ub([7, 8]));
      expect(prep.imageNonce, ub([9, 10]));
      expect(prep.imageUploadKey, ub([11, 12]));
      expect(prep.uploadNsec, 'nsec1up');
      expect(prep.uploadPubkeyHex, 'ff');
      expect(prep.mimeType, 'image/png');
      expect(prep.blurhash, isNull);
      expect(prep.thumbhash, isNull);
      expect(prep.dimensionsWidth, isNull);
      expect(prep.dimensionsHeight, isNull);
    });
  });

  // ── MarmotMessage ────────────────────────────────────────────────────────

  group('MarmotMessage', () {
    test('holds text message fields', () {
      final msg = MarmotMessage(
        id: 'm1',
        groupId: 'g1',
        senderNpub: 'npub1sender',
        text: 'hello',
        timestampSecs: 1700000000,
        media: [],
      );
      expect(msg.id, 'm1');
      expect(msg.groupId, 'g1');
      expect(msg.senderNpub, 'npub1sender');
      expect(msg.text, 'hello');
      expect(msg.timestampSecs, 1700000000);
      expect(msg.media, isEmpty);
    });

    test('holds structured payload fields', () {
      final msg = MarmotMessage(
        id: 'm2',
        groupId: 'g2',
        senderNpub: 'npub1s',
        contentType: 'application/json',
        payloadJson: '{"type":"reaction"}',
        timestampSecs: 0,
        media: [],
      );
      expect(msg.text, isNull);
      expect(msg.contentType, 'application/json');
      expect(msg.payloadJson, '{"type":"reaction"}');
    });

    test('holds media refs', () {
      final ref = MarmotMediaRef(
        url: 'https://blossom.example/abc',
        originalHash: ub([1, 2, 3]),
        mimeType: 'image/png',
        filename: 'photo.png',
        schemeVersion: 'mip04',
        nonce: ub([4, 5, 6]),
      );
      final msg = MarmotMessage(
        id: 'm3',
        groupId: 'g3',
        senderNpub: 'npub1s',
        timestampSecs: 1,
        media: [ref],
      );
      expect(msg.media, hasLength(1));
      expect(msg.media.first.url, 'https://blossom.example/abc');
    });
  });

  // ── MarmotMediaRef ───────────────────────────────────────────────────────

  group('MarmotMediaRef', () {
    test('holds required fields', () {
      final ref = MarmotMediaRef(
        url: 'https://b.example/file',
        originalHash: Uint8List(0),
        mimeType: 'text/plain',
        filename: 'doc.txt',
        schemeVersion: 'mip04',
        nonce: Uint8List(0),
      );
      expect(ref.url, 'https://b.example/file');
      expect(ref.originalHash, isEmpty);
      expect(ref.mimeType, 'text/plain');
      expect(ref.filename, 'doc.txt');
      expect(ref.schemeVersion, 'mip04');
      expect(ref.nonce, isEmpty);
      expect(ref.dimensionsWidth, isNull);
      expect(ref.dimensionsHeight, isNull);
    });

    test('holds optional dimensions', () {
      final ref = MarmotMediaRef(
        url: 'u',
        originalHash: Uint8List(0),
        mimeType: '',
        filename: '',
        schemeVersion: '',
        nonce: Uint8List(0),
        dimensionsWidth: 1920,
        dimensionsHeight: 1080,
      );
      expect(ref.dimensionsWidth, 1920);
      expect(ref.dimensionsHeight, 1080);
    });
  });

  // ── EncryptedMediaOutput ─────────────────────────────────────────────────

  group('EncryptedMediaOutput', () {
    test('holds required fields without optionals', () {
      final out = EncryptedMediaOutput(
        encryptedData: ub([10, 20]),
        originalHash: ub([1, 2]),
        encryptedHash: ub([3, 4]),
        mimeType: 'image/png',
        filename: 'img.png',
        originalSize: BigInt.from(1024),
        encryptedSize: BigInt.from(1088),
        nonce: ub([5, 6]),
      );
      expect(out.encryptedData, ub([10, 20]));
      expect(out.originalHash, ub([1, 2]));
      expect(out.encryptedHash, ub([3, 4]));
      expect(out.mimeType, 'image/png');
      expect(out.filename, 'img.png');
      expect(out.originalSize, BigInt.from(1024));
      expect(out.encryptedSize, BigInt.from(1088));
      expect(out.nonce, ub([5, 6]));
      expect(out.blurhash, isNull);
      expect(out.thumbhash, isNull);
      expect(out.dimensionsWidth, isNull);
      expect(out.dimensionsHeight, isNull);
    });

    test('holds optional metadata fields', () {
      final out = EncryptedMediaOutput(
        encryptedData: Uint8List(0),
        originalHash: Uint8List(0),
        encryptedHash: Uint8List(0),
        mimeType: '',
        filename: '',
        originalSize: BigInt.zero,
        encryptedSize: BigInt.zero,
        nonce: Uint8List(0),
        blurhash: 'L6PZfSi_Io~q',
        thumbhash: 'abc',
        dimensionsWidth: 800,
        dimensionsHeight: 600,
      );
      expect(out.blurhash, 'L6PZfSi_Io~q');
      expect(out.thumbhash, 'abc');
      expect(out.dimensionsWidth, 800);
      expect(out.dimensionsHeight, 600);
    });
  });

  // ── MediaRefInput ────────────────────────────────────────────────────────

  group('MediaRefInput', () {
    test('holds all fields', () {
      final ref = MediaRefInput(
        url: 'https://b.example/f',
        originalHash: Uint8List(0),
        mimeType: 'image/jpeg',
        filename: 'pic.jpg',
        schemeVersion: 'mip04',
        nonce: Uint8List(0),
      );
      expect(ref.url, 'https://b.example/f');
      expect(ref.originalHash, isEmpty);
      expect(ref.mimeType, 'image/jpeg');
      expect(ref.filename, 'pic.jpg');
      expect(ref.schemeVersion, 'mip04');
      expect(ref.nonce, isEmpty);
    });
  });

  // ── MarmotError (freezed sealed) ─────────────────────────────────────────

  group('MarmotError', () {
    test('notInitialised variant', () {
      const e = MarmotError.notInitialised();
      expect(e, isA<MarmotError>());
    });

    test('invalidNsec variant', () {
      const e = MarmotError.invalidNsec();
      expect(e, isA<MarmotError>());
    });

    test('invalidRelayUrl variant with field', () {
      const e = MarmotError.invalidRelayUrl('bad-url');
      expect(e, isA<MarmotError>());
    });

    test('invalidEvent variant with field', () {
      const e = MarmotError.invalidEvent('bad json');
      expect(e, isA<MarmotError>());
    });

    test('groupNotFound variant', () {
      const e = MarmotError.groupNotFound();
      expect(e, isA<MarmotError>());
    });

    test('welcomeNotFound variant', () {
      const e = MarmotError.welcomeNotFound();
      expect(e, isA<MarmotError>());
    });

    test('notAdmin variant', () {
      const e = MarmotError.notAdmin();
      expect(e, isA<MarmotError>());
    });

    test('media variant with field', () {
      const e = MarmotError.media('encryption failed');
      expect(e, isA<MarmotError>());
    });

    test('mdk variant with field', () {
      const e = MarmotError.mdk('internal error');
      expect(e, isA<MarmotError>());
    });

    test('unsupported variant with field', () {
      const e = MarmotError.unsupported('no keyring');
      expect(e, isA<MarmotError>());
    });

    test('keyring variant with field', () {
      const e = MarmotError.keyring('store unavailable');
      expect(e, isA<MarmotError>());
    });

    test('lock variant', () {
      const e = MarmotError.lock();
      expect(e, isA<MarmotError>());
    });

    test('noIdentity variant', () {
      const e = MarmotError.noIdentity();
      expect(e, isA<MarmotError>());
    });

    test('invalidPublicKey variant', () {
      const e = MarmotError.invalidPublicKey();
      expect(e, isA<MarmotError>());
    });
  });

  // ── StorageConfig (freezed sealed) ───────────────────────────────────────

  group('StorageConfig', () {
    test('memory variant', () {
      const config = StorageConfig.memory();
      expect(config, isA<StorageConfig>());
    });

    test('sqlite variant', () {
      const config = StorageConfig.sqlite(
        dbPath: '/tmp/db',
        serviceId: 'com.app',
        keyId: 'db-key',
      );
      expect(config, isA<StorageConfig>());
    });

    test('sqliteWithKey variant', () {
      final config = StorageConfig.sqliteWithKey(
        dbPath: '/tmp/db',
        dbKey: ub(List.generate(32, (_) => 0x42)),
      );
      expect(config, isA<StorageConfig>());
    });
  });
}
