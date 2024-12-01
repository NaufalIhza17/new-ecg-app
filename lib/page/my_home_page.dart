
import 'dart:async';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:ecg/model/ecg_data.dart';
import 'package:ecg/model/ecg_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:real_time_chart/real_time_chart.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io' show Platform;
import '../common.dart';
import '../model/model.dart';
import '../model/model_output.dart';
import '../provider/blob_config.dart';
import '../provider/client.dart';
import '../provider/decoration.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:sqflite/sqflite.dart';
import '../provider/label_provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  // COMMON COMPONENTS
  TextStyle headerTextStyle = const TextStyle(
    color: Colors.black,
    //fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  TextStyle focusTextStyle = const TextStyle(
    color: Colors.red,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  TextStyle infoTextStyle = TextStyle(
    fontFamily: Platform.isIOS ? 'Courier' : 'monospace',
    fontSize: Platform.isIOS ? 17 : 16,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  TextStyle fieldTextStyle = TextStyle(
    fontFamily: Platform.isIOS ? 'Courier' : 'monospace',
    fontSize: Platform.isIOS ? 19 : 18,
    fontWeight: FontWeight.w600,
    color: Colors.blue,
  );

  TextStyle errorTextStyle = TextStyle(
    fontFamily: Platform.isIOS ? 'Courier' : 'monospace',
    fontSize: Platform.isIOS ? 19 : 18,
    fontWeight: FontWeight.w600,
    color: Colors.red,
  );

  bool _showStartDateDialog = false;
  bool _showEndDateDialog = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(hours: 1));
  DateTime _endDate = DateTime.now();
  final HealthFactory _health = HealthFactory(useHealthConnectIfAvailable: true);
  final List<HealthDataType> _types = [HealthDataType.ELECTROCARDIOGRAM];
  //List<DropdownMenuItem<HealthDataPoint>> _records = [];
  List<HealthDataPoint> _healthData = [];
  List<ECGData> _data = [];
  HealthDataPoint? _selectedDataPoint;
  List<double> _voltages = [];

  late ECGReport metadata;

  late UploadClient? client;
  final String api = 'ecg';

  late Interpreter _genderInterpreter;
  late Tensor _genderInputTensor;
  late Tensor _genderOutputTensor;
  late Interpreter _pregnancyInterpreter;
  late Tensor _pregnancyInputTensor;
  late Tensor _pregnancyOutputTensor;

  int _tid = 0;
  String _status = '';
  final int _numberOfTries = 9;
  List<ModelOutput> _genderOutputs = [];
  List<ModelOutput> _pregnancyOutputs = [];
  int _averageTime = -1;
  List<Model> _models = [];
  Model? _selectedModel;
  Stopwatch timer = Stopwatch();


  // Controller
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final nameFocusNode = FocusNode();
  String? nameValidator = 'Please enter Name';

  final ageController = TextEditingController();
  final ageFocusNode = FocusNode();
  String? ageValidator = 'Please enter Age';

  final pediatricsController = TextEditingController();
  final pediatricsFocusNode = FocusNode();
  String? pediatricsValidator = 'Please enter Pediatrics';

  final databaseName = 'ecg.db';
  final tableName = 'ECG';
  String databasePath = '';
  late Database database;
  void loadAllModel() {
    var model = _models[0];
    _selectedModel = model;
    tfl.Interpreter.fromAsset('assets/${model.fileName}.tflite').then((value) {
      _genderInterpreter = value;
      _genderInputTensor = _genderInterpreter.getInputTensors().first;
      _genderOutputTensor = _genderInterpreter.getOutputTensors().first;
      debugPrint(_genderInputTensor.toString());
      debugPrint(_genderOutputTensor.toString());
    });
    model = _models[1];
    tfl.Interpreter.fromAsset('assets/${model.fileName}.tflite').then((value) {
      _pregnancyInterpreter = value;
      _pregnancyInputTensor = _pregnancyInterpreter.getInputTensors().first;
      _pregnancyOutputTensor = _pregnancyInterpreter.getOutputTensors().first;
      debugPrint(_pregnancyInputTensor.toString());
      debugPrint(_pregnancyOutputTensor.toString());
    });

  }

  List<double> normalizeInput(List<double> input, Model model) {
    return input.map((e) { return (e-model.mean)/model.std;}).toList();
  }

  void initMetadata() {
    metadata = ECGReport(id: Common.timestampNow(), dataInfo: '', label: LabelProvider.labels[0], name: '', age: -1, pediatrics: -1);
    List<String> genderLabels = ['Female', 'Male'];
    List<String> pregnancyLabels = ['Non Pregnancy', 'Pregnancy'];

    _models = [
      Model(id:0, fileName: 'resnet18_gender2' ,name: 'Resnet18', task: 'Gender',
          mean: -0.02404451, std: 0.6902185, threshold: 0.5, labels: genderLabels),
      Model(id:1, fileName: 'resnet18_pregnant1' ,name: 'Resnet18', task: 'Pregnancy',
          mean: -0.0251138, std: 0.7312898, threshold: 0.80, labels: pregnancyLabels),
      const Model(id:2, fileName: 'resnet18' ,name: 'Resnet18', task: 'Gender-Pregnancy',
          mean: 0.0, std: 1.0, threshold: 0.0, labels: [],),
      //Model(fileName: 'lawnet_gender3' ,name: 'LAWNet', task: 'Gender Classification',
          //mean: -0.02389351, std: 0.69433624, threshold: 0.3, labels: genderLabels),
    ];
    loadAllModel();
    WidgetsFlutterBinding.ensureInitialized();
    getDatabasesPath().then((value) {
      databasePath = join(value, databaseName);
      // Open database
      openDatabase(databasePath, version:1, onCreate: (Database db, int version) async {
        await db.execute(''
          'CREATE TABLE IF NOT EXISTS $tableName (id INTEGER PRIMARY KEY, dataInfo TEXT, label TEXT, name TEXT, age INTEGER, pediatrics INTEGER)');
      }).then((db) {
        database = db;
        debugPrint('Database created');
      });
    });
  }

  @override
  void initState() {
    super.initState();
    LabelProvider.selectedLabel = 0;
    Common.getDeviceInfo();
    _health.requestAuthorization(_types).then((value) {
      debugPrint('Health Authorization: $value');
      readHealthData();
      initMetadata();
      _changedSelectedModel(_models.first);
    });

  }

  @override
  void dispose() {
    //_timer?.cancel();
    super.dispose();
  }

  bool validate() {
    if(!formKey.currentState!.validate()) {
      if (nameController.text.isEmpty) {
        nameFocusNode.requestFocus();
        return false;
      } else if (ageController.text.isEmpty) {
        ageFocusNode.requestFocus();
        return false;
      } else if (LabelProvider.selectedLabel! > 1 && pediatricsController.text.isEmpty) {
        pediatricsFocusNode.requestFocus();
        return false;
      }
    } else {
      metadata.name = nameController.text;
      metadata.age = int.parse(ageController.text);
      if(pediatricsController.text.isNotEmpty) {
        metadata.pediatrics = int.parse(pediatricsController.text);
      } else {
        metadata.pediatrics = - 1;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final stream = nextDataStream();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appThemeData.colorScheme.inversePrimary,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 22)),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Padding(
            padding: Common.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                //Pick ECG
                Container(
                  padding: const EdgeInsets.only(left: 0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed:() {
                      setState(() {
                        _showStartDateDialog = !_showStartDateDialog;
                      });
                    },
                    child: Text(
                      '- Start Date: ${DateFormat("yyyy-MM-dd").format(_startDate)}',
                      style: fieldTextStyle,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                Visibility(
                  visible: _showStartDateDialog,
                  child: CalendarDatePicker2(
                    config: CalendarDatePicker2Config(),
                    value: [_startDate],
                    onValueChanged: (dates) {
                      setState(() {
                        _startDate = dates.first!;
                        readHealthData();
                        _showStartDateDialog = false;
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 0),
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed:() {
                      setState(() {
                        _showEndDateDialog = !_showEndDateDialog;
                      });
                    },
                    child: Text(
                      '- End Date  : ${DateFormat("yyyy-MM-dd").format(_endDate)}',
                      style: fieldTextStyle,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                Visibility(
                  visible: _showEndDateDialog,
                  child: CalendarDatePicker2(
                    config: CalendarDatePicker2Config(),
                    value: [_endDate],
                    onValueChanged: (dates) {
                      setState(() {
                        _endDate = dates.first!;
                        readHealthData();
                        _showEndDateDialog = false;
                      });
                    },
                  ),
                ),
                Visibility(
                    visible: _healthData.isEmpty,
                    child: Container(
                      padding: const EdgeInsets.only(left: 0, top: 10, right:0, bottom:0),
                      //margin: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text('- No ECG Report Found',
                        style: errorTextStyle,
                        textAlign: TextAlign.left,
                      ),
                    ),
                ),
                Visibility(
                  visible: _healthData.isNotEmpty,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            '- Report: ',
                            style: fieldTextStyle,
                            textAlign: TextAlign.left,
                          ),
                          DropdownButtonFormField(
                              hint: const Text('Pick Report'),
                              decoration: const InputDecoration(
                                isDense: true,
                              ),
                              style: fieldTextStyle,
                              value: _selectedDataPoint,
                              items: _getDataPointList(),
                              onChanged: _changedSelectedDataPoint
                          ),
                        ]),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            '- Classification: ',
                            style: fieldTextStyle,
                            textAlign: TextAlign.left,
                          ),
                          DropdownButtonFormField(
                              hint: const Text('Pick Model'),
                              decoration: const InputDecoration(
                                isDense: true,
                              ),
                              style: fieldTextStyle,
                              value: _selectedModel,
                              items: _getModelList(),
                              onChanged: _changedSelectedModel
                          ),
                        ]),
                      // Draw signal
                      //const SizedBox(height: 5,),
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width*0.55,
                        child: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 5),
                            child: RealTimeGraph(
                              updateDelay: const Duration(milliseconds: 4),
                              stream: stream.map((value) => double.parse((value*250).toStringAsFixed(0))),
                              supportNegativeValuesDisplay: true,
                              displayYAxisValues: false,
                              displayYAxisLines: false,
                              pointsSpacing: 1,
                              graphStroke: 3,
                              axisStroke: 1,
                              //speed: 2,
                              xAxisColor: Colors.white,
                              graphColor: Colors.red,
                            )
                        ),
                      ),
                      //const SizedBox(height: 5,),
                      // Show result for gender classification
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.only(left: 10, top: 0, right:0.0, bottom:0.0),
                            child: Text(
                              _status,
                              style: focusTextStyle,
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.only(left: 10, top: 0, right:0.0, bottom:0.0),
                            child: Text(
                              _getLabel(), // (${_averageOutput.toStringAsPrecision(2)})',
                              style: const TextStyle(color: Colors.green, fontSize: 19, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      // User Form
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              focusNode: nameFocusNode,
                              validator: (value) {
                                if(value==null || value.isEmpty) {
                                  return nameValidator;
                                }
                                return null;
                              },
                              controller: nameController,
                              decoration: const InputDecoration(
                                  isDense: true,
                                  //hintText: 'Enter Name',
                                  labelText: 'Name'
                              ),
                              autofocus: false,
                              onFieldSubmitted: (value) {
                                validate();
                              },
                              textAlign: TextAlign.center,
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              focusNode: ageFocusNode,
                              validator: (value) {
                                if(value==null || value.isEmpty) {
                                  return ageValidator;
                                }
                                return null;
                              },
                              controller: ageController,
                              decoration: const InputDecoration(
                                isDense: true,
                                //hintText: 'Enter Age',
                                labelText: 'Age',
                                counterText: '',
                              ),
                              autofocus: false,
                              onFieldSubmitted: (value) {
                                validate();
                              },
                              textAlign: TextAlign.center,
                              textInputAction: TextInputAction.next,
                              maxLength: 2,
                              keyboardType: const TextInputType.numberWithOptions(signed: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          //const SizedBox(width: 10),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField(
                                hint: const Text('Select Label'),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: UnderlineInputBorder(),
                                  labelText: 'Label',
                                ),
                                alignment: Alignment.center,
                                value: LabelProvider.selectedLabel,
                                items: LabelProvider.getLabelDropdownList(),
                                onChanged: changedSelectedLabel
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              enabled: LabelProvider.selectedLabel! > 1,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              focusNode: pediatricsFocusNode,
                              validator: (value) {
                                if(LabelProvider.selectedLabel! > 1 && (value==null || value.isEmpty)) {
                                  return pediatricsValidator;
                                }
                                return null;
                              },
                              controller: pediatricsController,
                              decoration: const InputDecoration(
                                isDense: true,
                                //hintText: 'Enter Pediatrics (weeks)',
                                labelText: 'Pediatrics (weeks)',
                                counterText: '',
                              ),
                              autofocus: false,
                              onFieldSubmitted: (value) {
                                validate();
                              },
                              textAlign: TextAlign.center,
                              textInputAction: TextInputAction.next,
                              //maxLength: 2,
                              keyboardType: const TextInputType.numberWithOptions(signed: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20,),
                      Center(
                        child: FloatingActionButton.extended(
                          onPressed: saveAndUpload,
                          tooltip: 'Save ECG Report to Database',
                          icon: const Icon(Icons.cloud_upload, size: 40),
                          label: const Text('Save and Upload', style: TextStyle(fontWeight: FontWeight.bold,),),
                        ),
                      )
                    ],
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future saveAndUpload() async {
    if(validate()) {
      // Save metadata
      int id = await database.rawInsert(
          'INSERT OR REPLACE INTO $tableName(id, dataInfo, label, name, age, pediatrics) VALUES(${metadata.id}, \'${metadata.dataInfo}\', \'${metadata.label}\', \'${metadata.name}\', ${metadata.age}, ${metadata.pediatrics})');
      debugPrint('Inserted ECG: $id');

      // await database.transaction((txn) async {
      //   int id1 = await txn.rawInsert(
      //       'INSERT INTO');
      // });
      uploadMetaData();
    }
  }
  void changedSelectedLabel(int? value) {
    setState(() {
      LabelProvider.selectedLabel = value;
      if(value! <2) {
        pediatricsController.clear();
        //pediatricsValidator = null;
      } else {
        //pediatricsValidator = 'Please enter Pediatrics';
        //pediatricsFocusNode.requestFocus();
      }
      metadata.label = LabelProvider.labels[value];
    });
  }

  void _resetModelOutputs() {
    /*_averageOutput = -1.0;
    for(int i=0; i<_outputs.length; ++i){
      _outputs[i] = -1.0;
    }*/
    _averageTime = -1;
    _genderOutputs = List<ModelOutput>.filled(_numberOfTries, const ModelOutput(value: -1, time: -1));
    _pregnancyOutputs = List<ModelOutput>.filled(_numberOfTries, const ModelOutput(value: -1, time: -1));
  }

  String _getLabel() {
    if(_selectedModel==null) return '';
    var id = _selectedModel!.id;
    _averageTime = 0;
    int genderCount = 0;
    int pregnancyCount = 0;
    debugPrint('Gender all outputs: ${_genderOutputs.map((e) => e.value).join(',')}');
    debugPrint('Pregnancy all outputs: ${_pregnancyOutputs.map((e) => e.value).join(',')}');

    if(id==0 || id==2) {
      for (int i = 0; i < _genderOutputs.length; ++i) {
        if (_genderOutputs[i].time > -1) {
          genderCount++;
          _averageTime += _genderOutputs[i].time;
        }
      }
      if(genderCount>0) {
        _averageTime = _averageTime ~/ genderCount;
      } else {
        _averageTime = -1;
        return 'Failed (No prediction)';
      }
    } else if(id==1) {
      for (int i = 0; i < _pregnancyOutputs.length; ++i) {
        if (_pregnancyOutputs[i].time > -1) {
          pregnancyCount++;
          _averageTime += _pregnancyOutputs[i].time;
        }
      }
      if(pregnancyCount>0) {
        _averageTime = _averageTime ~/ pregnancyCount;
      } else {
        _averageTime = -1;
        return 'Failed (No prediction)';
      }
    }

    if(id==0) {
      int g0 = _genderOutputs.where((e) => e.value < _selectedModel!.threshold).length;
      int g1 = _genderOutputs.length - g0;

      if (g0 > g1) {
        return '${_selectedModel!.labels[0]} ($g0/${_genderOutputs
            .length}) in $_averageTime ms';
      } else {
        return '${_selectedModel!.labels[1]} ($g1/${_genderOutputs
            .length}) in $_averageTime ms';
      }
    } else if(id==1){
      int p0 = _pregnancyOutputs.where((e) => e.value < _selectedModel!.threshold).length;
      int p1 = _pregnancyOutputs.length - p0;

      if (p0 > p1) {
        return '${_selectedModel!.labels[0]} ($p0/${_pregnancyOutputs
            .length}) in $_averageTime ms';
      } else {
        return '${_selectedModel!.labels[1]} ($p1/${_pregnancyOutputs
            .length}) in $_averageTime ms';
      }
    }
    else
    {
      int g0 = _genderOutputs.where((e) => e.value < _models[0].threshold).length;
      int g1 = _genderOutputs.length - g0;

      if(g0>g1) {
        // if is female then show pregnancy prediction
        int p0 = _pregnancyOutputs.where((e) => e.value < _models[1].threshold).length;
        int p1 = _pregnancyOutputs.length - p0;

        if (p0 > p1) {
          return '${_models[0].labels[0]} ($g0/${_genderOutputs
              .length}), ${_models[1].labels[0]} ($p0/${_pregnancyOutputs
              .length})\nin $_averageTime ms';
        } else {
          return '${_models[0].labels[0]} ($g0/${_genderOutputs
              .length}), ${_models[1].labels[1]} ($p1/${_pregnancyOutputs
              .length})\nin $_averageTime ms';
        }
      } else {
        return '${_models[0].labels[1]} ($g1/${_genderOutputs
            .length}), ${_models[1].labels[0]}\nin $_averageTime ms';
      }
    }

    /*if(_averageOutput<0) {
      return 'N/A';
    }else if(_averageOutput<_selectedModel!.threshold) {
      return _selectedModel!.labels[0];
    } else {
      return _selectedModel!.labels[1];
    }*/
  }

  Stream<double> nextDataStream() {
    return Stream.periodic(const Duration(milliseconds: 4), (_) {
      //return Random().nextInt(10).toDouble();
      if(_data.isEmpty) return 0.0;
        if(_tid>=_data.length) {
          _tid = 0;
        }
        //debugPrint(_data[_tid].voltage.toString());
        return _data[_tid++].voltage;
      }).asBroadcastStream();
  }

  void readVoltages() {
    if(_selectedDataPoint==null) _voltages=[];
    var jsonArray = _selectedDataPoint!.value.toJson()['voltageValues'] as List<Map<String, dynamic>>;
    //debugPrint(jsonArray.toString());
    var times = Iterable<int>.generate(jsonArray.length).toList();
    //if(_timer != null) _timer?.cancel();
    _voltages = jsonArray.map((e) { return 1000*(e['voltage'] as double); }).toList();
    _data = times.map( (t) {
      return ECGData(time:t.toDouble(), voltage: _voltages[t]);
    }).toList();
    _tid = 0;
    debugPrint('Number voltages: ${_data.length}. First: ${_data.first.voltage}');
    //_startDrawECGLine();
    setState(() {
      _status = 'Prediction';
    });
  }

  void _changedSelectedDataPoint(HealthDataPoint? selectedDataPoint) {
    setState(() {
      _selectedDataPoint = selectedDataPoint;
      _status = 'Reading voltages';
      readVoltages();
      metadata.id = _selectedDataPoint!.dateFrom.millisecondsSinceEpoch;
      metadata.dataInfo = _selectedDataPoint!.toString();//Common.listDoubleToString(_voltages, '_', 15);
      // Get the user information from database
      database.rawQuery('SELECT * FROM $tableName WHERE id = ${metadata.id} LIMIT 1').then((value) {
        debugPrint('SELECTED VALUE: ${value.toString()}');
        if(value.isNotEmpty) {
          nameController.text = value.first['name'].toString();
          ageController.text = value.first['age'].toString();
          pediatricsController.text = value.first['pediatrics'].toString();
          changedSelectedLabel(LabelProvider.labels.indexOf(value.first['label'].toString()));
        } else {
          nameController.clear();
          ageController.clear();
          pediatricsController.clear();
          changedSelectedLabel(0);
        }
      });
    });
    uploadSignal(_selectedDataPoint!.dateFrom, _voltages);
  }

  void _changedSelectedModel(Model? selectedModel) {
    setState(() {
      _selectedModel = selectedModel;
      //_status = 'Loading model';
    });
    //loadModel(_selectedModel!);
    readVoltages();
    uploadSignal(_selectedDataPoint!.dateFrom, _voltages);
  }

  Future uploadSignal(DateTime startTime, List<double> data) async {
    try {
      client = UploadClient(
        signal: data,
        metadata: metadata,
        blobConfig: BlobConfig(
          blobUrl: Common.masterServerPort,
          uuid: Common.uuid??'anonymous',
          timestamp: Common.dateTimeToString(startTime, ''),
        ),
      );

      client!.uploadSignal(
        onComplete: (_) {
          setState(() {
            _resetModelOutputs();
            for(int i=0; i<_numberOfTries; ++i) {
              getCWT(i);
            }
          });
        },
        onTimeout: () {
          setState(() {
            _status = 'Connection failed';
          });
        },
      );
    } catch(e) {
      setState(() {
        _status = 'Connection failed';
      });
      return;
    }
  }

  Future uploadMetaData() async {
    try {
      client?.metadata = metadata;
      client!.uploadMetadata(
        onComplete: (_) {
          setState(() {
            Common.showAlertDialog(this.context, 'Upload ECG Metadata', 'Successfully', const Duration(seconds: 2),);
          });
        },
        onTimeout: () {
          setState(() {
            _status = 'Connection failed';
            Common.showAlertDialog(this.context, 'Upload ECG Metadata', 'Connection Timeout', const Duration(seconds: 2), Colors.red);
          });
        },
      );
    } catch(e) {
      setState(() {
        _status = 'Connection failed';
        Common.showAlertDialog(this.context, 'Upload ECG Metadata', 'Failed', const Duration(seconds: 2), Colors.red);
      });
      return;
    }
  }

  Future getCWT(int segmentId) async {
    debugPrint('Segment $segmentId: ');
    try {
      client!.getCWT(
        segmentId,
        onComplete: (value) {

          if(value.isNotEmpty) {
            var key = value.keys.first;
            var genderOutput = [[0.0]];
            var pregnancyOutput = [[0.0]];
            var id = _selectedModel!.id;
            timer.reset();
            timer.start();
            if(id==0) {
              var cwt = normalizeInput(value[key]!, _models[0]);
              var input = cwt.reshape(_genderInputTensor.shape);
              _genderInterpreter.run(input, genderOutput);
            } else if(id==1) {
              var cwt = normalizeInput(value[key]!, _models[1]);
              var input = cwt.reshape(_pregnancyInputTensor.shape);
              _pregnancyInterpreter.run(input, pregnancyOutput);
            } else if(id==2) {
              var cwt1 = normalizeInput(value[key]!, _models[0]);
              var input1 = cwt1.reshape(_genderInputTensor.shape);
              var cwt2 = normalizeInput(value[key]!, _models[1]);
              var input2 = cwt2.reshape(_pregnancyInputTensor.shape);
              _genderInterpreter.run(input1, genderOutput);
              _pregnancyInterpreter.run(input2, pregnancyOutput);
            }
            timer.stop();

            setState(() {
              if(id==0) {
                _genderOutputs[key] = ModelOutput(value: genderOutput.first.first, time: timer.elapsedMilliseconds);
                debugPrint('Gender Output: ${genderOutput.first.first}');
              } else if(id==1) {
                _pregnancyOutputs[key] = ModelOutput(value: pregnancyOutput.first.first, time: timer.elapsedMilliseconds);
                debugPrint('Pregnancy Output: ${genderOutput.first.first}');
              } else if(id==2) {
                _genderOutputs[key] = ModelOutput(value: genderOutput.first.first, time: timer.elapsedMilliseconds);
                _pregnancyOutputs[key] = ModelOutput(value: pregnancyOutput.first.first, time: timer.elapsedMilliseconds);
                debugPrint('Gender Output: ${genderOutput.first.first}');
                debugPrint('Pregnancy Output: ${pregnancyOutput.first.first}');
              }
              debugPrint('--------------------------------------------');
            });
          }
        },
        onTimeout: () {
          setState(() {
            _status = 'Predicting failed';
          });
        },
      );

    } catch(e) {
      setState(() {
        _status = e.toString();
      });

      return;
    }
  }

  List<DropdownMenuItem<HealthDataPoint>> _getDataPointList() {
    return _healthData.map((e) {

      //debugPrint(e.toString());
      //debugPrint('Health data: ${e.value.toString()}');
      //debugPrint('Platform: ${e.platform}');
      //debugPrint('SourceName: ${e.sourceName}');
      String bpm = e.value.toString().split(',')[1].replaceAll('.0', '');
      String startTime = Common.dateTimeToString(
          e.dateFrom, 'yy-MM-dd HH:mm:ss');
      return DropdownMenuItem(
          value: e,
          child: SizedBox(
              child: Center(child: Text('$bpm $startTime', style: const TextStyle(fontSize: 18),))));
    }).toList();
  }

  List<DropdownMenuItem<Model>> _getModelList() {
    return _models.map((e) {
      return DropdownMenuItem(
        value: e,
        child: SizedBox(
            child: Center(child: Text(e.task,))));
    }).toList();
  }

  void readHealthData() async {
    _health.getHealthDataFromTypes(_startDate, _endDate, _types).then((data) {
      setState(() {
        _healthData = data;
        if(data.isNotEmpty) {
          debugPrint('ECG info: ${data.first.value.toString()}');
          _changedSelectedDataPoint(data.first);
        } else {
          _selectedDataPoint = null;
          debugPrint('Health data is empty');
        }
      });
    });
  }

}