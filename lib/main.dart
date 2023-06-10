import 'dart:async';
import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

var supprtedExt = [".mp4", ".mkv", ".avi"];
List<String> files = <String>[];
String message = "Please drag video files to this app";

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Combine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Video Combine Home Page'),
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
  void _fileDropDone(detail) {
    setState(() {
      for (var file in detail.files) {
        if (supprtedExt.contains(p.extension(file.path))) {
          files.add(file.path);
        }
      }
    });
  }

  void _mergeFile() async {
    if (files.isEmpty) {
      return;
    }
    var workDir = p.dirname(files[0]);
    var fileName = p.basename(files[0]);
    var ext = p.extension(files[0]);
    var newFileName = fileName.replaceFirst(ext, "-output.mp4");
    var outputPath = p.join(workDir, newFileName);

    if (File(outputPath).existsSync()) {
      File(outputPath).deleteSync();
    }

    var listFile = File(p.join(workDir, "list-tmp.txt"));
    if (listFile.existsSync()) {
      listFile.deleteSync();
    }

    listFile.createSync();
    var sink = listFile.openWrite();
    for (var f in files) {
      sink.writeln("file $f".replaceAll("\\", "/"));
    }
    await sink.flush();
    await sink.close();

    setState(() {
      message = "waiting...";
    });

    var args = [
      "-f",
      "concat",
      "-safe",
      "0",
      "-i",
      "list-tmp.txt",
      "-c",
      "copy",
      newFileName
    ];
    var result = Process.runSync("ffmpeg", args, workingDirectory: workDir);

    setState(() {
      if (result.exitCode == 0) {
        message = "success saved to $outputPath";
      } else {
        message = result.stderr.toString();
      }
    });

    listFile.deleteSync();
  }

  void _clearFile() {
    setState(() {
      files.clear();
    });
  }

  void _fileClicked(int index, String op) {
    setState(() {
      if (op == 'delete') {
        files.removeAt(index);
      } else if (index > 0 && op == 'move_up') {
        String tmp = files[index - 1];
        files[index - 1] = files[index];
        files[index] = tmp;
      } else if (index < (files.length - 1) && op == 'move_down') {
        String tmp = files[index + 1];
        files[index + 1] = files[index];
        files[index] = tmp;
      }
    });
  }

  ListTile tileBuilder(BuildContext context, int index) {
    return ListTile(
        title: Text(files[index]),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.move_up,
                size: 20.0,
                color: Colors.blue[900],
              ),
              onPressed: () {
                _fileClicked(index, 'move_up');
              },
            ),
            IconButton(
              icon: Icon(
                Icons.move_down,
                size: 20.0,
                color: Colors.blue[900],
              ),
              onPressed: () {
                _fileClicked(index, 'move_down');
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20.0,
                color: Colors.red[900],
              ),
              onPressed: () {
                _fileClicked(index, 'delete');
              },
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    const EdgeInsets margin =
        EdgeInsets.only(left: 15.0, right: 15.0, top: 15.0, bottom: 50.0);
    return DropTarget(
        onDragDone: _fileDropDone,
        child: Scaffold(
          body: Container(
              margin: margin,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                        flex: 8,
                        child: ListView.builder(
                            itemCount: files.length, itemBuilder: tileBuilder)),
                    Expanded(
                      flex: 2,
                      child: Text(message),
                    ),
                  ],
                ),
              )),
          floatingActionButton: Wrap(
            //will break to another line on overflow
            direction: Axis.horizontal, //use vertical to show  on vertical axis
            children: <Widget>[
              Container(
                  margin: const EdgeInsets.all(10),
                  child: FloatingActionButton(
                    tooltip: 'Clear',
                    onPressed: _clearFile,
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.clear),
                  )),
              Container(
                  margin: const EdgeInsets.all(10),
                  child: FloatingActionButton(
                    tooltip: 'Merge',
                    onPressed: _mergeFile,
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.task_alt),
                  )),
            ],
          ),
        ));
  }
}
