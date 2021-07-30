import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'dart:io' show Platform;
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

void main() => runApp(MaterialApp(
    darkTheme: ThemeData.dark(),
    debugShowCheckedModeBanner: false,
    home: FlutterWifiIoT()));

class FlutterWifiIoT extends StatefulWidget {
  @override
  _FlutterWifiIoTState createState() => _FlutterWifiIoTState();
}

class _FlutterWifiIoTState extends State<FlutterWifiIoT> {
  final TextEditingController passwordController = new TextEditingController();
  @override
  Widget build(BuildContext poContext) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Wi-Fi List Show"),
        ),
        body: getWidgets(poContext));
  }

  List<WifiNetwork> _htResultNetwork = [];
  bool _isEnabled = false;
  bool _isConnected = false;
  String ssid = "";
  @override
  initState() {
    getWifis();

    super.initState();
  }

  getWifis() async {
    _isEnabled = await WiFiForIoTPlugin.isEnabled();
    _isConnected = await WiFiForIoTPlugin.isConnected();
    _htResultNetwork = await loadWifiList();
    setState(() {});
    if (_isConnected) {
      WiFiForIoTPlugin.getSSID().then((value) => setState(() {
            ssid = value;
          }));
    }
  }

  Future<List<APClient>> getClientList(
      bool onlyReachables, int reachableTimeout) async {
    List<APClient> htResultClient;
    try {
      htResultClient = await WiFiForIoTPlugin.getClientList(
          onlyReachables, reachableTimeout);
    } on PlatformException {
      htResultClient = List<APClient>();
    }

    return htResultClient;
  }

  Future<List<WifiNetwork>> loadWifiList() async {
    List<WifiNetwork> htResultNetwork;
    try {
      htResultNetwork = await WiFiForIoTPlugin.loadWifiList();
    } on PlatformException {
      htResultNetwork = List<WifiNetwork>();
    }

    return htResultNetwork;
  }

  isRegisteredWifiNetwork(String ssid) {
    return ssid == this.ssid;
  }

  Widget getWidgets(context) {
    WiFiForIoTPlugin.isConnected().then((val) => setState(() {
          _isConnected = val;
        }));

    return SingleChildScrollView(
      child: Column(
        children: getButtonWidgetsForAndroid(context),
      ),
    );
  }

  List<Widget> getButtonWidgetsForAndroid(context) {
    List<Widget> htPrimaryWidgets = List();
    WiFiForIoTPlugin.isEnabled().then((val) => setState(() {
          _isEnabled = val;
        }));
    htPrimaryWidgets.addAll({
      Container(
        child: ListTile(
            leading: Text('Wi-Fi'),
            trailing: Switch(
                value: _isEnabled,
                onChanged: (v) {
                  if (_isEnabled) {
                    WiFiForIoTPlugin.setEnabled(false);
                  } else {
                    WiFiForIoTPlugin.setEnabled(true);
                    getWifis();
                  }
                  setState(() {
                    _isEnabled = !_isEnabled;
                  });
                })),
        color: _isEnabled ? Colors.green : Colors.red,
      ),
      SizedBox(height: 10),
      Text(
        'Wi-Fi Search',
        style: TextStyle(fontSize: 25),
        textAlign: TextAlign.center,
      ),
      IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () {
            getWifis();
          }),
      getList(context)
    });
    if (_isEnabled) {
      WiFiForIoTPlugin.isConnected().then((val) {
        if (val != null) {
          setState(() {
            _isConnected = val;
          });
        }
      });
    }

    return htPrimaryWidgets;
  }

  getList(contex) {
    return ListView.builder(
      itemBuilder: (builder, i) {
        var network = _htResultNetwork[i];
        var isConnctedWifi = false;
        if (_isConnected)
          isConnctedWifi = isRegisteredWifiNetwork(network.ssid);

        if (_htResultNetwork != null && _htResultNetwork.length > 0) {
          return Container(
            color: isConnctedWifi ? Colors.blueAccent : Colors.transparent,
            child: ListTile(
                title: Text(network.ssid),
                trailing: !isConnctedWifi
                    ? TextButton(
                        onPressed: () {
                          setState(() {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text("Add Password"),
                                insetPadding: EdgeInsets.symmetric(
                                    vertical: 100, horizontal: 50),
                                content: SingleChildScrollView(
                                    child: Center(
                                  child: TextField(
                                    controller: passwordController,
                                  ),
                                )),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("Cancel")),
                                  ElevatedButton(
                                    onPressed: () async {
                                      var isConnected =
                                          await WiFiForIoTPlugin.connect(
                                        network.ssid,
                                        security: NetworkSecurity.WPA,
                                        password: passwordController.text,
                                      );
                                      if (isConnected) {
                                        setState(() {
                                          showTopSnackBar(
                                            context,
                                            CustomSnackBar.success(
                                              message:
                                                  "${network.ssid} Connected",
                                            ),
                                          );
                                        });
                                      } else {
                                        setState(() {
                                          showTopSnackBar(
                                            context,
                                            CustomSnackBar.error(
                                              message: "Invalid Password",
                                            ),
                                          );
                                        });
                                      }

                                      passwordController.clear();
                                      Navigator.pop(context);
                                    },
                                    child: Text("Connect"),
                                  ),
                                ],
                              ),
                            );
                          });
                          // Navigator.of(contex).push(MaterialPageRoute(
                          //     builder: (_) => Attack(
                          //           wifiNetwork: network,
                          //         )));
                        },
                        child: Text(
                          'Connect',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : TextButton(
                        onPressed: () async {
                          await WiFiForIoTPlugin.disconnect();
                        },
                        child: Text(
                          "Disconnect",
                          style: TextStyle(color: Colors.white),
                        ))),
          );
        } else
          return Center(
            child: Text('No wifi found'),
          );
      },
      itemCount: _htResultNetwork.length,
      shrinkWrap: true,
    );
  }
}

class PopupCommand {
  String command;
  String argument;

  PopupCommand(this.command, this.argument);
}
