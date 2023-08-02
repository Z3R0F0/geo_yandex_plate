import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../bloc/geoposition_bloc.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_form_field.dart';
import '../models/map_tile_data.dart';
import '../api/map_tile_api.dart';
import 'package:http/http.dart' as http;

class GeopositionPage extends StatefulWidget {
  @override
  _GeopositionPageState createState() => _GeopositionPageState();
}

class _GeopositionPageState extends State<GeopositionPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _coordinatesController = TextEditingController();
  int _xTile = 0;
  int _yTile = 0;
  String _tileUrl = '';
  String _mapUrl = '';
  bool _tileIsVisible = false;
  int _zoomLevel = 14;
  int _lastZoomLevel = 0;

  // Обновление данных об изображении тайла карты
  void _updateMapTileData() async {
    if (_zoomLevel != _lastZoomLevel) {
      final coords = _coordinatesController.text.split(",");
      double latitude = double.tryParse(coords[0].trim()) ?? 0.0;
      double longitude = double.tryParse(coords[1].trim()) ?? 0.0;

      // Получение данных о тайле карты через API
      MapTileData mapTileData =
          await MapTileApi.getTileData(latitude, longitude, _zoomLevel);

      // Обработка данных о тайле карты
      if (mapTileData.tileUrl.isEmpty) {
        setState(() {
          _tileIsVisible = false;
          _tileUrl = '';
          _mapUrl = '';
        });
      } else {
        setState(() {
          _tileIsVisible = true;
          _xTile = mapTileData.xTile;
          _yTile = mapTileData.yTile;
          _tileUrl = mapTileData.tileUrl;
          _mapUrl = mapTileData.mapUrl;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final GeopositionBloc bloc = BlocProvider.of<GeopositionBloc>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CustomTextFormField(
                  controller: _coordinatesController,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter latitude and longitude';
                    }

                    if (!RegExp(r'\d+(\.\d+)?, \d+(\.\d+)?').hasMatch(value)) {
                      return 'Invalid format. Use "latitude, longitude".';
                    }

                    final latitude_longitude = value.split(",");
                    double latitude =
                        double.tryParse(latitude_longitude[0].trim()) ?? 0.0;
                    double longitude =
                        double.tryParse(latitude_longitude[1].trim()) ?? 0.0;

                    if (latitude < -90 || latitude > 90) {
                      return 'Latitude must be between -90 and 90 degrees';
                    }

                    if (longitude < -180 || longitude > 180) {
                      return 'Longitude must be between -180 and 180 degrees';
                    }

                    return null;
                  },
                  labelText: 'Latitude, Longitude',
                ),
                const Text(
                  'Zoom slider',
                  style: TextStyle(color: Colors.white),
                ),
                Slider(
                  value: _zoomLevel.toDouble(),
                  min: 14,
                  max: 20,
                  divisions: 6,
                  onChangeStart: (value) {},
                  onChangeEnd: (value) {
                    if (_zoomLevel != _lastZoomLevel) {
                      setState(() {
                        _zoomLevel = value.round();
                      });
                      _updateMapTileData();
                    }
                  },
                  onChanged: (value) {},
                  activeColor:
                      Colors.white, // Устанавливаем белый цвет для ползунка
                ),
                CustomButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _updateMapTileData();
                      bloc.updateIsFound(true); // Обновляем состояние блока
                    }
                  },
                  text: 'Calculate', // Кнопка для запуска расчета
                ),
                BlocBuilder<GeopositionBloc, Map<String, bool>>(
                  builder: (context, state) {
                    final isFound = state['isFound']!;
                    if (isFound) {
                      // Выводим контент, если геопозиция найдена
                      return Column(
                        children: [
                          CustomButton(
                            onPressed: () {
                              setState(() {
                                _tileIsVisible = !_tileIsVisible;
                              });
                            },
                            text:
                                'Toggle Parking', // Кнопка для переключения видимости тайла
                          ),
                          Stack(
                            children: [
                              _buildImageContainer(_mapUrl),
                              // Отображение карты
                              Visibility(
                                visible: _tileIsVisible,
                                child: _buildImageContainer(
                                    _tileUrl), // Отображение тайла
                              )
                            ],
                          ),
                          SizedBox(height: 10),
                          CustomButton(
                            onPressed: () {
                              if (_mapUrl.isNotEmpty) {
                                Clipboard.setData(ClipboardData(text: _mapUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Map URL copied to clipboard!')), // Сообщение о копировании URL карты
                                );
                              }
                            },
                            text:
                                'Copy Map URL', // Кнопка для копирования URL карты
                          ),
                          CustomButton(
                            onPressed: () {
                              if (_tileUrl.isNotEmpty) {
                                Clipboard.setData(
                                    ClipboardData(text: _tileUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Tile URL copied to clipboard!')),
                                );
                              }
                            },
                            text: 'Copy Parking URL',
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Tile X: $_xTile, Tile Y: $_yTile',
                            style: TextStyle(color: Colors.white),
                          ), // Выводим координаты тайла
                        ],
                      );
                    } else {
                      return SizedBox();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Загрузка изображения тайла карты по URL
  Future<Widget> _loadMapTileImage(String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final image = await Image.memory(
            response.bodyBytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Text(
                  'Image not found',
                  // Выводим сообщение об ошибке загрузки изображения
                  style: TextStyle(color: Colors.red),
                ),
              );
            },
          ).image;
          return Image(image: image);
        } else {
          // Обработка ошибки загрузки изображения с сервера
          return const Center(
            child: Text(
              'Error loading image',
              // Выводим сообщение об ошибке загрузки изображения
              style: TextStyle(color: Colors.red),
            ),
          );
        }
      } catch (e) {
        // Обработка неожиданных исключений, включая ImageCodecException
        print('Error loading image: $e');
        return const Center(
          child: Text(
            'Error loading image',
            // Выводим сообщение об ошибке загрузки изображения
            style: TextStyle(color: Colors.red),
          ),
        );
      }
    } else {
      return const Center(
        child: Text(
          'Map not found', // Выводим сообщение, если URL карты пустой
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  }

// Виджет для отображения контейнера с изображением
  Widget _buildImageContainer(String imageUrl) {
    return SizedBox(
      height: 300,
      // Устанавливаем фиксированную высоту, чтобы предотвратить изменение размеров
      child: Container(
        width: MediaQuery.of(context).size.height -
            MediaQuery.of(context).size.height / 30,
        decoration: BoxDecoration(
          color: imageUrl.contains('map')
              ? Colors.white
              : Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          backgroundBlendMode: BlendMode.multiply,
        ),
        child: Stack(
          children: [
            Center(
              child: FutureBuilder<Widget>(
                future: _loadMapTileImage(imageUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      imageUrl.contains('map')) {
                    return AnimatedOpacity(
                      opacity: snapshot.hasData ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 300),
                      child: snapshot.data ?? Container(),
                    );
                  } else {
                    return const SizedBox(
                      width: 50,
                      height: 50,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                },
              ),
            ),
            if (imageUrl
                .isEmpty) // Показываем черный квадрат, если URL изображения пустой
              Container(
                color: Colors.black,
                width: double.infinity,
                height: double.infinity,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
