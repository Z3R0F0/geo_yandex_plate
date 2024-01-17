import "dart:math";
import "package:flutter/material.dart";
import "package:geo_yandex_plate/models/map_tile_data.dart";
import 'package:intl/intl.dart';


class MapMarker {
  final double latitude;
  final double longitude;
  final Widget markerWidget;

  MapMarker({
    required this.latitude,
    required this.longitude,
    required this.markerWidget,
  });
}


class FormattedDate {
  static String getYesterdayDate() {
    DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
    String formattedDate = DateFormat('yyyyMMdd').format(yesterday);
    return formattedDate;
  }
}

class MapTileApi extends FormattedDate {
  static String _getParkingTileUrl(int xTile, int yTile, int zoom) {
    String formattedDate = FormattedDate.getYesterdayDate();
    return "https://core-carparks-renderer-lots.maps.yandex.net/maps-rdr-carparks/tiles?l=carparks&x=$xTile&y=$yTile&z=$zoom&scale=2&lang=ru_RU&v=20240117-053300&experimental_data_poi=subscript_zoom_v2_nbsp";
  }

  static String _getMapTileUrl(int xTile, int yTile, int zoom) {
    String formattedDate = FormattedDate.getYesterdayDate();
    return "https://core-renderer-tiles.maps.yandex.net/tiles?l=map&v=$formattedDate-b230722061630&x=$xTile&y=$yTile&z=$zoom&scale=2&lang=ru_RU&experimental_data_poi=subscript_zoom_v2_nbsp&ads=enabled";
  }

  static Future<List<MapTileData>> getTileDataWithMarkers(
      double latitude, double longitude, int zoom) async {
    try {
      List<double> pixelCoords = _calculateTileCoordinates(latitude, longitude, zoom);
      if (pixelCoords.isEmpty) {
        return [MapTileData.empty()];
      } else {
        int xTile = (pixelCoords[0] ~/ 256).toInt();
        int yTile = (pixelCoords[1] ~/ 256).toInt();
        String tileUrl = _getParkingTileUrl(xTile, yTile, zoom);
        String mapUrl = _getMapTileUrl(xTile, yTile, zoom);

        // Calculate marker positions within the tile.
        List<MapMarker> markers = [
          MapMarker(
            latitude: 55.759664, // Use the specified latitude
            longitude: 37.617761, // Use the specified longitude
            markerWidget: Container(
              height: 10,
              width: 10,
              color: Colors.red,
            ), // Create a custom marker widget.
          ),
        ];

        return [
          MapTileData(
            xTile: xTile,
            yTile: yTile,
            parkingUrl: tileUrl,
            mapUrl: mapUrl,
            markers: markers,
          ),
        ];
      }
    } catch (e) {
      print("Error occurred during coordinate calculation: $e");
      return [MapTileData.empty()];
    }
  }


  static Future<List<List<MapTileData>>> getTileMatrix(
      double latitude, double longitude, int zoom, int n) async {
    try {
      List<List<MapTileData>> tileMatrix = [];
      List<double> pixelCoords =
      _calculateTileCoordinates(latitude, longitude, zoom);

      if (pixelCoords.isEmpty) {
        return [[MapTileData.empty()]];
      } else {
        int centralXTile = (pixelCoords[0] ~/ 256).toInt();
        int centralYTile = (pixelCoords[1] ~/ 256).toInt();

        for (int i = -n ~/ 2; i <= n ~/ 2; i++) {
          List<MapTileData> row = [];

          for (int j = -n ~/ 2; j <= n ~/ 2; j++) {
            int xTile = centralXTile + i;
            int yTile = centralYTile + j;

            String tileUrl = _getParkingTileUrl(xTile, yTile, zoom);
            String mapUrl = _getMapTileUrl(xTile, yTile, zoom);

            row.add(
              MapTileData(
                xTile: xTile,
                yTile: yTile,
                parkingUrl: tileUrl,
                mapUrl: mapUrl,
              ),
            );
          }

          tileMatrix.add(row);
        }

        return tileMatrix;
      }
    } catch (e) {
      print("Error occurred during coordinate calculation: $e");
      return [[MapTileData.empty()]];
    }
  }

  static Future<List<List<MapTileData>>> getTileMatrixWithMarkers(
      double latitude, double longitude, int zoom, int n) async {
    try {
      List<List<MapTileData>> tileMatrix = [];
      List<double> pixelCoords = _calculateTileCoordinates(latitude, longitude, zoom);

      if (pixelCoords.isEmpty) {
        return [[MapTileData.empty()]];
      } else {
        int centralXTile = (pixelCoords[0] ~/ 256).toInt();
        int centralYTile = (pixelCoords[1] ~/ 256).toInt();

        for (int i = -n ~/ 2; i <= n ~/ 2; i++) {
          List<MapTileData> row = [];

          for (int j = -n ~/ 2; j <= n ~/ 2; j++) {
            int xTile = centralXTile + i;
            int yTile = centralYTile + j;

            String tileUrl = _getParkingTileUrl(xTile, yTile, zoom);
            String mapUrl = _getMapTileUrl(xTile, yTile, zoom);

            // Calculate marker positions within the tile.
            List<MapMarker> markers = [
              MapMarker(
                latitude: 55.760281,
                longitude: 37.613663,
                markerWidget: Container(height: 10, width: 10, color: Colors.red,),
              ),
              // Add more markers as needed.
            ];

            row.add(
              MapTileData(
                xTile: xTile,
                yTile: yTile,
                parkingUrl: tileUrl,
                mapUrl: mapUrl,
                markers: markers,
              ),
            );
          }

          tileMatrix.add(row);
        }

        return tileMatrix;
      }
    } catch (e) {
      print("Error occurred during coordinate calculation: $e");
      return [[MapTileData.empty()]];
    }
  }



  static Future<List<MapTileData>> getTileData(
      double latitude, double longitude, int zoom) async {
    try {
      List<double> pixelCoords =
      _calculateTileCoordinates(latitude, longitude, zoom);
      if (pixelCoords.isEmpty) {
        return [MapTileData.empty()];
      } else {
        int xTile = (pixelCoords[0] ~/ 256).toInt();
        int yTile = (pixelCoords[1] ~/ 256).toInt();
        String tileUrl = _getParkingTileUrl(xTile, yTile, zoom);
        String mapUrl = _getMapTileUrl(xTile, yTile, zoom);
        return [
          MapTileData(
            xTile: xTile,
            yTile: yTile,
            parkingUrl: tileUrl,
            mapUrl: mapUrl,
          ),
        ];
      }
    } catch (e) {
      print("Error occurred during coordinate calculation: $e");
      return [MapTileData.empty()];
    }
  }

  static List<double> _calculateTileCoordinates(
      double lat, double lon, int zoom) {
    try {
      double x_p, y_p;
      List<double> pixelCoords = [];
      double rho;
      double beta, phi, theta;
      double e = 0.0818191908426; // eccentricity of wgs84Mercator

      rho = pow(2, zoom + 8) / 2;
      beta = lat * pi / 180;
      phi = (1 - e * sin(beta)) / (1 + e * sin(beta));
      theta = tan(pi / 4 + beta / 2) * pow(phi, e / 2);

      x_p = rho * (1 + lon / 180);
      y_p = rho * (1 - log(theta) / pi);

      pixelCoords.add(x_p);
      pixelCoords.add(y_p);

      return pixelCoords;
    } catch (e) {
      print("Error occurred during coordinate calculation: $e");
      return [];
    }
  }
}

