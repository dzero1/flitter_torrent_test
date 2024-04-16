import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dtorrent_task/dtorrent_task.dart';
import 'package:dtorrent_common/dtorrent_common.dart';
import 'package:dtorrent_parser/dtorrent_parser.dart';
import 'package:events_emitter2/events_emitter2.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class TorrentItem extends StatefulWidget {
  const TorrentItem({super.key, required this.item});

  final String item;

  @override
  State<TorrentItem> createState() => _TorrentItemState();
}

class _TorrentItemState extends State<TorrentItem> {
  Torrent? model;
  TorrentTask? task;
  String savePath = '';
  String name = 'Loading...';
  double progressNum = 0.0;
  String progressInfo = 'Loading...';
  bool started = false;

  static var httpClient = HttpClient();
  Future<File> _downloadFile(String url, File file) async {
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    await file.writeAsBytes(bytes);
    return file;
  }

  parseTorrent() async {
    var torrentDir = await getTemporaryDirectory();
    print("torrentDir: $torrentDir");

    var torrentFile = widget.item;
    print("torrentFile: $torrentFile");

    String fileName = path.basename(widget.item);
    print("fileName: $fileName");

    var f = File(path.join(torrentDir.path, fileName));
    if (!(await f.exists())) {
      print("downloading: ${f.path}");
      await _downloadFile(torrentFile, f);
    }
    print("new torrentFile: ${f.path}");

    Directory? saveDir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getDownloadsDirectory();
    savePath = saveDir!.path;
    print("savePath: $savePath");

    model = await Torrent.parse(f.path);
    print("model: ${model!.infoHash}");

    setState(() {
      name = model!.name;
      print(name);

      progressInfo = '';
    });

    task ??= TorrentTask.newTask(model!, savePath);
  }

  runTorrent() async {
    parseTorrent();

    // model!.announces.clear();
    Timer? timer;
    var startTime = DateTime.now().millisecondsSinceEpoch;
    EventsListener<TaskEvent> listener = task!.createListener();
    listener
      ..on<TaskCompleted>((event) {
        print(
            'Complete! spend time : ${((DateTime.now().millisecondsSinceEpoch - startTime) / 60000).toStringAsFixed(2)} minutes');
        task!.stop();
        timer?.cancel();
        setState(() {
          started = false;
        });
      })
      ..on<TaskStopped>(((event) {
        print('Task Stopped');
      }));

    var map = await task!.start();
    setState(() {
      started = true;
    });
    findPublicTrackers().listen((announceUrls) {
      for (var element in announceUrls) {
        task!.startAnnounceUrl(element, model!.infoHashBuffer);
      }
    });
    log('Adding dht nodes');
    for (var element in model!.nodes) {
      log('dht node $element');
      task!.addDHTNode(element);
    }
    print(map);

    timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      var progress = '${(task!.progress * 100).toStringAsFixed(2)}%';
      var ads = ((task!.averageDownloadSpeed) * 1000 / 1024).toStringAsFixed(2);
      var aps = ((task!.averageUploadSpeed) * 1000 / 1024).toStringAsFixed(2);
      var ds = ((task!.currentDownloadSpeed) * 1000 / 1024).toStringAsFixed(2);
      var ps = ((task!.uploadSpeed) * 1000 / 1024).toStringAsFixed(2);

      var utpDownloadSpeed =
          ((task!.utpDownloadSpeed) * 1000 / 1024).toStringAsFixed(2);
      var utpUploadSpeed =
          ((task!.utpUploadSpeed) * 1000 / 1024).toStringAsFixed(2);
      var utpPeerCount = task!.utpPeerCount;

      var active = task!.connectedPeersNumber;
      var seeders = task!.seederNumber;
      var all = task!.allPeersNumber;
      print(
          'Progress : $progress (${task!.progress}) , Peers:($active/$seeders/$all)($utpPeerCount) . Download speed : ($utpDownloadSpeed)($ads/$ds)kb/s , upload speed : ($utpUploadSpeed)($aps/$ps)kb/s');

      setState(() {
        progressNum = double.parse((task!.progress * 100).toStringAsFixed(2));
        progressInfo =
            'Progress : $progress, Peers:($active/$seeders/$all)($utpPeerCount) . Download speed : ($utpDownloadSpeed)($ads/$ds)kb/s , upload speed : ($utpUploadSpeed)($aps/$ps)kb/s';
      });
    });
  }

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 1), () => parseTorrent());
    // Future.delayed(const Duration(seconds: 1), () => runTorrent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => parseTorrent(),
      title: Text(
          name) /* Wrap(
        direction: Axis.vertical,
        children: [
          Text(name),
          SizedBox(
            width: MediaQuery.of(context).size.width - 90,
            height: 3,
            child: LinearProgressIndicator(value: progressNum),
          ),
        ],
      ) */
      ,
      subtitle: Wrap(
        direction: Axis.vertical,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width - 90,
            height: 3,
            child: LinearProgressIndicator(value: progressNum),
          ),
          Text(progressInfo),
        ],
      ),
      trailing: started
          ? IconButton(
              onPressed: () => task!.stop(),
              icon: const Icon(Icons.stop),
            )
          : IconButton(
              onPressed: () => runTorrent(),
              icon: const Icon(Icons.download),
            ),
    );
  }
}
