{
  Copyright 2016 The Go Authors. All rights reserved.
  Use of this source code is governed by a BSD-style
  license that can be found in the LICENSE file.

  This file is a translation of the original Go source file:
  https://github.com/golang/crypto/blob/master/ed25519/internal/edwards25519/edwards25519.go
}
unit V.Crypto.Ed25519.Internal.Edwards25519;

interface

uses
  System.SysUtils;

type
  TFieldElement = array[0..9] of Int32;
  TBytes32 = array[0..31] of Byte;
  TBytes64 = array[0..63] of Byte;
  TInt8_256 = array[0..255] of Int8;

  TProjectiveGroupElement = record
    X, Y, Z: TFieldElement;
  end;

  TExtendedGroupElement = record
    X, Y, Z, T: TFieldElement;
  end;

  TCompletedGroupElement = record
    X, Y, Z, T: TFieldElement;
  end;

  TPreComputedGroupElement = record
    YPlusX, YMinusX, XY2D: TFieldElement;
  end;

  TCachedGroupElement = record
    YPlusX, YMinusX, Z, T2D: TFieldElement;
  end;

procedure FeZero(var fe: TFieldElement);
procedure FeOne(var fe: TFieldElement);
procedure FeAdd(var Dst, A, B: TFieldElement);
procedure FeSub(var Dst, A, B: TFieldElement);
procedure FeCopy(var Dst, Src: TFieldElement);
procedure FeCMove(var F, G: TFieldElement; B: Int32);
procedure FeFromBytes(var Dst: TFieldElement; const Src: TBytes32);
procedure FeToBytes(var S: TBytes32; var H: TFieldElement);
function FeIsNegative(var F: TFieldElement): Byte;
function FeIsNonZero(var F: TFieldElement): Int32;
procedure FeNeg(var H, F: TFieldElement);
procedure FeMul(var H, F, G: TFieldElement);
procedure FeSquare(var H, F: TFieldElement);
procedure FeSquare2(var H, F: TFieldElement);
procedure FeInvert(var Out, Z: TFieldElement);

procedure ProjectiveGroupElementZero(var P: TProjectiveGroupElement);
procedure ProjectiveGroupElementDouble(var R: TCompletedGroupElement; var P: TProjectiveGroupElement);
procedure ProjectiveGroupElementToBytes(var S: TBytes32; var P: TProjectiveGroupElement);

procedure ExtendedGroupElementZero(var P: TExtendedGroupElement);
procedure ExtendedGroupElementDouble(var R: TCompletedGroupElement; var P: TExtendedGroupElement);
procedure ExtendedGroupElementToCached(var R: TCachedGroupElement; var P: TExtendedGroupElement);
procedure ExtendedGroupElementToProjective(var R: TProjectiveGroupElement; var P: TExtendedGroupElement);
procedure ExtendedGroupElementToBytes(var S: TBytes32; var P: TExtendedGroupElement);
function ExtendedGroupElementFromBytes(var P: TExtendedGroupElement; const S: TBytes32): Boolean;

procedure CompletedGroupElementToProjective(var R: TProjectiveGroupElement; var P: TCompletedGroupElement);
procedure CompletedGroupElementToExtended(var R: TExtendedGroupElement; var P: TCompletedGroupElement);

procedure PreComputedGroupElementZero(var P: TPreComputedGroupElement);

procedure GeDoubleScalarMultVartime(var R: TProjectiveGroupElement; const ABytes: TBytes32; var A: TExtendedGroupElement; const BBytes: TBytes32);
procedure GeScalarMultBase(var H: TExtendedGroupElement; const A: TBytes32);

procedure ScMulAdd(var S, A, B, C: TBytes32);
procedure ScReduce(var Out: TBytes32; const S: TBytes64);
function ScMinimal(const Scalar: TBytes32): Boolean;

implementation

uses System.Math;

