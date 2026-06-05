import 'rust/api/groups.dart' as g;
import '_ensure.dart';

Future<g.GroupCreateResult> createGroup(String dbPath, String creatorNpub, g.CreateGroupParams params) async {
  await ensureNativeLibrary();
  return g.create(dbPath: dbPath, creatorNpub: creatorNpub, params: params);
}

Future<void> processWelcome(String dbPath, String wrapperEventId, String welcomeRumorJson) async {
  await ensureNativeLibrary();
  return g.processWelcome(dbPath: dbPath, wrapperEventId: wrapperEventId, welcomeRumorJson: welcomeRumorJson);
}

Future<List<g.PendingWelcome>> getPendingWelcomes(String dbPath) async {
  await ensureNativeLibrary();
  return g.getPendingWelcomes(dbPath: dbPath);
}

Future<void> acceptWelcome(String dbPath, String welcomeId) async {
  await ensureNativeLibrary();
  return g.acceptWelcome(dbPath: dbPath, welcomeId: welcomeId);
}

Future<List<g.MarmotGroup>> listGroups(String dbPath) async {
  await ensureNativeLibrary();
  return g.list(dbPath: dbPath);
}

Future<List<g.MarmotMember>> getMembers(String dbPath, String groupId) async {
  await ensureNativeLibrary();
  return g.getMembers(dbPath: dbPath, groupId: groupId);
}

Future<g.MemberChangeResult> addMember(String dbPath, String groupId, String keyPackageEventJson) async {
  await ensureNativeLibrary();
  return g.addMember(dbPath: dbPath, groupId: groupId, keyPackageEventJson: keyPackageEventJson);
}

Future<g.MemberChangeResult> removeMember(String dbPath, String groupId, String npub) async {
  await ensureNativeLibrary();
  return g.removeMember(dbPath: dbPath, groupId: groupId, npub: npub);
}
