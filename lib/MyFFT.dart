import 'dart:math';

class MyFFT {
  int size;
  int _csize;
  List<num> table;
  int _width;
  List<int> _bitrev;
  List<num> _out;
  List<num> _data;
  int _inv;

  MyFFT(this.size){
    {
      this.size = size | 0;
      if (this.size <= 1 || (this.size & (this.size - 1)) != 0)
        throw 'FFT size must be a power of two and bigger than 1';

      this._csize = size << 1;

      // NOTE: Use of `var` is intentional for old V8 versions
      var table = new List<num>(this.size * 2);
      for (var i = 0; i < table.length; i += 2) {
        num angle = pi * i / this.size;
        table[i] = cos(angle);
        table[i + 1] = -sin(angle);
      }
      this.table = table;

      // Find size's power of two
      var power = 0;
      for (var t = 1; this.size > t; t <<= 1)
        power++;

      // Calculate initial step's width:
      //   * If we are full radix-4 - it is 2x smaller to give inital len=8
      //   * Otherwise it is the same as `power` to give len=4
      this._width = power % 2 == 0 ? power - 1 : power;

    // Pre-compute bit-reversal patterns
    this._bitrev = new List<int>(1 << this._width);
    for (int j = 0; j < this._bitrev.length; j++) {
    this._bitrev[j] = 0;
    for (int shift = 0; shift < this._width; shift += 2) {
      int revShift = this._width - shift - 2;
      int p1 = (j >> shift);
      int p2 = (p1 & 3);
      int p3 = (revShift < 0)?0:p2 << revShift;
      this._bitrev[j] |= p3;
    }
    }

    this._out = null;
    this._data = null;
    this._inv = 0;
    }
  }

  createComplexArray() {
    List<num> res = new List<num>(this._csize);
    for (int i = 0; i < res.length; i++)
      res[i] = 0;
    return res;
  }

  transform(List<num >out, List<num> data) {
    if (out == data)
      throw 'Input and output buffers must be different';

    this._out = out;
    this._data = data;
    this._inv = 0;
    this._transform4();
    this._out = null;
    this._data = null;
  }

  _singleTransform2(outOff, off,
      step) {
    List<num> out = this._out;
    List<num> data = this._data;

    num evenR = data[off];
    num evenI = data[off + 1];
    num oddR = data[off + step];
    num oddI = data[off + step + 1];

    num leftR = evenR + oddR;
    num leftI = evenI + oddI;
    num rightR = evenR - oddR;
    num rightI = evenI - oddI;

    out[outOff] = leftR;
    out[outOff + 1] = leftI;
    out[outOff + 2] = rightR;
    out[outOff + 3] = rightI;
  }

  _singleTransform4(outOff, off,
      step) {
    List<num> out = this._out;
    List<num> data = this._data;
    int inv = (this._inv!=0) ? -1 : 1;
    int step2 = step * 2;
    int step3 = step * 3;

    // Original values
    num Ar = data[off];
    num Ai = data[off + 1];
    num Br = data[off + step];
    num Bi = data[off + step + 1];
    num Cr = data[off + step2];
    num Ci = data[off + step2 + 1];
    num Dr = data[off + step3];
    num Di = data[off + step3 + 1];

    // Pre-Final values
    num T0r = Ar + Cr;
    num T0i = Ai + Ci;
    num T1r = Ar - Cr;
    num T1i = Ai - Ci;
    num T2r = Br + Dr;
    num T2i = Bi + Di;
    num T3r = inv * (Br - Dr);
    num T3i = inv * (Bi - Di);

    // Final values
    num FAr = T0r + T2r;
    num FAi = T0i + T2i;

    num FBr = T1r + T3i;
    num FBi = T1i - T3r;

    num FCr = T0r - T2r;
    num FCi = T0i - T2i;

    num FDr = T1r - T3i;
    num FDi = T1i + T3r;

    out[outOff] = FAr;
    out[outOff + 1] = FAi;
    out[outOff + 2] = FBr;
    out[outOff + 3] = FBi;
    out[outOff + 4] = FCr;
    out[outOff + 5] = FCi;
    out[outOff + 6] = FDr;
    out[outOff + 7] = FDi;
  }

  _transform4() {
    List<num> out = this._out;
    int size = this._csize;

    // Initial step (permute and transform)
    int width = this._width;
    int step = 1 << width;
    int len = (size ~/ step) << 1;

    int outOff;
    int t = 0;
    List<int> bitrev = this._bitrev;
    if (len == 4) {
      for (outOff = 0; outOff < size; outOff += len, t++) {
        int off = bitrev[t];
        this._singleTransform2(outOff, off, step);
      }
    } else {
      // len === 8
      outOff = 0;
      t = 0;
      for (; outOff < size; outOff += len, t++) {
        int off = bitrev[t];
        this._singleTransform4(outOff, off, step);
      }
    }

    // Loop through steps in decreasing order
    int inv = (this._inv != 0) ? -1 : 1;
    List<num> table = this.table;
    for (step >>= 2; step >= 2; step >>= 2) {
      len = (size ~/ step) << 1;
      int quarterLen = len >> 2;

      // Loop through offsets in the data
      for (outOff = 0; outOff < size; outOff += len) {
      // Full case
        int limit = outOff + quarterLen;
        for (int i = outOff, k = 0; i < limit; i += 2, k += step) {
          int A = i;
          int B = A + quarterLen;
          int C = B + quarterLen;
          int D = C + quarterLen;

          // Original values
          num Ar = out[A];
          num Ai = out[A + 1];
          num Br = out[B];
          num Bi = out[B + 1];
          num Cr = out[C];
          num Ci = out[C + 1];
          num Dr = out[D];
          num Di = out[D + 1];

          // Middle values
          num MAr = Ar;
          num MAi = Ai;

          num tableBr = table[k];
          num tableBi = inv * table[k + 1];
          num MBr = Br * tableBr - Bi * tableBi;
          num MBi = Br * tableBi + Bi * tableBr;

          num tableCr = table[2 * k];
          num tableCi = inv * table[2 * k + 1];
          num MCr = Cr * tableCr - Ci * tableCi;
          num MCi = Cr * tableCi + Ci * tableCr;

          num tableDr = table[3 * k];
          num tableDi = inv * table[3 * k + 1];
          num MDr = Dr * tableDr - Di * tableDi;
          num MDi = Dr * tableDi + Di * tableDr;

          // Pre-Final values
          num T0r = MAr + MCr;
          num T0i = MAi + MCi;
          num T1r = MAr - MCr;
          num T1i = MAi - MCi;
          num T2r = MBr + MDr;
          num T2i = MBi + MDi;
          num T3r = inv * (MBr - MDr);
          num T3i = inv * (MBi - MDi);

          // Final values
          num FAr = T0r + T2r;
          num FAi = T0i + T2i;

          num FCr = T0r - T2r;
          num FCi = T0i - T2i;

          num FBr = T1r + T3i;
          num FBi = T1i - T3r;

          num FDr = T1r - T3i;
          num FDi = T1i + T3r;

          out[A] = FAr;
          out[A + 1] = FAi;
          out[B] = FBr;
          out[B + 1] = FBi;
          out[C] = FCr;
          out[C + 1] = FCi;
          out[D] = FDr;
          out[D + 1] = FDi;
        }
      }
    }
  }
}