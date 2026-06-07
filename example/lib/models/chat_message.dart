import 'package:marmot_dart/marmot_dart.dart';

enum FileStatus { sent, pending, downloading, done, error }

class ChatMessage {
  final String sender;
  final bool isMine;
  final String? text;
  final MarmotMediaRef? media;
  FileStatus status;
  String? savedPath;
  String? errorMsg;

  ChatMessage.text({
    required this.sender,
    required this.isMine,
    required this.text,
  }) : media = null,
       status = FileStatus.sent,
       savedPath = null,
       errorMsg = null;

  ChatMessage.file({
    required this.sender,
    required this.isMine,
    required MarmotMediaRef this.media,
    this.text,
    this.status = FileStatus.pending,
    this.savedPath,
  }) : errorMsg = null;

  bool get isFile => media != null;
}
