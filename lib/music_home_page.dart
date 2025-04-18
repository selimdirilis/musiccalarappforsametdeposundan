import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'favorite_service.dart';
import 'main.dart';
import 'theme_provider.dart';

class MusicHomePage extends StatefulWidget {
  final Function(SongModel) onSongSelected;
  final Function(List<SongModel>) onSongListUpdated;
  final AudioPlayer player;

  const MusicHomePage({
    super.key,
    required this.onSongSelected,
    required this.onSongListUpdated,
    required this.player,
  });

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final FavoriteService _favService = FavoriteService();
  List<SongModel> _songs = [];

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    if (!await Permission.audio.isGranted) {
      await Permission.audio.request();
    }
    if (await Permission.audio.isGranted) {
      final fetched = await _audioQuery.querySongs();
      setState(() => _songs = fetched);
      widget.onSongListUpdated(fetched);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontSize = Provider.of<ThemeProvider>(context).fontSize;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        margin: const EdgeInsets.only(top: 12),
        child: SafeArea(
          top: false,
          child: _songs.isEmpty
              ? Center(
            child: Text(
              "Şarkı bulunamadı veya izin verilmedi.",
              style: TextStyle(fontSize: fontSize),
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.only(top: 32, bottom: 400),
            itemCount: _songs.length,
            separatorBuilder: (_, __) => const Divider(height: 0, thickness: 0.2),
            itemBuilder: (context, index) {
              final song = _songs[index];
              return _buildSongTile(song, fontSize);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSongTile(SongModel song, double fontSize) {
    final isFav = _favService.isFavorite(song.id);

    return StreamBuilder<PlayerState>(
      stream: widget.player.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        final currentTag = widget.player.sequenceState?.currentSource?.tag;
        final isThisSongPlaying = (currentTag == song.id.toString()) && isPlaying;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Icon(
            isThisSongPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.greenAccent,
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
          subtitle: Text(
            song.artist ?? "Bilinmeyen Sanatçı",
            style: TextStyle(fontSize: fontSize * 0.8),
          ),
          trailing: IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav
                  ? Colors.redAccent
                  : Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
            onPressed: () async {
              await _favService.toggleFavorite(song.id);
              setState(() {});
            },
          ),
            onTap: () async {
              final curTag = widget.player.sequenceState?.currentSource?.tag;
              final isSameSong = (curTag == song.id.toString());

              if (isSameSong && isPlaying) {
                await widget.player.pause();
              } else {
                await widget.player.setAudioSource(
                  AudioSource.uri(Uri.parse(song.uri!), tag: song.id.toString()),
                );
                await widget.player.play();


                widget.onSongSelected(song);
              }
            }

        );
      },
    );
  }
}
