import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'favorite_service.dart';
import 'theme_provider.dart';

class FavoritePage extends StatefulWidget {
  final AudioPlayer player;
  final Function(SongModel) onSongSelected;
  final Function(List<SongModel>) onSongListUpdated;

  const FavoritePage({
    Key? key,
    required this.player,
    required this.onSongSelected,
    required this.onSongListUpdated,
  }) : super(key: key);

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final FavoriteService _favService = FavoriteService();
  List<SongModel> _songs = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final all = await _audioQuery.querySongs();
    final favIds = _favService.getFavorites();
    final favSongs =
    all.where((s) => favIds.contains(s.id)).toList(growable: false);
    setState(() => _songs = favSongs);
    widget.onSongListUpdated(favSongs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontSize = Provider.of<ThemeProvider>(context).fontSize;

    if (_songs.isEmpty) {
      return const Center(child: Text("Favori şarkı bulunamadı."));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 32, bottom: 100),
      itemCount: _songs.length,
      separatorBuilder: (_, __) => const Divider(thickness: 0.2),
      itemBuilder: (context, index) {
        final song = _songs[index];

        return StreamBuilder<PlayerState>(
          stream: widget.player.playerStateStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data?.playing ?? false;
            final currentTag = widget.player.sequenceState
                ?.currentSource
                ?.tag as MediaItem?;
            final isThisSongPlaying =
                currentTag?.id == song.id.toString() && isPlaying;

            return ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Icon(
                isThisSongPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.greenAccent,
              ),
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
              ),
              subtitle: Text(
                song.artist ?? "Bilinmeyen Sanatçı",
                style: TextStyle(fontSize: fontSize * 0.8),
              ),
              trailing: IconButton(
                icon: Icon(
                  _favService.isFavorite(song.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: _favService.isFavorite(song.id)
                      ? Colors.redAccent
                      : (theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black),
                ),
                onPressed: () async {
                  await _favService.toggleFavorite(song.id);
                  setState(() {
                    _songs.removeWhere((s) => s.id == song.id);
                  });
                },
              ),
              onTap: () {
                if (isThisSongPlaying) {
                  widget.player.pause();
                } else {
                  widget.onSongSelected(song);
                }
              },
            );
          },
        );
      },
    );
  }
}