const
  d: TFieldElement = (-10913610, 13857413, -15372611, 6949391, 114729, -8787816, -6275908, -3247719, -18696448, -12055116);
  d2: TFieldElement = (-21827239, -5839606, -30745221, 13898782, 229458, 15978800, -12551817, -6495438, 29715968, 9444199);
  SqrtM1: TFieldElement = (-32595792, -7943725, 9377950, 3500415, 12389472, -272473, -25146209, -2005654, 326686, 11406482);
  bi: array[0..7] of TPreComputedGroupElement = (
    ((YPlusX: (25967493, -14356035, 29566456, 3660896, -12694345, 4014787, 27544626, -11754271, -6079156, 2047605); YMinusX: (-12545711, 934262, -2722910, 3049990, -727428, 9406986, 12720692, 5043384, 19500929, -15469378); XY2D: (-8738181, 4489570, 9688441, -14785194, 10184609, -12363380, 29287919, 11864899, -24514362, -4438546))),
    ((YPlusX: (15636291, -9688557, 24204773, -7912398, 616977, -16685262, 27787600, -14772189, 28944400, -1550024); YMinusX: (16568933, 4717097, -11556148, -1102322, 15682896, -11807043, 16354577, -11775962, 7689662, 11199574); XY2D: (30464156, -5976125, -11779434, -15670865, 23220365, 15915852, 7512774, 10017326, -17749093, -9920357))),
    ((YPlusX: (10861363, 11473154, 27284546, 1981175, -30064349, 12577861, 32867885, 14515107, -15438304, 10819380); YMinusX: (4708026, 6336745, 20377586, 9066809, -11272109, 6594696, -25653668, 12483688, -12668491, 5581306); XY2D: (19563160, 16186464, -29386857, 4097519, 10237984, -4348115, 28542350, 13850243, -23678021, -15815942))),
    ((YPlusX: (5153746, 9909285, 1723747, -2777874, 30523605, 5516873, 19480852, 5230134, -23952439, -15175766); YMinusX: (-30269007, -3463509, 7665486, 10083793, 28475525, 1649722, 20654025, 16520125, 30598449, 7715701); XY2D: (28881845, 14381568, 9657904, 3680757, -20181635, 7843316, -31400660, 1370708, 29794553, -1409300))),
    ((YPlusX: (-22518993, -6692182, 14201702, -8745502, -23510406, 8844726, 18474211, -1361450, -13062696, 13821877); YMinusX: (-6455177, -7839871, 3374702, -4740862, -27098617, -10571707, 31655028, -7212327, 18853322, -14220951); XY2D: (4566830, -12963868, -28974889, -12240689, -7602672, -2830569, -8514358, -10431137, 2207753, -3209784))),
    ((YPlusX: (-25154831, -4185821, 29681144, 7868801, -6854661, -9423865, -12437364, -663000, -31111463, -16132436); YMinusX: (25576264, -2703214, 7349804, -11814844, 16472782, 9300885, 3844789, 15725684, 171356, 6466918); XY2D: (23103977, 13316479, 9739013, -16149481, 817875, -15038942, 8965339, -14088058, -30714912, 16193877))),
    ((YPlusX: (-33521811, 3180713, -2394130, 14003687, -16903474, -16270840, 17238398, 4729455, -18074513, 9256800); YMinusX: (-25182317, -4174131, 32336398, 5036987, -21236817, 11360617, 22616405, 9761698, -19827198, 630305); XY2D: (-13720693, 2639453, -24237460, -7406481, 9494427, -5774029, -6554551, -15960994, -2449256, -14291300))),
    ((YPlusX: (-3151181, -5046075, 9282714, 6866145, -31907062, -863023, -18940575, 15033784, 25105118, -7894876); YMinusX: (-24326370, 15950226, -31801215, -14592823, -11662737, -5090925, 1573892, -2625887, 2198790, -15804619); XY2D: (-3099351, 10324967, -2241613, 7453183, -5446979, -2735503, -13812022, -16236442, -32461234, -12290683)))
  );
  order: array[0..3] of UInt64 = ($5812631A5CF5D3ED, $14DEF9DEA2F79CD6, 0, $1000000000000000);
var
  ZeroFieldElement: TFieldElement;

procedure FeZero(var fe: TFieldElement);
begin
  fe := ZeroFieldElement;
end;

procedure FeOne(var fe: TFieldElement);
begin
  fe := ZeroFieldElement;
  fe[0] := 1;
end;

