class MapTileData {
  final int xTile;
  final int yTile;
  final String parkingUrl;
  final String mapUrl;

  MapTileData({
    required this.xTile,
    required this.yTile,
    required this.parkingUrl,
    required this.mapUrl,
  });

  factory MapTileData.empty() {
    return MapTileData(xTile: 0, yTile: 0, parkingUrl: '', mapUrl: '');
  }
}