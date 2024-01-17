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

  List<List<String>> mapUrlsMatrix = [];

  List<List<String>> parkingUrlsMatrix = [];

  List<List<List<MapMarker?>>> markersMatrix = [];


  // Обновление данных об изображении тайла карты
  void _updateMapTileData() async {
    if (_zoomLevel != _lastZoomLevel) {
      final coords = _coordinatesController.text.split(",");
      double latitude = double.tryParse(coords[0].trim()) ?? 0.0;
      double longitude = double.tryParse(coords[1].trim()) ?? 0.0;

      // Получение данных о тайле карты через API
      List<MapTileData> mapTileDataList =
      await MapTileApi.getTileData(latitude, longitude, _zoomLevel);
      MapTileData mapTileData = mapTileDataList[0];

      final mapTileMatrix =
      await MapTileApi.getTileMatrixWithMarkers(
          latitude, longitude, _zoomLevel, 4);

      // Обработка данных о тайле карты
      if (mapTileData.parkingUrl.isEmpty) {
        setState(() {
          _tileIsVisible = false;
          _tileUrl = '';
          _mapUrl = '';
        });
      } else {
        setState(() {
          // Проверка размерности матрицы
          if (mapTileMatrix.isNotEmpty && mapTileMatrix[0].isNotEmpty) {
            int numRows = mapTileMatrix.length;
            int numCols = mapTileMatrix[0].length;

            // Обновление матрицы mapUrlsMatrix
            mapUrlsMatrix = List.generate(numRows, (i) {
              return List.generate(numCols, (j) {
                return mapTileMatrix[j][i].mapUrl;
              });
            });

            // Обновление матрицы parkingUrlsMatrix
            parkingUrlsMatrix = List.generate(numRows, (i) {
              return List.generate(numCols, (j) {
                return mapTileMatrix[j][i].parkingUrl;
              });
            });

            markersMatrix = List.generate(numRows, (i) {
              return List.generate(numCols, (j) {
                return mapTileMatrix[j][i].markers ?? <MapMarker?>[];
              });
            });
          }

          _xTile = mapTileMatrix[0][0].xTile;
          _yTile = mapTileMatrix[0][0].yTile;
          _tileUrl = mapTileMatrix[0][0].mapUrl;
          _tileUrl = mapTileMatrix[0][0].parkingUrl;
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

                          Container(
                            height: 1000,
                            width: 1000,
                            child: Stack(
                              children: [
                                // Other widgets in the Stack
                                Positioned.fill(
                                  child: Container(
                                    width: 100,
                                    // Set the width to fill available space
                                    height: 100,
                                    // Set the height to fill available space
                                    child: GridView.builder(
                                      gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: mapUrlsMatrix
                                            .length, // Number of columns in the grid
                                      ),
                                      itemBuilder: (context, index) {
                                        final rowIndex =
                                            index ~/ mapUrlsMatrix.length;
                                        final colIndex =
                                            index % mapUrlsMatrix.length;
                                        return buildSquareMatrix(
                                            mapUrlsMatrix,
                                            markersMatrix)[rowIndex][colIndex];
                                      },
                                      itemCount: mapUrlsMatrix.length *
                                          mapUrlsMatrix.length,
                                    ),
                                  ),
                                ),

                                Visibility(
                                  visible: _tileIsVisible,
                                  child: Positioned.fill(
                                    child: Container(
                                      width: 100,
                                      // Set the width to fill available space
                                      height: 100,
                                      // Set the height to fill available space
                                      child: GridView.builder(
                                        gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: parkingUrlsMatrix
                                              .length, // Number of columns in the grid
                                        ),
                                        itemBuilder: (context, index) {
                                          final rowIndex =
                                              index ~/ parkingUrlsMatrix.length;
                                          final colIndex =
                                              index % parkingUrlsMatrix.length;
                                          return buildSquareMatrix(
                                              parkingUrlsMatrix, [])[rowIndex]
                                          [colIndex];
                                        },
                                        itemCount: parkingUrlsMatrix.length *
                                            parkingUrlsMatrix.length,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  Future<Widget> _loadMapTileImage(String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          final image = await Image
              .memory(
            response.bodyBytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: const Text(
                    'Картинка не найдена',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            },
          )
              .image;
          return Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.red)),
              child: Image(image: image));
        } else {
          return Center(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white),
              child: const Text(
                'Ответ не 200',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }
      } catch (e) {
        print('Error: $e');
        return Center(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white),
            child: const Text(
              'Ошибка :О',
              style: TextStyle(color: Colors.red),
            ),
          ),
        );
      }
    } else {
      return const Center(
        child: Text(
          'Map not found',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  }

  Widget _buildImageContainer(String imageUrl, List<MapMarker?> markers) {
    return SizedBox(
      child: Container(
        width: 20,
        height: 20,
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
                      child: Stack(
                        children: [
                          snapshot.data ?? Container(),
                          // Add markers to the map
                          ...markers.map((marker) {
                            if (marker != null) {
                              return Positioned(
                                left: marker.latitude,
                                top: marker.longitude,
                                child: marker.markerWidget,
                              );
                            } else {
                              return (SizedBox());
                            }
                          }),
                        ],
                      ),
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
            if (imageUrl.isEmpty)
              Container(
                width: 20,
                height: 20,
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }


  List<List<Widget>> buildSquareMatrix(List<List<String>> urlsMatrix,
      List<List<List<MapMarker?>>>? markersMatrix) {
    final size = urlsMatrix.length;
    final squareMatrix = List.generate(
      size,
          (i) =>
          List.generate(
            size,
                (j) {
              if (markersMatrix != null && i < markersMatrix.length &&
                  j < markersMatrix[i].length) {
                return _buildImageContainer(
                    urlsMatrix[i][j], markersMatrix[i][j]);
              } else {
                return _buildImageContainer(urlsMatrix[i][j], []);
              }
            },
          ),
    );
    return squareMatrix;
  }
}