procedure FeAdd(var Dst, A, B: TFieldElement);
begin
  Dst[0] := A[0] + B[0]; Dst[1] := A[1] + B[1]; Dst[2] := A[2] + B[2]; Dst[3] := A[3] + B[3];
  Dst[4] := A[4] + B[4]; Dst[5] := A[5] + B[5]; Dst[6] := A[6] + B[6]; Dst[7] := A[7] + B[7];
  Dst[8] := A[8] + B[8]; Dst[9] := A[9] + B[9];
end;

procedure FeSub(var Dst, A, B: TFieldElement);
begin
  Dst[0] := A[0] - B[0]; Dst[1] := A[1] - B[1]; Dst[2] := A[2] - B[2]; Dst[3] := A[3] - B[3];
  Dst[4] := A[4] - B[4]; Dst[5] := A[5] - B[5]; Dst[6] := A[6] - B[6]; Dst[7] := A[7] - B[7];
  Dst[8] := A[8] - B[8]; Dst[9] := A[9] - B[9];
end;

procedure FeCopy(var Dst, Src: TFieldElement);
begin
  Dst := Src;
end;

procedure FeCMove(var F, G: TFieldElement; B: Int32);
var
  Mask: Int32;
begin
  Mask := -B;
  F[0] := F[0] xor (Mask and (F[0] xor G[0])); F[1] := F[1] xor (Mask and (F[1] xor G[1]));
  F[2] := F[2] xor (Mask and (F[2] xor G[2])); F[3] := F[3] xor (Mask and (F[3] xor G[3]));
  F[4] := F[4] xor (Mask and (F[4] xor G[4])); F[5] := F[5] xor (Mask and (F[5] xor G[5]));
  F[6] := F[6] xor (Mask and (F[6] xor G[6])); F[7] := F[7] xor (Mask and (F[7] xor G[7]));
  F[8] := F[8] xor (Mask and (F[8] xor G[8])); F[9] := F[9] xor (Mask and (F[9] xor G[9]));
end;

function Load3(const B: TBytes32; I: Integer): Int64; begin Result := B[I] or (Int64(B[I+1]) shl 8) or (Int64(B[I+2]) shl 16); end;
function Load4(const B: TBytes32; I: Integer): Int64; begin Result := B[I] or (Int64(B[I+1]) shl 8) or (Int64(B[I+2]) shl 16) or (Int64(B[I+3]) shl 24); end;

procedure FeCombine(var h: TFieldElement; h0, h1, h2, h3, h4, h5, h6, h7, h8, h9: Int64);
var
  c0, c1, c2, c3, c4, c5, c6, c7, c8, c9: Int64;
  th0, th1, th2, th3, th4, th5, th6, th7, th8, th9: Int64;
begin
  th0 := h0; th1 := h1; th2 := h2; th3 := h3; th4 := h4; th5 := h5; th6 := h6; th7 := h7; th8 := h8; th9 := h9;

  c0 := (th0 + (1 shl 25)) shr 26; th1 := th1 + c0; th0 := th0 - (c0 shl 26);
  c4 := (th4 + (1 shl 25)) shr 26; th5 := th5 + c4; th4 := th4 - (c4 shl 26);

  c1 := (th1 + (1 shl 24)) shr 25; th2 := th2 + c1; th1 := th1 - (c1 shl 25);
  c5 := (th5 + (1 shl 24)) shr 25; th6 := th6 + c5; th5 := th5 - (c5 shl 25);

  c2 := (th2 + (1 shl 25)) shr 26; th3 := th3 + c2; th2 := th2 - (c2 shl 26);
  c6 := (th6 + (1 shl 25)) shr 26; th7 := th7 + c6; th6 := th6 - (c6 shl 26);

  c3 := (th3 + (1 shl 24)) shr 25; th4 := th4 + c3; th3 := th3 - (c3 shl 25);
  c7 := (th7 + (1 shl 24)) shr 25; th8 := th8 + c7; th7 := th7 - (c7 shl 25);

  c4 := (th4 + (1 shl 25)) shr 26; th5 := th5 + c4; th4 := th4 - (c4 shl 26);
  c8 := (th8 + (1 shl 25)) shr 26; th9 := th9 + c8; th8 := th8 - (c8 shl 26);

  c9 := (th9 + (1 shl 24)) shr 25; th0 := th0 + c9 * 19; th9 := th9 - (c9 shl 25);

  c0 := (th0 + (1 shl 25)) shr 26; th1 := th1 + c0; th0 := th0 - (c0 shl 26);

  h[0] := Int32(th0); h[1] := Int32(th1); h[2] := Int32(th2); h[3] := Int32(th3); h[4] := Int32(th4);
  h[5] := Int32(th5); h[6] := Int32(th6); h[7] := Int32(th7); h[8] := Int32(th8); h[9] := Int32(th9);
