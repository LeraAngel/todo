import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:todo/database/database.dart';
import 'package:todo/models/note_model.dart';
import 'add_note_screen.dart';
import 'package:sqflite/sqflite.dart';

final localNotificationsPlugin = FlutterLocalNotificationsPlugin();

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static void deleteNotification(int id) async {
    await localNotificationsPlugin.cancel(id);
    print("Уведомление удалено");
  }

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  late Future<List<Note>> _noteList;

  final DateFormat _dateFormatter = DateFormat.yMd().add_Hm();

  DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  void iniTimeZone() async {
    tz.initializeTimeZones();
  }

  @override
  void initState () {
    super.initState();
    _updateNoteList();
    iniTimeZone();
  }

  _updateNoteList () {
    _noteList = DatabaseHelper.instance.getNoteList();
  }


  void showNotification(Note note) async {
    var notificationDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          'Channel Id',
          'Channel Mane',
          channelDescription: 'Description',
          channelShowBadge: true,
          priority: Priority.high,
          importance: Importance.max,
          icon: "notification_icon",
        ));
    if (note.date!.isAfter(DateTime.now())) {
      await localNotificationsPlugin.zonedSchedule(
          note.id!,
          'Пора делать',
          note.title,
          tz.TZDateTime.now(tz.local).add(Duration(seconds: note.date!.difference(DateTime.now()).inSeconds)),
          notificationDetails,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          androidAllowWhileIdle: true);
    }
  }


  Widget _buildNote(Note note) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.0),
      child: Column(
        children: [
          ListTile(
            title: Text(note.title!, style: TextStyle(
              fontSize: 18.0,
              color: Colors.white,
              decoration: note.status == 0
                ? TextDecoration.none
                  : TextDecoration.lineThrough
            ),),
            subtitle: Text('${_dateFormatter.format(note.date!)} - ${note.priority}', style: TextStyle(
                fontSize: 15.0,
                color: Colors.white,
                decoration: note.status == 0
                    ? TextDecoration.none
                      : TextDecoration.lineThrough
            ),),
            leading: Checkbox(
              onChanged: (value){
                note.status = value! ? 1 : 0;
                DatabaseHelper.instance.updateNote(note);
                _updateNoteList();
                setState(() {});
                //Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
              },
              side: BorderSide(width: 2.0, color: Colors.white),
              activeColor: Theme.of(context).primaryColor,
              value: note.status == 1,
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.doorbell,
                color: Colors.deepOrange,
              ),
              onPressed: () {
                showNotification(note);
                print("Нажато уведомление");
                //NotifyManager.planNotifi(id: note.id!, title: note.title!, body: note.priority!, date: note.date!);
              },
            ),
            onTap: () =>
                Navigator.push(context, CupertinoPageRoute(builder: (_) => AddNoteScreen(
                updateNoteList: _updateNoteList(),
                note: note))),
          ),
          Divider(height: 5.0, color: Theme.of(context).primaryColor, thickness: 2.0,),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          Navigator.push(context, CupertinoPageRoute(builder: (_) => AddNoteScreen(
            updateNoteList: _updateNoteList,
          ),));
        },
        child: Icon(Icons.add),
      ),
      body: FutureBuilder (

        future: _noteList,
      builder: (context, AsyncSnapshot snapshot) {
          if(!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final int completedNoteCount = snapshot.data!.where((Note note) => note.status == 1).toList().length;

        return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 80.0),
            itemCount: int.parse(snapshot.data!.length.toString()) + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 40.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'My Notes',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10.0,),
                      Text(
                        '$completedNoteCount of ${snapshot.data.length}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 40.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _buildNote(snapshot.data![index - 1]);
            }
        );
      }
    ),
    );
  }
}
