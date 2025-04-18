// favorite_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String _keyFavorites = 'favorite_song_ids';
  Set<int> _favoriteSongIds = {};
  static final FavoriteService _instance = FavoriteService._internal();
  FavoriteService._internal();
  factory FavoriteService() => _instance;

  Future<void> initFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteList = prefs.getStringList(_keyFavorites) ?? [];
    _favoriteSongIds = favoriteList.map(int.parse).toSet();
  }

  bool isFavorite(int songId) => _favoriteSongIds.contains(songId);

  Future<void> toggleFavorite(int songId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favoriteSongIds.contains(songId)) {
      _favoriteSongIds.remove(songId);
    } else {
      _favoriteSongIds.add(songId);
    }
    await prefs.setStringList(_keyFavorites, _favoriteSongIds.map((e) => e.toString()).toList());
  }

  Set<int> getFavorites() => _favoriteSongIds;
}