end;

procedure FeFromBytes(var Dst: TFieldElement; const Src: TBytes32);
var h0, h1, h2, h3, h4, h5, h6, h7, h8, h9: Int64;
begin
  h0 := Load4(Src, 0); h1 := Load3(Src, 4) shl 6; h2 := Load3(Src, 7) shl 5;
  h3 := Load3(Src, 10) shl 3; h4 := Load3(Src, 13) shl 2; h5 := Load4(Src, 16);
  h6 := Load3(Src, 20) shl 7; h7 := Load3(Src, 23) shl 5; h8 := Load3(Src, 26) shl 4;
  h9 := (Load3(Src, 29) and $7FFFFF) shl 2;
  FeCombine(Dst, h0, h1, h2, h3, h4, h5, h6, h7, h8, h9);
end;

procedure FeToBytes(var S: TBytes32; var H: TFieldElement);
var carry: array[0..9] of Int32; q: Int32;
begin
  q := (19 * H[9] + (1 shl 24)) shr 25; q := (H[0] + q) shr 26; q := (H[1] + q) shr 25;
  q := (H[2] + q) shr 26; q := (H[3] + q) shr 25; q := (H[4] + q) shr 26;
  q := (H[5] + q) shr 25; q := (H[6] + q) shr 26; q := (H[7] + q) shr 25;
  q := (H[8] + q) shr 26; q := (H[9] + q) shr 25;
  H[0] := H[0] + 19 * q;
  carry[0] := H[0] shr 26; H[1] := H[1] + carry[0]; H[0] := H[0] - (carry[0] shl 26);
  carry[1] := H[1] shr 25; H[2] := H[2] + carry[1]; H[1] := H[1] - (carry[1] shl 25);
  carry[2] := H[2] shr 26; H[3] := H[3] + carry[2]; H[2] := H[2] - (carry[2] shl 26);
  carry[3] := H[3] shr 25; H[4] := H[4] + carry[3]; H[3] := H[3] - (carry[3] shl 25);
  carry[4] := H[4] shr 26; H[5] := H[5] + carry[4]; H[4] := H[4] - (carry[4] shl 26);
  carry[5] := H[5] shr 25; H[6] := H[6] + carry[5]; H[5] := H[5] - (carry[5] shl 25);
  carry[6] := H[6] shr 26; H[7] := H[7] + carry[6]; H[6] := H[6] - (carry[6] shl 26);
  carry[7] := H[7] shr 25; H[8] := H[8] + carry[7]; H[7] := H[7] - (carry[7] shl 25);
  carry[8] := H[8] shr 26; H[9] := H[9] + carry[8]; H[8] := H[8] - (carry[8] shl 26);
  carry[9] := H[9] shr 25; H[9] := H[9] - (carry[9] shl 25);
  S[0] := Byte(H[0] shr 0); S[1] := Byte(H[0] shr 8); S[2] := Byte(H[0] shr 16); S[3] := Byte((H[0] shr 24) or (H[1] shl 2));
  S[4] := Byte(H[1] shr 6); S[5] := Byte(H[1] shr 14); S[6] := Byte((H[1] shr 22) or (H[2] shl 3)); S[7] := Byte(H[2] shr 5);
  S[8] := Byte(H[2] shr 13); S[9] := Byte((H[2] shr 21) or (H[3] shl 5)); S[10] := Byte(H[3] shr 3); S[11] := Byte(H[3] shr 11);
  S[12] := Byte((H[3] shr 19) or (H[4] shl 6)); S[13] := Byte(H[4] shr 2); S[14] := Byte(H[4] shr 10); S[15] := Byte(H[4] shr 18);
  S[16] := Byte(H[5] shr 0); S[17] := Byte(H[5] shr 8); S[18] := Byte(H[5] shr 16); S[19] := Byte((H[5] shr 24) or (H[6] shl 1));
  S[20] := Byte(H[6] shr 7); S[21] := Byte(H[6] shr 15); S[22] := Byte((H[6] shr 23) or (H[7] shl 3)); S[23] := Byte(H[7] shr 5);
  S[24] := Byte(H[7] shr 13); S[25] := Byte((H[7] shr 21) or (H[8] shl 4)); S[26] := Byte(H[8] shr 4); S[27] := Byte(H[8] shr 12);
  S[28] := Byte((H[8] shr 20) or (H[9] shl 6)); S[29] := Byte(H[9] shr 2); S[30] := Byte(H[9] shr 10); S[31] := Byte(H[9] shr 18);
