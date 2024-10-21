import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:thesis_application/db/dbprovider.dart';
import 'package:thesis_application/db/models.dart';
import 'package:thesis_application/pages/daily_activity_chart.dart';
import 'package:thesis_application/pages/daily_activity_series.dart';
import 'package:thesis_application/pages/daily_activity_time_chart.dart';
import 'package:thesis_application/pages/daily_activity_time_series.dart';
import 'package:thesis_application/pages/weekly_activity_chart.dart';
import 'package:thesis_application/pages/weekly_activity_series.dart';
import 'package:thesis_application/shared/notification_service.dart';
import 'package:thesis_application/shared/variables.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:fl_chart/fl_chart.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final DBProvider dbProvider = DBProvider();
  DailyLog? dl;

  bool _connected = false;
  bool _discovered = false;
  bool _bleOn = false;
  bool _firstData = false;
  bool _duplicateSync = false;
  String _batteryValue = "";
  String _predictionValue = "";
  int _walkCount = 0;
  int _runCount = 0;
  int _restCount = 0;
  int onLoadTime = todaySinceEpoch();
  int _lastSynced = 0;
  bool _processingBLEData = false;

  BluetoothDevice? device;
  BluetoothCharacteristic? rxPred;
  BluetoothCharacteristic? rxBat;
  BluetoothCharacteristic? tx;
  StreamSubscription? charBatSubscription;
  StreamSubscription? charPredSubscription;
  StreamSubscription? deviceStateSubscription;

  NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadData();

    if (kDebugMode) {
      print("Initializing dashboard page");
    }

    flutterBlue.isOn.then((value) {
      if (mounted) {
        setState(() {
          _bleOn = value;
        });
      }
    });

    startScan();

    flutterBlue.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (kDebugMode) {
          print(r.device.name);
        }

        if (r.device.name == bleName) {
          await flutterBlue.stopScan();
          device = r.device;
          try {
            await device?.connect();

            deviceStateSubscription = device?.state.listen((event) async {
              if (event == BluetoothDeviceState.disconnected) {
                if (kDebugMode) {
                  print("Device disconnected");
                  await handleDisconnect();
                }
                if (mounted) {
                  setState(() {
                    _connected = false;
                  });
                }
                startScan();
              }

              if (event == BluetoothDeviceState.connected) {
                if (kDebugMode) {
                  print("Device connected");
                }
                if (mounted) {
                  setState(() {
                    _connected = true;
                  });
                }
              }
            });

            List<BluetoothService>? services = await device?.discoverServices();

            services?.forEach((service) async {
              if (service.uuid.toString() == serviceUUID.toLowerCase()) {
                if (kDebugMode) {
                  print("Discovering characteristics...");
                }

                var characteristics = service.characteristics;

                for (BluetoothCharacteristic c in characteristics) {
                  if (c.uuid.toString() == rxBatUUID.toLowerCase()) {
                    rxBat = c;
                    await rxBat?.setNotifyValue(true);
                    charBatSubscription = rxBat?.value.listen((value) async {
                      String strData = String.fromCharCodes(value);
                      setState(() {
                        _batteryValue = strData;
                      });
                    });
                  }

                  if (c.uuid.toString() == rxPredUUID.toLowerCase()) {
                    rxPred = c;
                    await rxPred?.setNotifyValue(true);
                    charPredSubscription = rxPred?.value.listen((value) async {
                      final prefs = await SharedPreferences.getInstance();
                      String strData = String.fromCharCodes(value);

                      if (strData.isNotEmpty) {
                        var splitted = strData.split(",");

                        var now = DateTime.now().microsecondsSinceEpoch;

                        if ((now - _lastSynced < 1000 * 30) ||
                            _processingBLEData == true) {
                          return;
                        }
                        _processingBLEData = true;
                        _lastSynced = now;
                        await prefs.setInt('_lastSynced', _lastSynced);

                        if (splitted.length > 2) {
                          _firstData = true;
                          tx?.write("r".codeUnits);
                          if (_duplicateSync == true) {
                            return;
                          }
                          _duplicateSync = true;
                        } else {
                          _duplicateSync = false;
                        }

                        if (onLoadTime < todaySinceEpoch()) {
                          dl = await dateShifted(todaySinceEpoch(), onLoadTime);
                          onLoadTime = todaySinceEpoch();
                          renderPie();
                          await renderWeeklyBar();
                        }

                        List<dynamic> series = json.decode(dl!.series);
                        for (var element in splitted) {
                          if (element.isNotEmpty) {
                            series.add(element);
                          }
                        }

                        dl?.series = json.encode(series);
                        await dbProvider.updateDailyLog(dl!);
                      }
                      _processingBLEData = false;

                      setState(() {
                        _predictionValue = strData;
                      });
                    });
                  }
                  if (c.uuid.toString() == txUUID.toLowerCase()) {
                    tx = c;

                    if (mounted) {
                      setState(() {
                        _discovered = true;
                        if (kDebugMode) {
                          print("Found BLE device");
                        }
                      });
                    }
                  }
                }
              }
            });
          } catch (e) {
            startScan();
          }
        }
      }
    });

    _prefs.then((SharedPreferences prefs) {
      setState(() {
        _walkCount = prefs.getInt('_walkCount') ?? 0;
        _lastSynced = prefs.getInt('_lastSynced') ?? 0;
      });
    });
  }

  void _loadData() async {
    await dbProvider.open("storage.db");

    int todayId = todaySinceEpoch();
    int yesterdayId = yesterdaySinceEpoch();

    dl = await dateShifted(todayId, yesterdayId);

    renderPie();
    await renderWeeklyBar();
  }

  Future<void> renderWeeklyBar() async {
    List<Map<String, Object?>> list =
        await dbProvider.db.rawQuery("Select * from WeeklyLog");

    List<WeeklyActivitySeries> rest = [];
    List<WeeklyActivitySeries> walk = [];
    List<WeeklyActivitySeries> stair = [];
    List<WeeklyActivitySeries> run = [];

    for (var element in list) {
      WeeklyLog w = WeeklyLog.fromMap(element);
      Map jsonlog = json.decode(w.log);
      rest.add(WeeklyActivitySeries(
          type: "Rest",
          count: jsonlog['rest'],
          day: w.day,
          barColor: Colors.grey,
          target: 30));

      walk.add(WeeklyActivitySeries(
          type: "Walk",
          count: jsonlog['walk'],
          day: w.day,
          barColor: Colors.blueAccent,
          target: 30));

      run.add(WeeklyActivitySeries(
          type: "Run",
          count: jsonlog['run'],
          day: w.day,
          barColor: Colors.green,
          target: 30));

      stair.add(WeeklyActivitySeries(
          type: "Stair",
          count: jsonlog['stair'],
          day: w.day,
          barColor: Colors.amber,
          target: 30));
    }

    weeklyData[0] = rest;
    weeklyData[1] = walk;
    weeklyData[2] = run;
    weeklyData[3] = stair;
  }

  Future<DailyLog> dateShifted(int todayId, int yesterdayId) async {
    DailyLog? localdl = await dbProvider.getDailyLog(todayId);

    if (localdl == null) {
      localdl = await dbProvider.insertDailyLog(DailyLog.fromMap({
        'day': dayOfToday(),
        'ts': todayId,
        'ttl': getttl(),
        'log': json.encode({'rest': 0, 'walk': 0, 'run': 0, 'stair': 0}),
        'series': json.encode([]),
        'id': todayId
      }));

      DailyLog? ydl = await dbProvider.getDailyLog(yesterdayId);

      if (ydl != null) {
        await dbProvider.updateWeeklyLog(
            WeeklyLog.fromMap({'day': dayOfYesterday(), 'log': ydl.log}));
      }
    }
    return localdl;
  }

  void renderPie() {
    Map<String, dynamic> dlJson = {'rest': 0, 'walk': 0, 'run': 0, 'stair': 0};
    if (dl != null) {
      dlJson = json.decode(dl!.log);
    }

    pieData = [
      ActivitySeries(
        type: "Rest",
        count: dlJson['rest']!,
        barColor: Colors.grey,
      ),
      ActivitySeries(

        type: "Walk",
        count: dlJson['walk']!,
        barColor: Colors.blueAccent,
      ),
      ActivitySeries(
        type: "Run",
        count: dlJson['run']!,
        barColor: Colors.green,
      ),
      ActivitySeries(
        type: "Stair",
        count: dlJson['stair']!,
        barColor: Colors.amber,
      ),
    ];
  }

  void renderTimeSeries() {
    List<dynamic> series = json.decode(dl!.series);

    for (int i = 0; i < series.length; i++) {
      timeSeries
          .add(ActivityTimeSeries(radius: 2.0, type: series[i], seq: i, ts: 0));
    }
  }

  void startScan() {
    if (kDebugMode) {
      print("starting scan");
    }

    flutterBlue.startScan(
        withServices: [Guid(serviceUUID.toLowerCase())],
        allowDuplicates: false);
  }

  @override
  void deactivate() async {
    super.deactivate();
    await handleDisconnect();
    if (kDebugMode) {
      print("inside deactivate");
    }
  }

  List<ActivitySeries> pieData = [];
  List<List<WeeklyActivitySeries>> weeklyData = [[], [], [], []];
  List<ActivityTimeSeries> timeSeries = [];

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Center(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              if (!_connected)
                const Icon(
                  Icons.warning,
                  color: Colors.red,
                  size: 30,
                ),
              if (_connected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 30,
                ),
              Text("  LAST SYNCED ${formatShortDate(_lastSynced)}    ",
                  style: const TextStyle(fontSize: fontSizeExtraSmall)),
              if (_connected && !_firstData)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.blueGrey,
                  ),
                ),
            ],
          ),
        ),
        DailyActivityChart(
          data: pieData,
        ),
        WeeklyActivityChart(data: weeklyData),
        DailyActivityTimeSeriesChart(data: timeSeries),
        const Text("Live Prediction"),
        Text(
          "$_predictionValue",
          style: const TextStyle(fontSize: fontSizeBig),
        ),
        Center(
          child: ElevatedButton(
            child: const Text('Clear Data'),
            onPressed: () async {
              dl?.log =
                  json.encode({'rest': 0, 'walk': 0, 'run': 0, 'stair': 0});

              await dbProvider.updateDailyLog(dl!);
              // await _notificationService.scheduleNotifications();
              //await _notificationService.showNotifications();
              setState(() {
                renderPie();
              });
            },
          ),
        ),
      ]),
    ));
  }

  Future<void> handleDisconnect() async {
    await charPredSubscription?.cancel();
    await charBatSubscription?.cancel();
    await deviceStateSubscription?.cancel();
    await device?.disconnect();
  }
}
