import '../api/map_tile_api.dart';

class MapTileData {
  final int xTile;
  final int yTile;
  final String parkingUrl;
  final String mapUrl;
  final List<MapMarker>? markers;

  MapTileData({
    required this.xTile,
    required this.yTile,
    required this.parkingUrl,
    required this.mapUrl,
    this.markers,
  });

  factory MapTileData.empty() {
    return MapTileData(xTile: 0, yTile: 0, parkingUrl: '', mapUrl: '');
  }
}