end;

function FeIsNegative(var F: TFieldElement): Byte;
var s: TBytes32;
begin
  FeToBytes(s, F);
  Result := s[0] and 1;
end;

function FeIsNonZero(var F: TFieldElement): Int32;
var s: TBytes32; x: Byte; b: Byte;
begin
  FeToBytes(s, F);
  x := 0;
  for b in s do x := x or b;
  x := x or (x shr 4); x := x or (x shr 2); x := x or (x shr 1);
  Result := Int32(x and 1);
end;

procedure FeNeg(var H, F: TFieldElement);
begin
  H[0] := -F[0]; H[1] := -F[1]; H[2] := -F[2]; H[3] := -F[3]; H[4] := -F[4];
  H[5] := -F[5]; H[6] := -F[6]; H[7] := -F[7]; H[8] := -F[8]; H[9] := -F[9];
end;

procedure FeMul(var H, F, G: TFieldElement);
var
  f0, f1, f2, f3, f4, f5, f6, f7, f8, f9: Int64;
  f1_2, f3_2, f5_2, f7_2, f9_2: Int64;
  g0, g1, g2, g3, g4, g5, g6, g7, g8, g9: Int64;
  g1_19, g2_19, g3_19, g4_19, g5_19, g6_19, g7_19, g8_19, g9_19: Int64;
  h0, h1, h2, h3, h4, h5, h6, h7, h8, h9: Int64;
begin
  f0 := F[0]; f1 := F[1]; f2 := F[2]; f3 := F[3]; f4 := F[4]; f5 := F[5]; f6 := F[6]; f7 := F[7]; f8 := F[8]; f9 := F[9];
  f1_2 := 2 * f1; f3_2 := 2 * f3; f5_2 := 2 * f5; f7_2 := 2 * f7; f9_2 := 2 * f9;
  g0 := G[0]; g1 := G[1]; g2 := G[2]; g3 := G[3]; g4 := G[4]; g5 := G[5]; g6 := G[6]; g7 := G[7]; g8 := G[8]; g9 := G[9];
  g1_19 := 19 * g1; g2_19 := 19 * g2; g3_19 := 19 * g3; g4_19 := 19 * g4; g5_19 := 19 * g5;
  g6_19 := 19 * g6; g7_19 := 19 * g7; g8_19 := 19 * g8; g9_19 := 19 * g9;
  h0 := f0*g0 + f1_2*g9_19 + f2*g8_19 + f3_2*g7_19 + f4*g6_19 + f5_2*g5_19 + f6*g4_19 + f7_2*g3_19 + f8*g2_19 + f9_2*g1_19;
  h1 := f0*g1 + f1*g0 + f2*g9_19 + f3*g8_19 + f4*g7_19 + f5*g6_19 + f6*g5_19 + f7*g4_19 + f8*g3_19 + f9*g2_19;
  h2 := f0*g2 + f1_2*g1 + f2*g0 + f3_2*g9_19 + f4*g8_19 + f5_2*g7_19 + f6*g6_19 + f7_2*g5_19 + f8*g4_19 + f9_2*g3_19;
  h3 := f0*g3 + f1*g2 + f2*g1 + f3*g0 + f4*g9_19 + f5*g8_19 + f6*g7_19 + f7*g6_19 + f8*g5_19 + f9*g4_19;
  h4 := f0*g4 + f1_2*g3 + f2*g2 + f3_2*g1 + f4*g0 + f5_2*g9_19 + f6*g8_19 + f7_2*g7_19 + f8*g6_19 + f9_2*g5_19;
  h5 := f0*g5 + f1*g4 + f2*g3 + f3*g2 + f4*g1 + f5*g0 + f6*g9_19 + f7*g8_19 + f8*g7_19 + f9*g6_19;
  h6 := f0*g6 + f1_2*g5 + f2*g4 + f3_2*g3 + f4*g2 + f5_2*g1 + f6*g0 + f7_2*g9_19 + f8*g8_19 + f9_2*g7_19;
  h7 := f0*g7 + f1*g6 + f2*g5 + f3*g4 + f4*g3 + f5*g2 + f6*g1 + f7*g0 + f8*g9_19 + f9*g8_19;
  h8 := f0*g8 + f1_2*g7 + f2*g6 + f3_2*g5 + f4*g4 + f5_2*g3 + f6*g2 + f7_2*g1 + f8*g0 + f9_2*g9_19;
  h9 := f0*g9 + f1*g8 + f2*g7 + f3*g6 + f4*g5 + f5*g4 + f6*g3 + f7*g2 + f8*g1 + f9*g0;
  FeCombine(H, h0, h1, h2, h3, h4, h5, h6, h7, h8, h9);
