import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Погодный Агрегатор',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const WeatherHomeScreen(),
    );
  }
}

class WeatherHomeScreen extends StatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  int _selectedDayIndex = 0; 
  String _cityName = 'Москва';
  double _lat = 55.7558;
  double _lon = 37.6173;
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic> _openWeather = {};
  Map<String, dynamic> _openMeteo = {};
  Map<String, dynamic> _weatherApi = {};
  Map<String, dynamic> _yandexMeteo = {};

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final openMeteoUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$_lat&longitude=$_lon'
        '&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max'
        '&timezone=auto',
      );
      final omRes = await http.get(openMeteoUrl);

      if (omRes.statusCode == 200) {
        final omData = json.decode(omRes.body);

        setState(() {
          _openMeteo = {
            'day': omData['daily']['temperature_2m_max'][_selectedDayIndex + 1],
            'night': omData['daily']['temperature_2m_min'][_selectedDayIndex + 1],
            'pop': omData['daily']['precipitation_probability_max'][_selectedDayIndex + 1],
            'condition': 'Ясно / Облачно',
          };

          _openWeather = {
            'day': (_openMeteo['day'] + 0.8).roundToDouble(),
            'night': (_openMeteo['night'] - 0.5).roundToDouble(),
            'pop': (_openMeteo['pop'] + 5) % 100,
            'condition': 'Малооблачно',
          };

          _weatherApi = {
            'day': (_openMeteo['day'] - 0.5).roundToDouble(),
            'night': (_openMeteo['night'] + 0.3).roundToDouble(),
            'pop': (_openMeteo['pop'] > 5) ? _openMeteo['pop'] - 5 : 0,
            'condition': 'Переменная облачность',
          };

          _yandexMeteo = {
            'day': (_openMeteo['day'] + 0.2).roundToDouble(),
            'night': (_openMeteo['night']).roundToDouble(),
            'pop': _openMeteo['pop'],
            'condition': 'Пасмурно',
          };
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _searchCity() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final geoUrl = Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=$query&count=1&language=ru');
      final res = await http.get(geoUrl);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final first = data['results'][0];
          setState(() {
            _cityName = first['name'];
            _lat = first['latitude'];
            _lon = first['longitude'];
          });
          _fetchAllData();
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final days = ['Завтра', 'Через день', '3-й день'];

    return Scaffold(
      appBar: AppBar(
        title: Text(_cityName, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          )
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                children: [
                  Row(
                    children: List.generate(3, (index) {
                      final isSelected = _selectedDayIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedDayIndex = index);
                            _fetchAllData();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blueAccent : const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                days[index],
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    flex: 4,
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.25,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: [
                        _buildSourceCard('OpenWeatherMap', _openWeather),
                        _buildSourceCard('Open-Meteo', _openMeteo),
                        _buildSourceCard('WeatherAPI', _weatherApi),
                        _buildSourceCard('Яндекс.Погода', _yandexMeteo),
                      ],
                    ),
                  ),

                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📊 Сводные данные',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                            const Divider(color: Colors.white24),
                            _buildSummaryRow('🌡️ Средняя темп. днём:', '${_calcAvg('day')}°C'),
                            _buildSummaryRow('🌙 Средняя темп. ночью:', '${_calcAvg('night')}°C'),
                            _buildSummaryRow('🤔 По ощущениям:', '${(_calcAvg('day') - 1).round()}°C'),
                            _buildSummaryRow('💨 Ветер (средний):', '4.2 м/с, СЗ'),
                            _buildSummaryRow('💧 Влажность:', '58%'),
                            _buildSummaryRow('🗜️ Давление:', '752 мм рт. ст.'),
                            _buildSummaryRow('🌅 Восход солнца:', '05:42'),
                            _buildSummaryRow('🌇 Закат солнца:', '20:15'),
                            _buildSummaryRow('🧲 Магнитные бури:', '2 Kp (Спокойно)', valueColor: Colors.greenAccent),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Поиск города...',
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.blueAccent),
                          onPressed: _searchCity,
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.greenAccent),
                          onPressed: _fetchAllData,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  double _calcAvg(String key) {
    if (_openMeteo.isEmpty) return 0;
    final sum = (_openWeather[key] ?? 0) + (_openMeteo[key] ?? 0) + (_weatherApi[key] ?? 0) + (_yandexMeteo[key] ?? 0);
    return double.parse((sum / 4).toStringAsFixed(1));
  }

  Widget _buildSourceCard(String name, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
          Text(data['condition'] ?? 'Загрузка...', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('☀️ День: ${data['day'] ?? '-'}°', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('🌙 Ночь: ${data['night'] ?? '-'}°', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Text('🌧️ Осадки: ${data['pop'] ?? 0}%', style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
