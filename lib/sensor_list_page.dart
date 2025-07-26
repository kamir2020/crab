import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SensorHistoryPage extends StatefulWidget {
  final String deviceID;
  final String deviceName;

  const SensorHistoryPage({
    super.key,
    required this.deviceID,
    required this.deviceName,
  });

  @override
  State<SensorHistoryPage> createState() => _SensorHistoryPageState();
}

class _SensorHistoryPageState extends State<SensorHistoryPage> {

  List history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSensorHistory();
  }

  Future<void> fetchSensorHistory() async {
    final url = Uri.parse(
      'https://my-developments.com/api-crab/get_sensor_history.php?deviceID=${widget.deviceID}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          history = data;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load sensor history");
      }
    } catch (e) {
      print("Error fetching history: $e");
      setState(() => isLoading = false);
    }
  }

  Widget _sensorRow(String label, String value, bool isOutOfRange) {
    return Text(
      "$label: $value",
      style: TextStyle(
        fontSize: 14,
        color: isOutOfRange ? Colors.red : Colors.black,
        fontWeight: isOutOfRange ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  bool _isOutOfRange(String label, double value) {
    switch (label) {
      case 'pH':
        return value < 6.5 || value > 8.5;
      case 'Temp':
        return value < 10 || value > 35;
      case 'Turbidity':
        return value > 5;
      case 'Oxygen':
        return value < 4;
      case 'EC':
        return value > 2000;
      default:
        return false;
    }
  }

  Widget _buildSensorCard(Map d) {
    double ph = double.tryParse(d['ph']) ?? 0;
    double temp = double.tryParse(d['temp']) ?? 0;
    double turbidity = double.tryParse(d['turbidity']) ?? 0;
    double oxygen = double.tryParse(d['oxgen']) ?? 0;
    double ec = double.tryParse(d['ec']) ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📅 ${d['dateCaptured']} 🕒 ${d['timeCaptured']}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            _sensorRow("pH", d['ph'], _isOutOfRange("pH", ph)),
            _sensorRow("Temp (°C)", d['temp'], _isOutOfRange("Temp", temp)),
            _sensorRow("Turbidity (NTU)", d['turbidity'], _isOutOfRange("Turbidity", turbidity)),
            _sensorRow("Oxygen (mg/L)", d['oxgen'], _isOutOfRange("Oxygen", oxygen)),
            _sensorRow("EC (µS/cm)", d['ec'], _isOutOfRange("EC", ec)),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History: ${widget.deviceName}'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
          ? const Center(child: Text("No history found"))
          : ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) =>
            _buildSensorCard(history[index]),
      ),
    );
  }
}