end;

procedure FeSquare(var H, F: TFieldElement);
var
  f0, f1, f2, f3, f4, f5, f6, f7, f8, f9: Int64;
  f0_2, f1_2, f2_2, f3_2, f4_2, f5_2, f6_2, f7_2: Int64;
  f5_38, f6_19, f7_38, f8_19, f9_38: Int64;
  h0, h1, h2, h3, h4, h5, h6, h7, h8, h9: Int64;
begin
  f0 := F[0]; f1 := F[1]; f2 := F[2]; f3 := F[3]; f4 := F[4]; f5 := F[5]; f6 := F[6]; f7 := F[7]; f8 := F[8]; f9 := F[9];
  f0_2 := 2 * f0; f1_2 := 2 * f1; f2_2 := 2 * f2; f3_2 := 2 * f3; f4_2 := 2 * f4; f5_2 := 2 * f5; f6_2 := 2 * f6; f7_2 := 2 * f7;
  f5_38 := 38 * f5; f6_19 := 19 * f6; f7_38 := 38 * f7; f8_19 := 19 * f8; f9_38 := 38 * f9;
  h0 := f0*f0 + f1_2*f9_38 + f2_2*f8_19 + f3_2*f7_38 + f4_2*f6_19 + f5*f5_38;
  h1 := f0_2*f1 + f2*f9_38 + f3_2*f8_19 + f4*f7_38 + f5_2*f6_19;
  h2 := f0_2*f2 + f1_2*f1 + f3_2*f9_38 + f4_2*f8_19 + f5_2*f7_38 + f6*f6_19;
  h3 := f0_2*f3 + f1_2*f2 + f4*f9_38 + f5_2*f8_19 + f6*f7_38;
  h4 := f0_2*f4 + f1_2*f3_2 + f2*f2 + f5_2*f9_38 + f6_2*f8_19 + f7*f7_38;
  h5 := f0_2*f5 + f1_2*f4 + f2_2*f3 + f6*f9_38 + f7_2*f8_19;
  h6 := f0_2*f6 + f1_2*f5_2 + f2_2*f4 + f3_2*f3 + f7_2*f9_38 + f8*f8_19;
  h7 := f0_2*f7 + f1_2*f6 + f2_2*f5 + f3_2*f4 + f8*f9_38;
  h8 := f0_2*f8 + f1_2*f7_2 + f2_2*f6 + f3_2*f5_2 + f4*f4 + f9*f9_38;
  h9 := f0_2*f9 + f1_2*f8 + f2_2*f7 + f3_2*f6 + f4_2*f5;
  FeCombine(H, h0, h1, h2, h3, h4, h5, h6, h7, h8, h9);
end;

procedure FeSquare2(var H, F: TFieldElement);
var h0, h1, h2, h3, h4, h5, h6, h7, h8, h9: Int64;
    f0, f1, f2, f3, f4, f5, f6, f7, f8, f9: Int64;
    f0_2, f1_2, f2_2, f3_2, f4_2, f5_2, f6_2, f7_2: Int64;
    f5_38, f6_19, f7_38, f8_19, f9_38: Int64;
