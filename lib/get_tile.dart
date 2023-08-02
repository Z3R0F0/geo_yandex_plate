import "dart:math";

class MapTileApi {
  static String _getTileUrl(int xTile, int yTile, int zoom) {
    return "https://core-carparks-renderer-lots.maps.yandex.net/maps-rdr-carparks/tiles?l=carparks&x=$xTile&y=$yTile&z=$zoom&scale=2&lang=ru_RU&v=20230802-030100&experimental_data_poi=subscript_zoom_v2_nbsp";
  }

  static String _getMapUrl(int xTile, int yTile, int zoom) {
    return "https://core-renderer-tiles.maps.yandex.net/tiles?l=map&v=23.08.01-0-b230722061630&x=$xTile&y=$yTile&z=$zoom&scale=2&lang=ru_RU&experimental_data_poi=subscript_zoom_v2_nbsp&ads=enabled";
  }

  static Future<MapTileData> getTileData(
      double latitude, double longitude, int zoom) async {
    try {
      List<double> pixelCoords =
          _calculateTileCoordinates(latitude, longitude, zoom);
      if (pixelCoords.isEmpty) {
        return MapTileData.empty();
      } else {
        int xTile = (pixelCoords[0] ~/ 256).toInt();
        int yTile = (pixelCoords[1] ~/ 256).toInt();
        String tileUrl = _getTileUrl(xTile, yTile, zoom);
        String mapUrl = _getMapUrl(xTile, yTile, zoom);
        return MapTileData(
            xTile: xTile, yTile: yTile, tileUrl: tileUrl, mapUrl: mapUrl);
      }
    } catch (e) {
      print("Error occurred during coordinate calculation: $e");
      return MapTileData.empty();
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

class MapTileData {
  final int xTile;
  final int yTile;
  final String tileUrl;
  final String mapUrl;

  MapTileData({
    required this.xTile,
    required this.yTile,
    required this.tileUrl,
    required this.mapUrl,
  });

  factory MapTileData.empty() {
    return MapTileData(xTile: 0, yTile: 0, tileUrl: '', mapUrl: '');
  }
}
