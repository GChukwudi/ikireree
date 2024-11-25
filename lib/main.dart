import 'package:flutter/material.dart';
// convert the main function to async
import 'dart:convert';
// import the http package to make HTTP requests
import 'package:http/http.dart' as http;
// import the provider package to use ChangeNotifier
import 'package:provider/provider.dart';

class Weather {
  // define the properties of the Weather class
  final double temperature;
  final String description;
  final double humidity;
  final double windSpeed;
  final String icon;

  // create a constructor for the Weather class
  Weather({
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
  });

  // create a factory method to convert the JSON data to a Weather object
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'],
      humidity: (json['main']['humidity'] as num).toDouble(),
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      icon: json['weather'][0]['icon'],
    );
  }
}

// create a WeatherService class to fetch weather data
class WeatherService {
  final String apiKey = '7d83a6f1dfbf88feaa22ac24dd124785';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // create a method to fetch the current weather data
  Future<Weather> getCurrentWeather(String city) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather?q=$city&appid=$apiKey&units=metric'),
    );

    // check if the response status code is 200 OK
    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  // create a method to fetch the 5-day forecast data
  Future<List<Weather>> getForecast(String city) async {
    final response = await http.get(
      Uri.parse('$baseUrl/forecast?q=$city&appid=$apiKey&units=metric'),
    );

    // check if the response status code is 200 OK
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Weather> forecast = [];
      for (var item in data['list']) {
        forecast.add(Weather.fromJson(item));
      }
      return forecast;
    } else {
      throw Exception('Failed to load forecast data');
    }
  }
}

// create a WeatherProvider class to manage the weather data
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE0E0E0),
        title: const Text('Weather App',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Consumer<WeatherProvider>(
        // use the Consumer widget to access the WeatherProvider
        builder: (context, weatherProvider, child) {
          if (weatherProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // get the current weather data from the WeatherProvider
          final weather = weatherProvider.currentWeather;
          if (weather == null) {
            return const Center(child: Text('No weather data available'));
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weatherProvider.selectedCity,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Image.network(
                  'https://openweathermap.org/img/wn/${weather.icon}@2x.png',
                  width: 100,
                  height: 100,
                ),
                Text(
                  '${weather.temperature.round()}°C',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text(
                  weather.description,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/forecast'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    backgroundColor: const Color(0xFFE0E0E0),
                  ),
                  child: const Text(
                    'View 5-Day Forecast',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xff404040),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// create a ForecastScreen widget to display the 5-day forecast
class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE0E0E0),
        title: const Text(
          '5-Day Forecast',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          if (weatherProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: weatherProvider.forecast.length,
            itemBuilder: (context, index) {
              final weather = weatherProvider.forecast[index];
              return ListTile(
                leading: Image.network(
                  'https://openweathermap.org/img/wn/${weather.icon}.png',
                ),
                title: Text('${weather.temperature.round()}°C'),
                subtitle: Text(weather.description),
                trailing: Text('${weather.humidity}% humidity'),
              );
            },
          );
        },
      ),
    );
  }
}

// create a SettingsScreen widget to update the city
class SettingsScreen extends StatelessWidget {
  final TextEditingController _cityController = TextEditingController();

  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE0E0E0),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Enter a City Name',
                labelStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_cityController.text.isNotEmpty) {
                  context
                      .read<WeatherProvider>()
                      .updateCity(_cityController.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                backgroundColor: const Color(0xFFE0E0E0),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Update City',
                  style: TextStyle(fontSize: 16, color: Color(0xff404040))),
            ),
          ],
        ),
      ),
    );
  }
}

// create a WeatherProvider class to manage the weather data
class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  Weather? _currentWeather;
  List<Weather> _forecast = [];
  String _selectedCity = 'Vancouver';
  bool _isLoading = false;

  Weather? get currentWeather => _currentWeather;
  List<Weather> get forecast => _forecast;
  String get selectedCity => _selectedCity;
  bool get isLoading => _isLoading;

  Future<void> updateCity(String city) async {
    _selectedCity = city;
    await fetchWeatherData();
  }

  Future<void> fetchWeatherData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentWeather = await _weatherService.getCurrentWeather(_selectedCity);
      _forecast = await _weatherService.getForecast(_selectedCity);
    } catch (e) {
      (_currentWeather = null);
    }

    _isLoading = false;
    notifyListeners();
  }
}

// lib/main.dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WeatherProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/forecast': (context) => const ForecastScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}
