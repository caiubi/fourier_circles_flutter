//import CanvasController from "./canvas-controller";
//import { getFourierData, resample2dData } from "../just-fourier-things";
//import { slurp, clampedSlurp } from "../util";
//import { palette } from "../color";

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'FourierUtils.dart';

class EpicyclesPainter extends CustomPainter {

  // [ {freq, amplitude, phase } ]
  List<FFTData> fourierData = [];
  // [ {x, y} ]
  List<Offset> fourierPath = [];

  double animAmt = 0;
  double fourierAmt = 1.0;

  double stepSize = 1;
  double offset = 1024;

  var circlePaint;
  var pathPaint;
  var guidePaint;

  bool waveMode;

  EpicyclesPainter({this.fourierData, this.fourierPath, this.fourierAmt, this.animAmt, this.waveMode}){
    circlePaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;
    pathPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;
    guidePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;
  }


  renderPath(Canvas canvas, path) {
    for (int i = 0; i < path.length - 1; i ++) {
      canvas.drawLine(path[i], path[i+1], pathPaint);
//      this.context.beginPath();
//      this.context.strokeStyle = palette.blue;
//      this.context.lineWidth = 2;
//      this.context.moveTo(path[i].x, path[i].y);
//      this.context.lineTo(path[i+1].x, path[i+1].y);
//      this.context.stroke();
    }
  }

  renderCircles(Canvas canvas) {
    if (this.fourierData.length == 0) {
      return;
    }
    num runningX = 0;
    num runningY = 0;
    num maxAmp = 0;
    Offset lastOffset = Offset(0,0);

    num numFouriers = slurp(2, this.fourierData.length, this.fourierAmt).round();
    for (int i = 0; i < numFouriers; i ++) {
      num amplitude = this.fourierData[i].amplitude;
      maxAmp = max(amplitude, maxAmp);
      num angle = 2 * pi * this.fourierData[i].freq * this.animAmt + this.fourierData[i].phase;
      runningX += amplitude * cos(angle);
      runningY += amplitude * sin(angle);
      if (i == 0) {
        continue; // we skip the first one because we just don't care about rendering the constant term
      }
      if (amplitude < 0.5) {
        continue; // skip the really tiny ones
      }

      canvas.drawCircle(Offset(runningX, runningY), amplitude, circlePaint);
      canvas.drawArc(Rect.fromCircle(center: Offset(runningX, runningY), radius: amplitude), angle + pi, 0, true, circlePaint);

    }
//    canvas.drawLine(Offset(runningX, runningY), Offset(maxAmp+200, runningY), circlePaint);
  }

  renderPeriod(Canvas canvas, List<Offset> path){
    if(path.isEmpty){
      return;
    }

    double startX = 400;

    canvas.drawLine(path[path.length -1],
        Offset(startX-10, path[path.length - 1].dy), guidePaint);

    canvas.drawCircle(Offset(startX, path[path.length - 1].dy), 5, guidePaint);
    for (int i = path.length - 1; i > 0; i--) {
      int j = path.length - 1 - i;

      canvas.drawLine(Offset(startX+(j*stepSize), path[i].dy),
          Offset(startX+((j+1)*stepSize), path[i-1].dy), pathPaint);
    }
  }

  void clear() {

  }

  @override
  void paint(Canvas canvas, Size size) {
      this.renderPath(canvas, this.fourierPath);
      this.renderCircles(canvas);
      this.renderPeriod(canvas, this.fourierPath);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return this != oldDelegate;
  }

}
