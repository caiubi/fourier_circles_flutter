
import 'package:flutter/material.dart';
import 'package:fourier_circles_flutter/EpicyclesController.dart';
import 'package:fourier_circles_flutter/EpicyclesPainter.dart';


class FourierCirclesRoute extends StatefulWidget {
  final List<Offset> path;
  final EpicyclesController circlesController;
  final double numberOfCircles;
  final bool waveMode;

  FourierCirclesRoute({Key key, this.path, this.numberOfCircles, this.waveMode}) :
        this.circlesController = EpicyclesController(path),
        super(key: key){
    this.circlesController.setFourierAmt(numberOfCircles);
  }

  @override
  _FourierCirclesRouteState createState() => _FourierCirclesRouteState();
}

class _FourierCirclesRouteState extends State<FourierCirclesRoute>
    with SingleTickerProviderStateMixin {
  double waveRadius = 0.0;
  double waveGap = 100.0;
  Animation<double> _animation;
  AnimationController controller;


  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        duration: Duration(milliseconds: 5000), vsync: this);

    controller.forward();

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        print("completed, will reset");
        controller.reset();
      } else if (status == AnimationStatus.dismissed) {
        print("dismissed, will start");
        controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _animation = Tween(begin: 0.0, end: waveGap).animate(controller)
      ..addListener(() {
            if(widget.circlesController.lastUpdate == null){
              widget.circlesController.lastUpdate = new DateTime.now();
            }
            var now = new DateTime.now();
            widget.circlesController.update(now.difference(widget.circlesController.lastUpdate).inMilliseconds/1000.0);
            widget.circlesController.lastUpdate = now;
        setState(() {
          waveRadius = _animation.value;
        });
      });

    return Card(
      child:CustomPaint(
        painter: EpicyclesPainter(
          fourierData: widget.circlesController.fourierData,
          fourierPath: widget.circlesController.fourierPath,
          fourierAmt: widget.circlesController.fourierAmt,
          animAmt: widget.circlesController.animAmt,
          waveMode: widget.waveMode,
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}