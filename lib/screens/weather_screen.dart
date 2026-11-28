import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _cityController =
      TextEditingController(text: 'Da Lat');

  // Thay API Key 
  static const String _apiKey = 'b4d2173cc3da567f140adccf3ba3dbd9';

  bool _isLoading = false;
  String? _cityName;
  double? _temp;
  int? _humidity;
  String? _description;
  String? _outfitSuggestion;
  String? _errorMessage;

  String _buildOutfitSuggestion(double temp, String desc) {
    final lowerDesc = desc.toLowerCase();
    if (lowerDesc.contains('mưa') || lowerDesc.contains('rain')) {
      return 'Nên mang áo mưa/ô gấp và giày chống trơn trượt.';
    }
    if (temp <= 20) {
      return 'Trời se lạnh/mát: nên mặc áo khoác ấm, quần dài và mang khăn nhẹ.';
    } else if (temp <= 28) {
      return 'Thời tiết dễ chịu: phù hợp áo thun, quần jeans/kaki và giày thể thao.';
    } else {
      return 'Trời khá nắng/nóng: nên chọn áo thoáng mát, mũ rộng vành, kính râm và kem chống nắng.';
    }
  }

  Future<void> _searchWeather() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập tên thành phố du lịch.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Nếu chưa thay API Key thật, hiển thị dữ liệu mẫu để test ngay không lỗi
    if (_apiKey == 'THAY_API_KEY_OPENWEATHERMAP' || _apiKey.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      const demoTemp = 19.5;
      const demoDesc = 'mát mẻ, có mây nhẹ (chế độ mẫu - chưa gắn API Key)';
      setState(() {
        _cityName = city;
        _temp = demoTemp;
        _humidity = 78;
        _description = demoDesc;
        _outfitSuggestion = _buildOutfitSuggestion(demoTemp, demoDesc);
        _isLoading = false;
      });
      return;
    }

    try {
      final uri = Uri.https(
        'api.openweathermap.org',
        '/data/2.5/weather',
        {
          'q': city,
          'appid': _apiKey,
          'units': 'metric',
          'lang': 'vi',
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final mainData = data['main'] as Map<String, dynamic>? ?? {};
        final weatherList = data['weather'] as List<dynamic>? ?? [];
        final firstWeather = weatherList.isNotEmpty
            ? weatherList.first as Map<String, dynamic>
            : <String, dynamic>{};

        final double tempVal = ((mainData['temp'] ?? 0) as num).toDouble();
        final int humidityVal = ((mainData['humidity'] ?? 0) as num).toInt();
        final String descVal =
            (firstWeather['description'] ?? 'Không rõ').toString();

        setState(() {
          _cityName = (data['name'] ?? city).toString();
          _temp = tempVal;
          _humidity = humidityVal;
          _description = descVal;
          _outfitSuggestion = _buildOutfitSuggestion(tempVal, descVal);
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage =
              'API Key không hợp lệ hoặc chưa được kích hoạt (mã lỗi 401).';
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage =
              'Không tìm thấy địa điểm "$city". Hãy thử nhập không dấu (VD: Da Lat, Can Tho, Ha Noi).';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Không thể lấy dữ liệu thời tiết (mã lỗi ${response.statusCode}).';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối mạng hoặc hết thời gian chờ: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _searchWeather();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tra cứu Thời tiết Du lịch'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _cityController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchWeather(),
              decoration: const InputDecoration(
                labelText: 'Tên thành phố (VD: Da Lat, Nha Trang, Can Tho)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _searchWeather,
              icon: const Icon(Icons.search),
              label: const Text('Tra cứu thời tiết'),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              )
            else if (_cityName != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Địa điểm: $_cityName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Nhiệt độ: ${_temp?.toStringAsFixed(1)}°C'),
                      Text('Độ ẩm: $_humidity%'),
                      Text('Tình trạng: $_description'),
                      const Divider(height: 20),
                      const Text(
                        'Gợi ý trang phục:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(_outfitSuggestion ?? ''),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}