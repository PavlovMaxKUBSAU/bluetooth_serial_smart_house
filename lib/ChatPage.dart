import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';



class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;
  final double optimalSize;

  const ChatPage({required this.server, required this.optimalSize});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  BluetoothConnection? connection;

  // List<_Message> messages = [new _Message(1, "+25°C+25°C+25°C1.2 bar0001")];
  // List<_Message> messages = [new _Message(1, "\$------")];
  List<_Message> messages = [new _Message(1, "                          ")];

  String _messageBuffer = '';

  final TextEditingController textEditingController =
  new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);
  bool isDisconnecting = false;

  late double optimalSize;

  late BorderRadius border_radius;
  late double border_width;

  late Image img_main;

  Color standartColor = Color.fromRGBO(130,250,0,1);

  bool toggler_pump = false;
  Timer? _timer;


  @override
  void initState() {
    super.initState();
    optimalSize = widget.optimalSize;
    border_radius = BorderRadius.circular(optimalSize * 0.5);
    border_width = optimalSize * 0.08;

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Подключено');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Отключено локально!');
        } else {
          print('Отключено удаленно!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Ошибка подключения, выброс исключения');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Text> list = messages.map((_message) {
      return (_message.text[0] == String.fromCharCode(13)) ?
      Text(_message.text.substring(1)) :
      Text(_message.text);
    }).toList();


    if (list[0].data![0] != "\$") {
      img_main = list[0].data![22] == "1" ? Image.asset(
          "assets/PumpON.png", fit: BoxFit.contain)
          : Image.asset("assets/PumpOFF.png", fit: BoxFit.contain);
      
      if (list[0].data![25] == "1") {
        if (_timer == null) {
          _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) =>
              setState(() {
                toggler_pump = !toggler_pump;
              }));
        }
      }
      else {
        _timer?.cancel();
        _timer = null;
        toggler_pump = false;
      }
    }

    return Scaffold(
        appBar: AppBar(
            toolbarHeight: 50,
            title: (isConnecting
                ? Text('Подключение...')
                : isConnected
                ? Text('Подключено')
                : Text('Нет связи!', style: TextStyle(color: Color.fromRGBO(230,50,30,1)),))),
        backgroundColor: Colors.white,

        body: list[0].data![0] == "\$" ?
          Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: optimalSize * 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          "Установленная температура:",
                          style: TextStyle(fontSize: optimalSize * 1.5),
                        ),
                      ],
                  ),

                  Padding(
                    padding: EdgeInsets.only(top: optimalSize),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        ElevatedButton(
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all<OutlinedBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: border_radius,
                                    side: BorderSide(color: Colors.black)
                                  ),
                              ),
                              backgroundColor: MaterialStateProperty.all<Color>(Colors.white60),
                            ),
                            
                            onPressed: () { _sendMessage("-"); },
                            child: Text(
                              "-",
                              style: TextStyle(fontSize: optimalSize * 2, color: Colors.black, fontWeight: FontWeight.bold),)
                        ),
                        Container(
                          height: optimalSize * 2,
                          width: optimalSize * 5.5,

                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: border_radius,
                            color: standartColor,
                            border: Border.all(
                              color: Colors.black,
                              width: border_width,
                            ),
                          ),

                          child: Text(
                            list[0].data!.substring(1,6),
                            style: TextStyle(fontSize: optimalSize*1.5),
                          ),
                        ),
                        ElevatedButton(
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all<OutlinedBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: border_radius,
                                    side: BorderSide(color: Colors.black)
                                ),
                              ),
                              backgroundColor: MaterialStateProperty.all<Color>(Colors.white60),
                            ),

                            onPressed: () { _sendMessage("+"); },
                            child: Text(
                              "+",
                              style: TextStyle(fontSize: optimalSize * 2, color: Colors.black),)
                        ),
                      ]
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(top: optimalSize * 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          "Котел: ",
                          style: TextStyle(fontSize: optimalSize*1.5),
                        ),
                        Switch.adaptive(

                          value: list[0].data![6] == "0",
                          onChanged: (value) {
                             _sendMessage(value ? "P" : "S");
                          },
                          activeTrackColor: Colors.lightGreenAccent,
                          activeColor: Colors.green,
                        ),
                      ]
                    ),
                  ),
                ],
              ),
            ),

            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: optimalSize * 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        // padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(5)),
                        shape: MaterialStateProperty.all<OutlinedBorder>(
                          RoundedRectangleBorder(
                              borderRadius: border_radius,
                              side: BorderSide(color: Colors.black)
                          ),
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.lightBlue),
                      ),

                      onPressed: () { _sendMessage("E"); },
                      child: Text(
                        "СОХРАНИТЬ И ВЫЙТИ",
                        style: TextStyle(fontSize: optimalSize * 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )

        : Stack(
          children: <Widget>[
            
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width,
                child: img_main,
              )
            ),

            ///t в системе
            Center(
              child: Container(
                height: optimalSize * 2,
                width: optimalSize * 5.5,

                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: border_radius,
                  color: standartColor,
                  border: Border.all(
                    color: Colors.black,
                    width: border_width,
                  ),
                ),

                margin: EdgeInsets.only(bottom: optimalSize * 26, right: optimalSize * 1.75),

                child: Text(
                  list[0].data!.substring(0,5),
                  style: TextStyle(fontSize: optimalSize*1.5),
                ),
              ),
            ),

            ///t котла
            Center(
              child: Container(
                height: optimalSize * 2,
                width: optimalSize * 5.5,

                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: border_radius,
                  color: standartColor,
                  border: Border.all(
                    color: Colors.black,
                    width: border_width,
                  ),
                ),

                margin: EdgeInsets.only(right: optimalSize * 2, bottom: optimalSize),

                child: Text(
                  list[0].data!.substring(5,10),
                  style: TextStyle(fontSize: optimalSize*1.5),
                ),
              ),
            ),

            ///t установленная
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: optimalSize * 19.5, right: optimalSize * 2),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: optimalSize * 1.8, color: Colors.black, fontWeight: FontWeight.bold),
                            children: <TextSpan>[
                              TextSpan(text: "T"),
                              TextSpan(text: "уст  ", style: TextStyle(fontSize: optimalSize * 1.3)),
                            ],
                          )
                      ),

                      Container(
                        height: optimalSize * 2,
                        width: optimalSize * 5.5,

                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: border_radius,
                          color: list[0].data![24] == "0" ? standartColor : Color.fromRGBO(200, 200, 200,1),
                          border: Border.all(
                            color: Colors.black,
                            width: border_width,
                          ),
                        ),

                        child: Text(
                          list[0].data![24] == "0" ? list[0].data!.substring(10,15)
                              : "STOP",
                          style: TextStyle(fontSize: optimalSize*1.5),
                        ),
                      ),
                    ]
                ),
              ),
            ),

            ///давление
            Center(
              child: Container(
                height: optimalSize * 2,
                width: optimalSize * 5.95,

                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: border_radius,
                  color: standartColor,
                  border: Border.all(
                    color: Colors.black,
                    width: border_width,
                  ),
                ),

                margin: EdgeInsets.only(bottom: optimalSize * 8.93, right: optimalSize * 1.2),

                child: Text(
                  list[0].data!.substring(15,22),
                  style: TextStyle(fontSize: optimalSize*1.5),
                ),
              ),
            ),


            ///кнопка установок
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: optimalSize * 30),
                child: ElevatedButton(
                  // style: ButtonStyle(
                  //   padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.only(left: 20)),
                  // ),

                  onPressed: () { _sendMessage("U"); },
                  child: Text(
                    "УСТАНОВКИ",
                    style: TextStyle(fontSize: optimalSize*1.7, letterSpacing: 1),)

                ),
              ),
            ),

            ///картинка огня
            Center(
              child: Container(
                margin: EdgeInsets.only(top: optimalSize * 8.3, right: optimalSize * 2),
                child: list[0].data![23] == "1" ? Image.asset("assets/ON.png", scale: 18/optimalSize)
                    : Image.asset("assets/OFF.png", scale: 18/optimalSize),
              ),
            ),

            ///авария
            Center(
              child: Container(
                alignment: Alignment.topRight,
                child: toggler_pump ? Image.asset("assets/emergency.png", scale: 18/optimalSize)
                    : null
              )
            ),
          ],
        ),
      );

  }





  void _onDataReceived(Uint8List data) {
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);

    if (~index != 0) {
      messages.clear();
      setState(() {
        messages.add(
            _Message(
                1,
                backspacesCounter > 0
                    ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                    : _messageBuffer + dataString.substring(0, index)
            )
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
          0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }
  
  void _sendMessage(String text) async {
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(ascii.encode(text)));
        await connection!.output.allSent;

        // Future.delayed(Duration(milliseconds: 333)).then((_) {
        //   listScrollController.animateTo(
        //       listScrollController.position.maxScrollExtent,
        //       duration: Duration(milliseconds: 333),
        //       curve: Curves.easeOut);
        // });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }


}


