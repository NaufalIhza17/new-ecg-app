import 'package:flutter/cupertino.dart';

class BlobConfig {
  final String blobUrl;
  final String uuid;
  late final String timestamp;


  BlobConfig({required this.blobUrl, required this.uuid, required this.timestamp});

  Uri getUri(String api, [String type='V']) {
    String url = '$blobUrl/$api/${uuid}_$timestamp';
    if(type.isNotEmpty){
      url = '${url}_$type';
    }
    debugPrint(url);
    return Uri.parse(url);
  }
}