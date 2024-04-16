import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:torrent_test/components/torrentItem.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List tList = [
    'https://webtorrent.io/torrents/big-buck-bunny.torrent',
    'https://webtorrent.io/torrents/cosmos-laundromat.torrent',
    'https://webtorrent.io/torrents/sintel.torrent',
    'https://webtorrent.io/torrents/tears-of-steel.torrent',
    'https://webtorrent.io/torrents/wired-cd.torrent',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        constraints: BoxConstraints(
          minHeight: 200,
          minWidth: 200,
          maxHeight: MediaQuery.of(context).size.height,
          maxWidth: MediaQuery.of(context).size.width,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: tList.length,
          itemBuilder: (context, index) => TorrentItem(item: tList[index]),
        ),
      ),
    );
  }
}
