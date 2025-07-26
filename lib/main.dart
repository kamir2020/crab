import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_crab/screen-dashboard.dart';

void main() async{
  runApp(MaterialApp(
    theme:
    ThemeData(primaryColor: Colors.red,),
    debugShowCheckedModeBanner: false,
    home: SplashScreen(),
  ));
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => new _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    startTime();
  }

  startTime() async {
    var duration = new Duration(seconds: 5);
    return new Timer(duration,route);
  }

  route() {
    Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) => ScreenDashboard()
    ));
  }

  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack (
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              alignment: Alignment.topCenter,
              decoration: BoxDecoration(
                color: Colors.transparent
              ),
            ),
            Column (
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded (
                  flex: 2,
                  child: Container (
                    child: Column (
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.asset('images/icon1.png',width: 150,height: 150,),
                        Padding(padding: EdgeInsets.only(top: 10.0),
                        ),
                        Text(
                          "Crab Water Monitoring\nApplication",
                          style: TextStyle(color: Colors.black,fontSize: 24.0, fontWeight: FontWeight.bold,),
                          textAlign: TextAlign.center,
                        ),

                      ],
                    ),
                  ),
                ),
                Expanded(flex: 1,
                  child: Column (
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(),
                      Padding(
                        padding: EdgeInsets.only(top: 20.0),
                      ),
                      Text("Keeping Waters Clean for Crabs & Beyond",style: TextStyle(color: Colors.black,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold)),
                    ],
                  ),)
              ],
            )
          ],
        ),
      ),
    );
  }
}