import 'dart:math';
import 'dart:ui';

import 'package:fft/fft.dart';
import 'package:my_complex/my_complex.dart';

import 'MyFFT.dart';

class FFTData {
  double freq;
  double amplitude;
  double phase;
  FFTData({this.freq, this.amplitude, this.phase});
}


List<FFTData> getFourierData(List<num> points){
  if (points.length == 0) {
    return [];
  }

  int numPoints = points.length ~/ 2;

  MyFFT fft = new MyFFT(numPoints);
  List<num> out = fft.createComplexArray();
  fft.transform(out, points);

//  List<Complex> outComplex = new FFT().Transform(points);
//  List<num> out = [];

//  outComplex.forEach((Complex element){
//    out.add(element.real);
//    out.add(element.imaginary);
//  });


  // Transform into an API of points I find friendlier.
  List<FFTData> fftData = [];

  for (int i = 0; i < numPoints; i ++) {
    // to reorder the frequencies a little nicer, we pick from the front and back alternatively
    int evenMid = i~/2;
    int oddMid = (numPoints - ((i+1) ~/ 2));

    int j = (i % 2 == 0) ? evenMid : oddMid;
    var x = out[2 * j];
    var y = out[2 * j + 1];


    double freq = ((j + numPoints / 2) % numPoints) - numPoints / 2;
    fftData.add(FFTData(
      freq: freq,
      // a little expensive
      amplitude: sqrt(x * x + y * y) / numPoints,
      // a lottle expensive :(
      phase: atan2(y, x),
    ));
  }
  // fftData.sort((a, b) => b.amplitude - a.amplitude);
  return fftData;
}

List<num> resample2dData(List<Offset> points, num numSamples) {
  if (points.length == 0) {
    // Can't resample if we don't have ANY points
    return [];
  }

  List<num> newPoints = [];
  for (int i = 0; i < numSamples; i ++) {
    double position = points.length * (i / numSamples);
    int index = position.floor();
    int nextIndex = (index + 1) % points.length;
    double amt = position - index;
    newPoints.add(
      /* x */
      slurp(points[index].dx, points[nextIndex].dx, amt)
    );

    newPoints.add(
      /* y */
      slurp(points[index].dy, points[nextIndex].dy, amt)
    );
  }
  return newPoints;
}

num slurp(val1, val2, double amt) {
  return (val2 - val1) * amt + val1;
}