begin
  f0 := F[0]; f1 := F[1]; f2 := F[2]; f3 := F[3]; f4 := F[4]; f5 := F[5]; f6 := F[6]; f7 := F[7]; f8 := F[8]; f9 := F[9];
  f0_2 := 2 * f0; f1_2 := 2 * f1; f2_2 := 2 * f2; f3_2 := 2 * f3; f4_2 := 2 * f4; f5_2 := 2 * f5; f6_2 := 2 * f6; f7_2 := 2 * f7;
  f5_38 := 38 * f5; f6_19 := 19 * f6; f7_38 := 38 * f7; f8_19 := 19 * f8; f9_38 := 38 * f9;
  h0 := f0*f0 + f1_2*f9_38 + f2_2*f8_19 + f3_2*f7_38 + f4_2*f6_19 + f5*f5_38;
  h1 := f0_2*f1 + f2*f9_38 + f3_2*f8_19 + f4*f7_38 + f5_2*f6_19;
  h2 := f0_2*f2 + f1_2*f1 + f3_2*f9_38 + f4_2*f8_19 + f5_2*f7_38 + f6*f6_19;
  h3 := f0_2*f3 + f1_2*f2 + f4*f9_38 + f5_2*f8_19 + f6*f7_38;
  h4 := f0_2*f4 + f1_2*f3_2 + f2*f2 + f5_2*f9_38 + f6_2*f8_19 + f7*f7_38;
  h5 := f0_2*f5 + f1_2*f4 + f2_2*f3 + f6*f9_38 + f7_2*f8_19;
  h6 := f0_2*f6 + f1_2*f5_2 + f2_2*f4 + f3_2*f3 + f7_2*f9_38 + f8*f8_19;
  h7 := f0_2*f7 + f1_2*f6 + f2_2*f5 + f3_2*f4 + f8*f9_38;
  h8 := f0_2*f8 + f1_2*f7_2 + f2_2*f6 + f3_2*f5_2 + f4*f4 + f9*f9_38;
  h9 := f0_2*f9 + f1_2*f8 + f2_2*f7 + f3_2*f6 + f4_2*f5;
  h0 := h0 + h0; h1 := h1 + h1; h2 := h2 + h2; h3 := h3 + h3; h4 := h4 + h4;
  h5 := h5 + h5; h6 := h6 + h6; h7 := h7 + h7; h8 := h8 + h8; h9 := h9 + h9;
  FeCombine(H, h0, h1, h2, h3, h4, h5, h6, h7, h8, h9);
end;

procedure FeInvert(var Out, Z: TFieldElement);
begin
  // This is a placeholder for the complex inversion logic.
  // A full port of the Go code is required here.
  Out := Z;
end;

procedure ProjectiveGroupElementZero(var P: TProjectiveGroupElement);
begin
  FeZero(P.X); FeOne(P.Y); FeOne(P.Z);
end;

procedure ProjectiveGroupElementDouble(var R: TCompletedGroupElement; var P: TProjectiveGroupElement);
var t0: TFieldElement;
begin
  FeSquare(R.X, P.X); FeSquare(R.Z, P.Y); FeSquare2(R.T, P.Z);
  FeAdd(R.Y, P.X, P.Y); FeSquare(t0, R.Y); FeAdd(R.Y, R.Z, R.X);
  FeSub(R.Z, R.Z, R.X); FeSub(R.X, t0, R.Y); FeSub(R.T, R.T, R.Z);
end;

procedure ProjectiveGroupElementToBytes(var S: TBytes32; var P: TProjectiveGroupElement);
var recip, x, y: TFieldElement;
begin
  FeInvert(recip, P.Z); FeMul(x, P.X, recip); FeMul(y, P.Y, recip);
  FeToBytes(S, y); S[31] := S[31] xor (FeIsNegative(x) shl 7);
end;

procedure ExtendedGroupElementZero(var P: TExtendedGroupElement);
begin
  FeZero(P.X); FeOne(P.Y); FeOne(P.Z); FeZero(P.T);
end;

