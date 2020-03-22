import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(App());

const Map<int, Color> color = {
  50: Color.fromRGBO(136, 14, 79, .1),
  100: Color.fromRGBO(136, 14, 79, .2),
  200: Color.fromRGBO(136, 14, 79, .3),
  300: Color.fromRGBO(136, 14, 79, .4),
  400: Color.fromRGBO(136, 14, 79, .5),
  500: Color.fromRGBO(136, 14, 79, .6),
  600: Color.fromRGBO(136, 14, 79, .7),
  700: Color.fromRGBO(136, 14, 79, .8),
  800: Color.fromRGBO(136, 14, 79, .9),
  900: Color.fromRGBO(136, 14, 79, 1),
};

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miksing - Demo App',
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFFFF9933, color),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map> playlist = new List<Map>();
  bool webPlayerVisible = false;

  VideoPlayerController videoPlayerController;
  final Completer<WebViewController> webPlayerController =
      Completer<WebViewController>();

  uploadVideo(String path) async {
    final StorageReference anim = FirebaseStorage.instance.ref().child(path);
    String url = (await anim.getDownloadURL()).toString();
    videoPlayerController = VideoPlayerController.network(url)
      ..initialize().then((_) {
        setState(() {});
        videoPlayerController.play();
        videoPlayerController.setLooping(true);
      });
  }

  @override
  void initState() {
    super.initState();
    uploadVideo("anim/Miksing_Logo-Animated.mp4");

    const defaultUser = 'Zdh2ZOt9AOMKih2cNv00XSwk3fh1';
    String path = "/user/$defaultUser/song/";
    print('initState');

    FirebaseDatabase.instance
        .reference()
        .child(path)
        .once()
        .then((DataSnapshot snapshot) {
      Map<dynamic, dynamic> values = snapshot.value;
      values.forEach((key, values) {
        Map map = new Map();
        map['id'] = key;
        playlist.add(map);
        FirebaseDatabase.instance
            .reference()
            .child('song')
            .child(key)
            .once()
            .then((DataSnapshot snapshot) {
          Map<dynamic, dynamic> values = snapshot.value;
          String name = values['name'];
          if (name != null) map['name'] = name;
          String mark = values['mark'];
          if (mark != null) map['mark'] = mark;
        });
      });
    });

    webPlayerController.future.then((controller) {
      //_loadHtmlFromAssets(controller);
    });
  }

  @override
  void dispose() {
    super.dispose();
    videoPlayerController.dispose();
  }

  _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          final Iterable<ListTile> tiles = _saved.map(
            (Map song) {
              return ListTile(
                title: _buildSong(song),
              );
            },
          );
          final List<Widget> divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();
          return Scaffold(
            appBar: AppBar(
              title: Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }

  final Set<Map> _saved = Set<Map>();
  final TextStyle _biggerFont = const TextStyle(fontSize: 18.0);
  final TextStyle _boldFont = const TextStyle(fontWeight: FontWeight.bold);

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: playlist.length,
        itemBuilder: (context, i) {
          if (i.isOdd) return Divider();
          return _buildRow(playlist[i]);
        });
  }

  Widget _buildRow(Map song) {
    final bool saved = _saved.contains(song);
    return ListTile(
      title: _buildSong(song),
      trailing: Icon(
        saved ? Icons.favorite : Icons.favorite_border,
        color: saved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if (saved) {
            _saved.remove(song);
          } else {
            _saved.add(song);
            String id = song['id'];
            if (id != null) loadVideoById(id);
          }
        });
      },
    );
  }

  Widget _buildSong(Map song) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song['name'],
          style: _biggerFont,
        ),
        Text(
          song['mark'],
          style: _boldFont,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Miksing - Demo App'),
        actions: <Widget>[
          // Add 3 lines from here...
          IconButton(icon: Icon(Icons.list), onPressed: _pushSaved),
        ],
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            videoPlayerController != null &&
                    videoPlayerController.value.initialized
                ? AspectRatio(
                    aspectRatio: 16 / 9,
                    child: VideoPlayer(videoPlayerController),
                  )
                : Container(),
            AspectRatio(
                aspectRatio: 16 / 9, //_controller.value.aspectRatio,
                child: Visibility(
                  visible: webPlayerVisible,
                  child: WebView(
                    initialUrl: '',
                    javascriptMode: JavascriptMode.unrestricted,
                    initialMediaPlaybackPolicy:
                        AutoMediaPlaybackPolicy.always_allow,
                    onWebViewCreated: (WebViewController webViewController) {
                      webPlayerController.complete(webViewController);
                      _loadHtmlFromAssets(webViewController);
                    },
                  ),
                )),
            Text(
              'Flutter Demo',
              style: Theme.of(context).textTheme.display1,
            ),
            Expanded(
              child: _buildSuggestions(),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (videoPlayerController != null)
              videoPlayerController.value.isPlaying
                  ? videoPlayerController.pause()
                  : videoPlayerController.play();
          });
        },
        child: Icon(
          videoPlayerController != null && videoPlayerController.value.isPlaying
              ? Icons.pause
              : Icons.play_arrow,
        ),
      ),
    );
  }

  firebaseErrorLog(String message) {
    developer.log("Firebase", name: "com.tregz.miksing", error: message);
  }

  loadVideoById(String id) {
    if (!webPlayerVisible) {
      setState(() {
        webPlayerVisible = true;
      });
    }
    webPlayerController.future.then((WebViewController controller) =>
        controller.evaluateJavascript('loadVideoById(\'' + id + '\');'));
  }

  Future<void> _loadHtmlFromAssets(WebViewController controller) async {
    String fileText = await rootBundle.loadString('assets/youtube.html');
    String theURI = Uri.dataFromString(fileText,
        mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString();

    setState(() {
      controller.loadUrl(theURI);
    });
  }
}
