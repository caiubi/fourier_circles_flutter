import 'dart:math';
import 'dart:ui';
import 'FourierUtils.dart';

class EpicyclesController{
  EpicyclesController(List<Offset> path) {
    setPath(path, numPoints: 1024);
    setFourierAmt(1.0);
  }

  DateTime lastUpdate;
  bool animate = true;


  // [ {freq, amplitude, phase } ]
  List<FFTData> fourierData = [];
  // [ {x, y} ]
  List<Offset> fourierPath = [];
  int numPoints = 0;
  // What percentage of the path to draw
  double pathAmt = 1;
  bool animatePathAmt = true;

  double animAmt = 0;
  double niceAnimAmt = 0;
  double period = 5;

  double fourierAmt = 1.0;

  bool pathDirty = false;

  setPath(List<Offset> path, {numPoints=-1, minAmplitude=0.01}) {
    if (numPoints < 0) {
      numPoints = path.length;
    }
    this.numPoints = numPoints;
    this.animAmt = 0;
    this.niceAnimAmt = 0;
    this.fourierPath = [];
    // Get the fourier data, also filter out the really small terms.
    List<num> resampledData = resample2dData(path, this.numPoints);
    this.fourierData = getFourierData(resampledData);
    this.fourierData = this.fourierData.where((f) => f.amplitude > minAmplitude).toList();
    this.fourierData
        .sort((a, b) => (b.amplitude.compareTo(a.amplitude)));
    //  console.log(this.fourierData.length + '/' + numPoints)
  }

  setFourierAmt(amt) {
    this.fourierAmt = amt;
//    this.pathDirty = true;
  }

  recalculatePath() {
    // then render everything.
    for (int i = 0; i < this.numPoints; i ++) {
      this.niceAnimAmt += 1 / this.numPoints;
      this.addToPath();
    }
    this.niceAnimAmt -= 1;
  }

  update(dt) {
    if (this.pathDirty) {
      this.recalculatePath();
      this.pathDirty = false;
    }

    if (!this.animate) {
      return;
    }
    this.animAmt += (dt / this.period) % 1;

    while (this.animAmt > 1) {
      this.animAmt --;
      this.niceAnimAmt --;
    }

    if (this.animatePathAmt) {
      const transitionFactor = (1 / 10);
      num pos = 0; //TODO(verify)
      num desiredPathAmt = 0;
      if (pos < 0.8) {
        desiredPathAmt = 1;
      }
      this.pathAmt += transitionFactor * (desiredPathAmt - this.pathAmt);
      if (this.pathAmt >= 0.99) {
        this.pathAmt = 1;
      }
    }

    // some max iterations to stop it from hanging
    for (int i = 0; i < 20; i ++) {
      if (this.niceAnimAmt >= this.animAmt) {
        break;
      }
      this.niceAnimAmt += 1 / this.numPoints;
      this.addToPath();
    }
  }

  addToPath() {
    if (this.fourierData.length == 0) {
      return;
    }
    num runningX = 0;
    num runningY = 0;
    num numFouriers = slurp(2, this.fourierData.length, this.fourierAmt).round();
    for (int i = 0; i < numFouriers; i ++) {
      num amplitude = this.fourierData[i].amplitude;
      num angle = 2 * pi * this.fourierData[i].freq * this.niceAnimAmt + this.fourierData[i].phase;
      runningX += amplitude * cos(angle);
      runningY += amplitude * sin(angle);
    }

    this.fourierPath.add(Offset(runningX, runningY));

    while (this.fourierPath.length > this.numPoints * this.pathAmt && this.fourierPath.length > 0) {
      this.fourierPath.removeAt(0);
    }
  }

}