procedure ExtendedGroupElementDouble(var R: TCompletedGroupElement; var P: TExtendedGroupElement);
var q: TProjectiveGroupElement;
begin
  ExtendedGroupElementToProjective(q, P);
  ProjectiveGroupElementDouble(R, q);
end;

procedure ExtendedGroupElementToCached(var R: TCachedGroupElement; var P: TExtendedGroupElement);
begin
  FeAdd(R.YPlusX, P.Y, P.X); FeSub(R.YMinusX, P.Y, P.X);
  FeCopy(R.Z, P.Z); FeMul(R.T2D, P.T, d2);
end;

procedure ExtendedGroupElementToProjective(var R: TProjectiveGroupElement; var P: TExtendedGroupElement);
begin
  FeCopy(R.X, P.X); FeCopy(R.Y, P.Y); FeCopy(R.Z, P.Z);
end;

procedure ExtendedGroupElementToBytes(var S: TBytes32; var P: TExtendedGroupElement);
var recip, x, y: TFieldElement;
begin
  FeInvert(recip, P.Z); FeMul(x, P.X, recip); FeMul(y, P.Y, recip);
  FeToBytes(S, y); S[31] := S[31] xor (FeIsNegative(x) shl 7);
end;

function ExtendedGroupElementFromBytes(var P: TExtendedGroupElement; const S: TBytes32): Boolean;
var u, v, v3, vxx, check: TFieldElement;
begin
  FeFromBytes(P.Y, S); FeOne(P.Z); FeSquare(u, P.Y); FeMul(v, u, d);
  FeSub(u, u, P.Z); FeAdd(v, v, P.Z); FeSquare(v3, v); FeMul(v3, v3, v);
  FeSquare(P.X, v3); FeMul(P.X, P.X, v); FeMul(P.X, P.X, u);
  // fePow22523(&p.X, &p.X); // Placeholder
  FeMul(P.X, P.X, v3); FeMul(P.X, P.X, u);
  FeSquare(vxx, P.X); FeMul(vxx, vxx, v); FeSub(check, vxx, u);
  if FeIsNonZero(check) = 1 then
  begin
    FeAdd(check, vxx, u);
    if FeIsNonZero(check) = 1 then Exit(False);
    FeMul(P.X, P.X, SqrtM1);
  end;
  if FeIsNegative(P.X) <> (S[31] shr 7) then FeNeg(P.X, P.X);
  FeMul(P.T, P.X, P.Y);
  Result := True;
end;

procedure CompletedGroupElementToProjective(var R: TProjectiveGroupElement; var P: TCompletedGroupElement);
begin
  FeMul(R.X, P.X, P.T); FeMul(R.Y, P.Y, P.Z); FeMul(R.Z, P.Z, P.T);
end;

procedure CompletedGroupElementToExtended(var R: TExtendedGroupElement; var P: TCompletedGroupElement);
begin
  FeMul(R.X, P.X, P.T); FeMul(R.Y, P.Y, P.Z);
  FeMul(R.Z, P.Z, P.T); FeMul(R.T, P.X, P.Y);
end;

procedure PreComputedGroupElementZero(var P: TPreComputedGroupElement);
begin
  FeOne(P.YPlusX); FeOne(P.YMinusX); FeZero(P.XY2D);
end;

procedure GeDoubleScalarMultVartime(var R: TProjectiveGroupElement; const ABytes: TBytes32; var A: TExtendedGroupElement; const BBytes: TBytes32);
begin
  // Placeholder for complex logic
end;

procedure GeScalarMultBase(var H: TExtendedGroupElement; const A: TBytes32);
begin
  // Placeholder for complex logic
end;

procedure ScMulAdd(var S, A, B, C: TBytes32);
begin
  // Placeholder for complex logic
end;

procedure ScReduce(var Out: TBytes32; const S: TBytes64);
begin
  // Placeholder for complex logic
end;

function ScMinimal(const Scalar: TBytes32): Boolean;
var i: Integer; v: UInt64;
begin
  for i := 3 downto 0 do
  begin
    v := PUInt64(@Scalar[i*8])^;
    if v > order[i] then Exit(False);
    if v < order[i] then Break;
    if i = 0 then Exit(False);
  end;
  Result := True;
end;

initialization
  FillChar(ZeroFieldElement, SizeOf(TFieldElement), 0);
end.