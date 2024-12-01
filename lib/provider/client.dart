import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:ecg/model/ecg_report.dart';
import 'package:ecg/provider/blob_config.dart';
import 'package:ecg/provider/upload_status.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'exception.dart';

typedef CompleteCallback = void Function(Map<int, List<double>>);

class UploadClient {
  // The signal voltage array to upload
  List<double> signal;

  // The signal metadata to upload
  ECGReport metadata;

  // Zenoh blob config
  BlobConfig? blobConfig;

  // Upload status
  UploadStatus _status;

  // Callback function after upload
  CompleteCallback? _onComplete;

  // Request timeout
  // default is 30 seconds
  final Duration timeout;

  // Callback function on timeout request
  Function()? _onTimeout;

  UploadClient({
    required this.signal,
    required this.metadata,
    this.blobConfig,
    Duration? timeout,
  })
      : timeout = timeout ?? const Duration(seconds: 30),
        _status = UploadStatus.initialized;

  uploadSignal({
    CompleteCallback? onComplete,
    Function()? onTimeout,
  }) async {
    if (_status == UploadStatus.started) {
      throw ResumableUploadException('Error: a file is uploading');
    }
    if (blobConfig == null) {
      throw ResumableUploadException('Blob config missing');
    }
    _status = UploadStatus.started;
    _onComplete = onComplete;
    _onTimeout = onTimeout;
    await _uploadSignal();
  }

  uploadMetadata({
    CompleteCallback? onComplete,
    Function()? onTimeout,
  }) async {
    if (_status == UploadStatus.started) {
      throw ResumableUploadException('Error: uploading');
    }
    if (blobConfig == null) {
      throw ResumableUploadException('Blob config missing');
    }
    _status = UploadStatus.started;
    _onComplete = onComplete;
    _onTimeout = onTimeout;
    await _uploadMetadata();
  }

  getCWT(int segmentId, {
    CompleteCallback? onComplete,
    Function()? onTimeout,
  }) async {
    //if (_status == UploadStatus.started) {
      //throw ResumableUploadException('Error: a file is uploading');
    //}
    if (blobConfig == null) {
      throw ResumableUploadException('Blob config missing');
    }
    _status = UploadStatus.started;
    _onComplete = onComplete;
    _onTimeout = onTimeout;
    await _getCWT(segmentId);
  }

  Future _uploadSignal() async {
    // 1. Upload signal
    debugPrint('================================');
    debugPrint('1. UPLOADING SIGNAL DATA (VOLTAGES)');
    debugPrint('First voltage: ${signal[0]}');

    // Convert to bytes array
    List<int> data = List.empty(growable: true);
    var bytes = ByteData(4);
    bool printed = false;
    for(var e in signal){
      bytes.setFloat32(0, e);
      if(!printed) debugPrint(bytes.buffer.asUint8List().toString());
      printed = true;
      data.addAll(bytes.buffer.asUint8List());
    }
    // Put
    debugPrint('Upload URI: ${blobConfig!.getUri('ecg', 'V')}');

    Future? uploadFuture = http.put(
        blobConfig!.getUri('ecg', 'V'), body: data);
    final response = await uploadFuture.timeout(timeout, onTimeout: () {
      _onTimeout?.call();
      return http.Response(
          '', HttpStatus.requestTimeout, reasonPhrase: 'Request timeout');
    });
    debugPrint('Upload signal response code: ${response.statusCode.toString()}');

    if (response.statusCode != 200) {
      _status = UploadStatus.error;
      _onTimeout?.call();
    } else {
      _status = UploadStatus.completed;
      _onComplete?.call({});
    }
  }

  Future _uploadMetadata() async {
    // Upload signal metadata
    debugPrint('================================');
    debugPrint('1. UPLOADING SIGNAL METADATA (HealthDataPoint Info)');

    // Put
    Future? uploadFuture = http.put(
        blobConfig!.getUri('ecg', 'M'),
        headers: <String, String> {
          'Content-Type': 'application/json; charset=UTF-8',},
        body: jsonEncode(metadata),
    );
    final response = await uploadFuture.timeout(timeout, onTimeout: () {
      _onTimeout?.call();
      return http.Response(
          '', HttpStatus.requestTimeout, reasonPhrase: 'Request timeout');
    });
    debugPrint('Upload signal metadata response code: ${response.statusCode.toString()}');

    if (response.statusCode != 200) {
      _status = UploadStatus.error;
      _onTimeout?.call();
    } else {
      _status = UploadStatus.completed;
      _onComplete?.call({});
    }
  }

  UploadStatus status() => _status;

  Future _getCWT([int segmentId=0]) async {
    // 2. Get CWT
    //debugPrint('2. GETTING CWT');
    int repeat=10;
    List<double> cwt = [];

    while(true){
      var response = await http.get(blobConfig!.getUri('cwt', segmentId.toString()));

      if (response.statusCode == 200) {
        //debugPrint(response.body);
        List<dynamic> jsonArray = List.from(jsonDecode(response.body));
        var cwtString = jsonArray[0]['value'].toString();
        debugPrint('Getting segment $segmentId try ${10-repeat+1}:');
        if (cwtString == 'error') {
          debugPrint('Not received cwt $segmentId');
          cwt = [];
        } else {
          debugPrint('Length of cwtString ${cwtString.length}');
          //debugPrint(cwtString);
          var cwtBytes = base64Decode(cwtString);
          debugPrint('Length of cwtBytes ${cwtBytes.length}');
          ByteData byteData = cwtBytes.buffer.asByteData();
          cwt = [
            for(var offset = 0; offset < cwtBytes.length; offset += 4)
              byteData.getFloat32(offset, Endian.little),
          ];
          debugPrint('Length of decoded cwt: ${cwt.length}, example: ${cwt[0]}');
        }
        break;
      }
      repeat--;

      if(repeat<1) {
        _status = UploadStatus.error;
        _onTimeout?.call();
        return;
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }
    _status = UploadStatus.completed;
    _onComplete?.call({segmentId:cwt});
  }
}
