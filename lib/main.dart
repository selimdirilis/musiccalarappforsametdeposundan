import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'theme_provider.dart';
import 'favorite_service.dart';
import 'music_home_page.dart';
import 'favorite_page.dart';
import 'settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Arka planda çalışan işlemi beklememek için Future.delayed kullanıyoruz
  await Future.delayed(Duration.zero, () async {
    // JustAudioBackground'ı başlatma
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.music.channel.audio', // Paket adınıza uygun olarak değiştirildi
      androidNotificationChannelName: 'Müzik Çalar',
      androidNotificationOngoing: true,
    );
  });

  // Ekran yönünü yalnızca dikey yapmak için bu kodu ekliyoruz
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,  // Yalnızca dikey yönü kabul et
    DeviceOrientation.portraitDown,  // Dikey aşağıyı da kabul et (ters ekran)
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final light = ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.white,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Colors.greenAccent,
        labelTextStyle: MaterialStatePropertyAll(TextStyle(color: Colors.black)),
      ),
    );
    final dark = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.black,
        indicatorColor: Colors.greenAccent,
        labelTextStyle: MaterialStatePropertyAll(TextStyle(color: Colors.white)),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Müzik Çalar',
      themeMode: themeProvider.themeMode,
      theme: light,
      darkTheme: dark,
      builder: (context, child) {
        final scale = themeProvider.fontSize / 16;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: scale),
          child: child!,
        );
      },
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _panelController = PanelController();
  final _player = AudioPlayer();
  final _favorites = FavoriteService();
  double _panelSlide = 0.0;

  int _selectedIndex = 0;
  SongModel? _current;
  bool _isPlaying = false;
  bool _repeatOne = false;
  List<SongModel> _allSongs = [];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      MusicHomePage(
        player: _player,
        onSongSelected: _onSelect,
        onSongListUpdated: (list) => _allSongs = list,
      ),
      FavoritePage(
        player: _player,
        onSongSelected: _onSelect,
        onSongListUpdated: (list) => _allSongs = list,
      ),
      const SettingsPage(),
    ];
    _player.playerStateStream.listen((state) {
      final playing = state.playing &&
          state.processingState != ProcessingState.completed;
      setState(() => _isPlaying = playing);
      if (state.processingState == ProcessingState.completed) {
        if (_repeatOne && _current != null) {
          _player.seek(Duration.zero);
          _player.play();
        } else {
          _next();
        }
      }
    });
  }

  void _onSelect(SongModel song) async {
    final mediaItem = MediaItem(
      id: song.id.toString(),
      title: song.title ?? 'Bilinmeyen Parça',
      artist: song.artist ?? 'Bilinmeyen Sanatçı',
      album: song.album ?? 'Bilinmeyen Albüm',
      duration: Duration(milliseconds: song.duration ?? 0),
      artUri: song.uri != null ? Uri.parse('file://${song.uri}') : null,
    );

    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(song.uri!), tag: mediaItem),
    );

    await _player.play();
    setState(() => _current = song);
  }

  void _next() {
    if (_current == null || _allSongs.isEmpty) return;
    final i = _allSongs.indexWhere((s) => s.id == _current!.id);
    final next = _allSongs[(i + 1) % _allSongs.length];
    _onSelect(next);
  }

  void _onTap(int idx) => setState(() => _selectedIndex = idx);

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = -(_panelSlide * 150);
    return Scaffold(
      body: Stack(
        children: [
          SlidingUpPanel(
            controller: _panelController,
            minHeight: 190,
            maxHeight: MediaQuery.of(context).size.height,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            onPanelSlide: (p) => setState(() => _panelSlide = p),
            panelBuilder: _fullPanel,
            body: _pages[_selectedIndex],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom,
            child: NavigationBar(
              height: 65,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onTap,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home), label: 'Anasayfa'),
                NavigationDestination(
                    icon: Icon(Icons.favorite), label: 'Favoriler'),
                NavigationDestination(
                    icon: Icon(Icons.settings), label: 'Ayarlar'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fullPanel(ScrollController sc) {
    final theme = Theme.of(context);
    final txt = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final bg = theme.colorScheme.surface.withOpacity(0.95);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Stack(
        children: [
          Positioned(
            top: 80, // Yükseklik ayarı
            left: 20, // Sol tarafın mesafesi
            child: Container(
              width: 330, // Genişlik
              height: 370, // Yükseklik
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 80, // İkon boyutu
                ),
              ),
            ),
          ),
          Positioned(
            top: 510, // Yükseklik ayarı
            left: 20, // Sol tarafın mesafesi
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _current?.title ?? 'Parça Başlığı',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: txt),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _current?.artist ?? 'Sanatçı',
                  style: TextStyle(fontSize: 20, color: txt.withOpacity(0.7)),
                ),
              ],
            ),
          ),

          // Panelin geri kalan kısmı
          Column(
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: (1 - _panelSlide).clamp(0.0, 1.0),
                child: GestureDetector(
                  onTap: () => _panelController.open(),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: theme.cardColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _current?.title ?? 'Parça Başlığı',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: txt),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: txt),
                          onPressed: () =>
                          _isPlaying
                              ? _player.pause()
                              : _player.play(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      _current != null && _favorites.isFavorite(_current!.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _current != null &&
                          _favorites.isFavorite(_current!.id)
                          ? Colors.redAccent
                          : txt,
                    ),
                    onPressed: () async {
                      if (_current != null) {
                        await _favorites.toggleFavorite(_current!.id);
                        setState(() {});
                      }
                    },
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: Icon(Icons.skip_previous, size: 36, color: txt),
                          onPressed: _next),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                            _isPlaying ? Icons.pause_circle : Icons.play_circle,
                            size: 56, color: txt),
                        onPressed: () =>
                        _isPlaying ? _player.pause() : _player.play(),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                          icon: Icon(Icons.skip_next, size: 36, color: txt),
                          onPressed: _next),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.repeat,
                        color: _repeatOne ? Colors.greenAccent : txt),
                    onPressed: () => setState(() => _repeatOne = !_repeatOne),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<Duration?>(
                stream: _player.durationStream,
                builder: (c, ds) {
                  final total = ds.data ?? Duration.zero;
                  return StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (c, ps) {
                      final pos = ps.data ?? Duration.zero;
                      return Column(
                        children: [
                          Slider(
                            value: pos.inSeconds.toDouble(),
                            max: total.inSeconds.toDouble().clamp(
                                1, double.infinity),
                            onChanged: (v) =>
                                _player.seek(Duration(seconds: v.toInt())),
                            activeColor: Colors.greenAccent,
                            inactiveColor: txt.withOpacity(0.3),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(pos), style: TextStyle(
                                  color: txt.withOpacity(0.7))),
                              Text(_fmt(total), style: TextStyle(
                                  color: txt.withOpacity(0.7))),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ],
      ),
    );
  }
}
