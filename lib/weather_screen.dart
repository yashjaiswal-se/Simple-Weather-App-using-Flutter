import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:weather_app/hourly_forecast_item.dart';
import 'package:weather_app/additional_item.dart';
import 'package:weather_app/secrets.dart'; // where your apiKey lives

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> weatherFuture;

  @override
  void initState() {
    super.initState();
    weatherFuture = getWeatherData();
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied';
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<Map<String, dynamic>> getWeatherData() async {
    try {
      final position = await _getCurrentPosition();
      final lat = position.latitude;
      final lon = position.longitude;

      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw 'Error fetching weather data';
      }
    } catch (e) {
      throw 'Error: $e';
    }
  }

  Widget buildWeatherUI(Map<String, dynamic> data) {
    final current = data['list'][0];
    final currentTemp = current['main']['temp'];
    final weatherMain = current['weather'][0]['main'];
    final iconCode = current['weather'][0]['icon'];
    final humidity = current['main']['humidity'].toString();
    final pressure = current['main']['pressure'].toString();
    final windSpeed = current['wind']['speed'].toString();

    final now = DateTime.now();
    final List allHours = data['list'];
    final upcomingHours =
        allHours
            .where((entry) {
              final entryTime = DateTime.parse(entry['dt_txt']);
              return entryTime.isAfter(now);
            })
            .take(6)
            .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Main Weather Card
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$currentTemp°C",
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Image.network(
                      'https://openweathermap.org/img/wn/$iconCode@2x.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      weatherMain,
                      style: const TextStyle(fontSize: 22, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Hourly Forecast",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 150,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    upcomingHours.map((hour) {
                      final time = hour['dt_txt'].substring(11, 16);
                      final temp = hour['main']['temp'].toString();
                      final icon = hour['weather'][0]['icon'];
                      return HourlyForecastItem(
                        time: time,
                        icon: Image.network(
                          'https://openweathermap.org/img/wn/$icon@2x.png',
                          width: 50,
                          height: 50,
                        ),
                        temperature: "$temp°C",
                      );
                    }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Additional Information",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AdditionalItem(
                  icon: Icons.water_drop,
                  label: "Humidity",
                  value: humidity,
                ),
                AdditionalItem(
                  icon: Icons.air,
                  label: "Wind Speed",
                  value: windSpeed,
                ),
                AdditionalItem(
                  icon: Icons.beach_access,
                  label: "Pressure",
                  value: pressure,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Weather App",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                weatherFuture = getWeatherData();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: weatherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return buildWeatherUI(snapshot.data!);
          }
        },
      ),
    );
  }
}
