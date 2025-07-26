import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_crab/sensor_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ScreenDashboard extends StatefulWidget {
  _ScreenDashboard createState() => _ScreenDashboard();
}

class _ScreenDashboard extends State<ScreenDashboard> {

  List devices = [];
  bool isLoading = true;
  Timer? _autoRefreshTimer; // ✅ auto-refresh timer

  int totalDevices = 0;
  int onlineCount = 0;
  int offlineCount = 0;
  int outOfRangeCount = 0;
  String lastUpdatedTime = '-';

  @override
  void initState() {
    super.initState();
    fetchDevicesWithSensors();

    _autoRefreshTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      fetchDevicesWithSensors();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchDevicesWithSensors({bool showSnackbar = false}) async {
    final url = Uri.parse('https://my-developments.com/api-crab/get-devices.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        String? latestTimestamp;

        int online = 0, offline = 0, warning = 0;

        for (var d in data) {
          bool isOffline = d['status'] == 'Offline';

          double turbidity = double.tryParse(d['turbidity']) ?? 0;
          double temp = double.tryParse(d['temp']) ?? 0;
          double ph = double.tryParse(d['ph']) ?? 0;
          double ox = double.tryParse(d['oxgen']) ?? 0;
          double ec = double.tryParse(d['ec']) ?? 0;

          bool out = ph < 6.5 || ph > 8.5 || temp < 10 || temp > 35 || ox < 4 || turbidity > 5 || ec > 2000;

          if (isOffline) {
            offline++;
          } else {
            online++;
          }

          if (out) warning++;

          String combined = '${d['dateCaptured']} ${d['timeCaptured']}';
          if (latestTimestamp == null || combined.compareTo(latestTimestamp) > 0) {
            latestTimestamp = combined;
          }
        }

        setState(() {
          devices = data;
          totalDevices = data.length;
          onlineCount = online;
          offlineCount = offline;
          outOfRangeCount = warning;
          lastUpdatedTime = latestTimestamp ?? '-';
          isLoading = false;
        });

        // ✅ Show snackbar if auto-refresh or triggered manually
        if (showSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Device list auto-refreshed"),
              duration: Duration(seconds: 2),
            ),
          );
        }

      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Widget _rowStat(IconData icon, String label, int count, Color color, double percent) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count (${percent.toStringAsFixed(0)}%)',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardHeaderRow() {
    double toPercent(int count) =>
        totalDevices == 0 ? 0 : (count / totalDevices) * 100;

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _rowStat(Icons.devices, 'Total', totalDevices, Colors.blue, 100),
                _rowStat(Icons.wifi, 'Online', onlineCount, Colors.green, toPercent(onlineCount)),
                _rowStat(Icons.wifi_off, 'Offline', offlineCount, Colors.red, toPercent(offlineCount)),
                _rowStat(Icons.warning_amber, 'Warning', outOfRangeCount, Colors.orange, toPercent(outOfRangeCount)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Last Update: $lastUpdatedTime',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _sensorText(String label, String value, bool outOfRange) {
    return Text(
      '$label: $value',
      style: TextStyle(
        color: outOfRange ? Colors.red : Colors.black,
        fontWeight: outOfRange ? FontWeight.bold : FontWeight.normal,
        fontSize: 14,
      ),
    );
  }

  Widget buildDeviceCard(Map d) {
    double turbidity = double.tryParse(d['turbidity']) ?? 0;
    double temp = double.tryParse(d['temp']) ?? 0;
    double ph = double.tryParse(d['ph']) ?? 0;
    double ox = double.tryParse(d['oxgen']) ?? 0;
    double ec = double.tryParse(d['ec']) ?? 0;

    bool turbOut = turbidity > 5;
    bool tempOut = temp < 10 || temp > 35;
    bool phOut = ph < 6.5 || ph > 8.5;
    bool oxOut = ox < 4;
    bool ecOut = ec > 2000;

    bool anyOut = turbOut || tempOut || phOut || oxOut || ecOut;
    bool isOffline = d['status'] == 'Offline';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isOffline
          ? Colors.red.shade50
          : anyOut
          ? Colors.orange.shade50
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${d['deviceName']} (${d['deviceID']})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Location: ${d['deviceLocation']}'),
            const SizedBox(height: 4),
            Text('📅 ${d['dateCaptured']} ${d['timeCaptured']}'),
            const SizedBox(height: 8),
            _sensorText('🌊 Turbidity', '${d['turbidity']} NTU', turbOut),
            _sensorText('🌡️ Temp', '${d['temp']} °C', tempOut),
            _sensorText('⚗️ pH', '${d['ph']}', phOut),
            _sensorText('💧 Oxygen', '${d['oxgen']} mg/L', oxOut),
            _sensorText('⚡ EC', '${d['ec']} µS/cm', ecOut),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    d['status'],
                    style: TextStyle(
                      color: isOffline ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: isOffline
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                ),
                if (anyOut)
                  Chip(
                    label: const Text(
                      "⚠️ Out of Range",
                      style: TextStyle(color: Colors.orange),
                    ),
                    backgroundColor: Colors.orange.shade100,
                  ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.history, size: 16,color: Colors.white,),
                  label: const Text("History",style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SensorHistoryPage(
                          deviceID: d['deviceID'],
                          deviceName: d['deviceName'],
                        ),
                      ),
                    );
                  },
                ),
              ],
            )

          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Device List",
        style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),), backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh,color: Colors.white,),
            tooltip: 'Refresh',
            onPressed: () {
              fetchDevicesWithSensors(showSnackbar: true); // manual refresh with snackbar
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app,color: Colors.white,),
            tooltip: 'Exit App',
            onPressed: () {
              exit(0); // Force close the app
              // OR: SystemNavigator.pop(); // Softer exit
            },
          ),
        ],),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : devices.isEmpty
          ? const Center(child: Text("No data found"))
          : Column(
        children: [
          _buildDashboardHeaderRow(),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) =>
                  buildDeviceCard(devices[index]),
            ),
          ),
        ],
      ),
    );
  }

}

