import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'favorite_service.dart';
import 'theme_provider.dart';

class FavoritePage extends StatefulWidget {
  final Function(SongModel) onSongSelected;
  final Function(List<SongModel>) onSongListUpdated;
  final AudioPlayer player;

  const FavoritePage({
    super.key,
    required this.onSongSelected,
    required this.onSongListUpdated,
    required this.player,
  });

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _favoriteSongs = [];

  @override
  void initState() {
    super.initState();
    _loadFavoriteSongs();
  }

  Future<void> _loadFavoriteSongs() async {
    final allSongs = await _audioQuery.querySongs();
    final favoriteIds = FavoriteService().getFavorites();
    final filtered = allSongs.where((song) => favoriteIds.contains(song.id)).toList();

    setState(() => _favoriteSongs = filtered);
    widget.onSongListUpdated(filtered);
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Provider.of<ThemeProvider>(context).fontSize;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _favoriteSongs.isEmpty
            ? Center(
          child: Text(
            "Favori şarkı yok.",
            style: TextStyle(fontSize: fontSize, color: Colors.white70),
          ),
        )
            : ListView.separated(
          padding: const EdgeInsets.only(top: 32, bottom: 200),
          itemCount: _favoriteSongs.length,
          separatorBuilder: (_, __) => const Divider(height: 0, thickness: 0.2),
          itemBuilder: (context, index) {
            final song = _favoriteSongs[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: const Icon(Icons.favorite, color: Colors.redAccent),
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                song.artist ?? "Bilinmeyen Sanatçı",
                style: TextStyle(fontSize: fontSize * 0.8),
              ),
              onTap: () async {
                await widget.player.setAudioSource(
                  AudioSource.uri(Uri.parse(song.uri!), tag: song.id.toString()),
                );
                await widget.player.play();
                widget.onSongSelected(song);
              },
            );
          },
        ),
      ),
    );
  }
}
