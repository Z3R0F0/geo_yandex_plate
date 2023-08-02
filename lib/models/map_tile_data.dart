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