import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fourier_circles_flutter/FourierCirclesRoute.dart';
import 'package:fourier_circles_flutter/GetCefet.dart';

import 'DrawingPoints.dart';
import 'FourierUtils.dart';

List<DrawingPoints> generatePoints(Function fn, double steps, Paint paint){
  List<DrawingPoints> tmpPoints = [];
  double radius = 50;
  double center = 100;
  for (double i = 0; i < steps; i++) {
    tmpPoints.add(DrawingPoints(
        points: Offset(
          (center + radius * fn(2 * pi * i / steps)),
          (center + radius * fn(2 * pi * i / steps)),
        ),
        paint: paint
    ));
  }

  tmpPoints.add(null);
  return tmpPoints;
}

double squareWave(double x){
  double period = pi/2.0;
  double y = x%(2*period);
  return (y > period)?2:0;
}

double sawToothWave(double x){
  return x%(0.5*pi);
}

double triangleWave(double y){
  double period = pi/2.0;

  double x = y%(2*period);
  return (x > period)?(2*period - (x)):(x);
}

class Draw extends StatefulWidget {
  @override
  _DrawState createState() => _DrawState();
}

class _DrawState extends State<Draw> {
  Color selectedColor = Colors.blue;
  Color pickerColor = Colors.black;
  double strokeWidth = 3.0;
  List<DrawingPoints> points = [];
  bool showBottomList = false;
  double opacity = 1.0;
  double numberOfCircles = 1.0;
  bool waveMode = true;
  StrokeCap strokeCap = StrokeCap.round;

  _DrawState(){

    points = generatePoints(sawToothWave, 360, Paint()
      ..strokeCap = strokeCap
      ..isAntiAlias = true
      ..color = selectedColor.withOpacity(opacity)
      ..strokeWidth = strokeWidth);
  }

  Widget getDrawScreen(){
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          RenderBox renderBox = context.findRenderObject();
          points.add(DrawingPoints(
              points: renderBox.globalToLocal(details.globalPosition),
              paint: Paint()
                ..strokeCap = strokeCap
                ..isAntiAlias = true
                ..color = selectedColor.withOpacity(opacity)
                ..strokeWidth = strokeWidth));
        });
      },
      onPanStart: (details) {
        setState(() {
          points.clear();
          RenderBox renderBox = context.findRenderObject();
          points.add(DrawingPoints(
              points: renderBox.globalToLocal(details.globalPosition),
              paint: Paint()
                ..strokeCap = strokeCap
                ..isAntiAlias = true
                ..color = selectedColor.withOpacity(opacity)
                ..strokeWidth = strokeWidth));
        });
      },
      onPanEnd: (details) {
        setState(() {
          points.add(null);
        });
      },
      child: CustomPaint(
        size: Size.square(30),

        painter: DrawingPainter(
          pointsList: points,
          waveMode: waveMode
        ),
      ),
    );
  }

  loadSample(Function mathFn){
    setState(() {
      points = generatePoints(mathFn, 360, Paint()
        ..strokeCap = strokeCap
        ..isAntiAlias = true
        ..color = selectedColor.withOpacity(opacity)
        ..strokeWidth = strokeWidth);
    });
  }

  getNavigationBar(){
    int numPoints = points.length ~/ 2;
    num numFouriers = slurp(2, numPoints, this.numberOfCircles).floor();


    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Slider(
                    value: numberOfCircles,
                    max: 1,
                    min: 0,
                    onChanged: (val) {
                      setState(() {

                        numberOfCircles = val;
                      });
                }),
                Text("Número de círculos: "+numFouriers.toString()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    RaisedButton(
                      onPressed: (){
                        loadSample(squareWave);
                      },
                      child: Text("Onda quadrada"),
                    ),
                    RaisedButton(
                      onPressed: (){
                        loadSample(triangleWave);
                      },
                      child: Text("Onda triangular"),
                    ),
                    RaisedButton(
                      onPressed: (){
                        loadSample(sawToothWave);
                      },
                      child: Text("Onda dente de serra"),
                    ),
                    RaisedButton(
                      onPressed: (){
                        setState(() {
                          points = GetCefet().where((item) => item[1] > 50).map((item)=> DrawingPoints(
                              points: Offset(
                                item[0],
                                350-item[1],
                              ),
                              paint: Paint()
                                ..strokeCap = strokeCap
                                ..isAntiAlias = true
                                ..color = selectedColor.withOpacity(opacity)
                                ..strokeWidth = strokeWidth)
                          ).toList(growable: true);
                          points.add(null);
                        });
                      },
                      child: Text("Onda cefet"),
                    )
                  ],
                )
              ],
            ),
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Offset> pathToUse;

    pathToUse = (this.points.isEmpty || this.points.last != null)?[]:
    this.points
        .where((point) => point != null).toList()
        .map((point){
      return point.points;
    }).toList();


    return Scaffold(
      bottomNavigationBar: getNavigationBar(),
      body: Container(
        color: Colors.white70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(10),
                child: Card(
                  child: getDrawScreen(),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(10),
                child: FourierCirclesRoute(path: pathToUse, numberOfCircles: numberOfCircles, waveMode: waveMode),
              ),
            )
          ],
        ),
      ),
    );
  }
}


class DrawingPainter extends CustomPainter {
  DrawingPainter({this.pointsList, this.waveMode});
  bool waveMode = true;
  List<DrawingPoints> pointsList;
  List<Offset> offsetPoints = List();
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i++) {
      if (pointsList[i] != null && pointsList[i + 1] != null) {
        if(i+1 < pointsList.length -1){
          canvas.drawLine(pointsList[i].points, pointsList[i + 1].points,
              pointsList[i].paint);
        }else {
          canvas.drawLine(pointsList[i].points, pointsList[0].points,
              pointsList[i].paint);
        }
      } else if (pointsList[i] != null && pointsList[i + 1] == null) {
        if(!waveMode){
          canvas.drawLine(pointsList[i].points, pointsList[0].points,
              pointsList[i].paint);
        }
//        offsetPoints.clear();
//        offsetPoints.add(pointsList[i].points);
//        offsetPoints.add(Offset(
//            pointsList[i].points.dx + 0.1, pointsList[i].points.dy + 0.1));
//        canvas.drawPoints(PointMode.points, offsetPoints, pointsList[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
