program BitmapBilinearInterpolationScale;

uses
   math, sysutils;
type
  TPixel = record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  bmpArray = array of array of TPixel;
  PPixel = ^TPixel;
  PArray = ^bmpArray;
var
  input, output: string;
  scale: real;
  inBmp, outBmp: array of array of TPixel;
  inW, inH, outW, outH, i, j: integer;
  outPixel: TPixel;


function LoadBitmap(filename: string; bmp: bmpArray; var w, h: integer): bmpArray;
var
  inFile: file;
  header: array[0..53] of byte;
  pixelSize: integer;
  rowSize, paddingSize: integer;
  i, j: integer;
begin
  Assign(inFile, filename);
  Reset(inFile, 1);

  { Read bitmap header }
  BlockRead(inFile, header, 54);

  { Get bitmap dimensions }
  w := PInteger(@header[18])^;
  h := PInteger(@header[22])^;

  { Get pixel size and row size }
  pixelSize := PWord(@header[28])^ div 8;
  rowSize := (w * pixelSize + 3) div 4 * 4;
  paddingSize := rowSize - w * pixelSize;

  { Allocate memory for bitmap }
  SetLength(bmp, h, w);
  { Read bitmap pixels }
  for i := h - 1 downto 0 do
  begin
    for j := 0 to w - 1 do
    begin
      BlockRead(inFile, bmp[i][j], pixelSize);
    end;
    if paddingSize > 0 then
    begin
      Seek(inFile, FilePos(inFile) + paddingSize);
    end;
  end;

  Close(inFile);
  LoadBitmap := bmp;
end;

function clamp(x, a, b: byte): byte;
begin
  if x < a then
    clamp := a
  else if x > b then
    clamp := b
  else
    clamp := x;
end;


procedure SaveBitmap(filename: string; bmp: bmpArray);
var
  outFile: file;
  header: array[0..53] of byte;
  pixelSize: integer;
  rowSize, paddingSize: integer;
  i, j: integer;
begin
  Assign(outFile, filename);
  Rewrite(outFile, 1);

  { Set bitmap header }
  FillChar(header, SizeOf(header), 0);
  header[0] := $42;
  header[1] := $4D;
  PInteger(@header[2])^ := SizeOf(header) + Length(bmp[0]) * Length(bmp) * 3;
  header[10] := SizeOf(header);
  header[14] := 40;
  PInteger(@header[18])^ := Length(bmp[0]);
  PInteger(@header[22])^ := Length(bmp);
  PWord(@header[26])^ := 1;
  PWord(@header[28])^ := 24;

  { Get pixel size and row size }
  pixelSize := PWord(@header[28])^ div 8;
  rowSize := (Length(bmp[0]) * pixelSize + 3) div 4 * 4;
  paddingSize := rowSize - Length(bmp[0]) * pixelSize;

  { Write bitmap header }
  BlockWrite(outFile, header, SizeOf(header));

  { Write bitmap pixels }
  for i := Length(bmp) - 1 downto 0 do
  begin
    for j := 0 to Length(bmp[0]) - 1 do
    begin
      BlockWrite(outFile, bmp[i][j], pixelSize);
    end;
    if paddingSize > 0 then
    begin
      FillChar(outPixel, paddingSize, 0);
      BlockWrite(outFile, outPixel, paddingSize);
    end;
  end;
  Close(outFile);
end;

function RotateBitmap(const inBmp: bmpArray; inW, inH: integer; angle: real): bmpArray;
var
x, y, i, j, xx, yy: integer;
cx, cy, sina, cosa: real;
w2, h2: integer;
pixel: TPixel;
begin
  cx := inW / 2;
  cy := inH / 2;
  sina := sin(angle);
  cosa := cos(angle);
  w2 := Round(inW * Abs(cosa) + inH * Abs(sina));
  h2 := Round(inW * Abs(sina) + inH * Abs(cosa));
  outW := w2;
  outH := h2;
  SetLength(outBmp, outH, outW);
  for i := 0 to outH -1 do
  begin
    for j := 0 to outW -1 do
    begin
      x := j - w2 div 2;
      y := h2 div 2 - i;
      xx := Round(cosa * x + sina * y + cx);
      yy := Round(-sina * x + cosa * y + cy);
      if (xx >= 0) and (xx < inW) and (yy >= 0) and (yy < inH) then
      begin
        outBmp[i][j] := inBmp[high(inBmp) - yy][ xx];
      end;
    end;
  end;
  RotateBitmap := outBmp;
end;


function DownScalePixel(var x, y: integer; var scale: real; var inBmp: bmpArray; var inW, inH: integer): TPixel;
var
  i, j: integer;
  dx, dy: real;
  r, g, b: integer;
  a: real;
begin
  if x <= inW then
    dx := x;
  if y <= inH then
    dy := y;
  i := Floor(dy);
  j := Floor(dx);
  a := dx - j;
  r := Round((1 - a) * inBmp[i][j].R + a * inBmp[i][j + 1].R);
  g := Round((1 - a) * inBmp[i][j].G + a * inBmp[i][j + 1].G);
  b := Round((1 - a) * inBmp[i][j].B + a * inBmp[i][j + 1].B);
  outPixel.R := Clamp(Round(r), 0, 255);
  outPixel.G := Clamp(Round(g), 0, 255);
  outPixel.B := Clamp(Round(b), 0, 255);
  DownScalePixel := outPixel;
end;

function UpScalePixel(var x, y: integer; var scale: real; var inBmp: bmpArray; var inW, inH: integer): TPixel;
var
  dx, dy: real;
  r, g, b: integer;
  a: real;
begin
  dx := x / scale;
  dy := y / scale;
  i := Floor(dy);
  j := Floor(dx);
  a := dx - j;
  if i < high(inBmp) then
  begin
    if j < high(inBmp[high(inBmp)]) then
    begin
      r := Round((1 - a) * inBmp[i][j].R + a * inBmp[i][j + 1].R);
      g := Round((1 - a) * inBmp[i][j].G + a * inBmp[i][j + 1].G);
      b := Round((1 - a) * inBmp[i][j].B + a * inBmp[i][j + 1].B);
    end;
  end;
  outPixel.R := Clamp(Round(r), 0, 255);
  outPixel.G := Clamp(Round(g), 0, 255);
  outPixel.B := Clamp(Round(b), 0, 255);
  UpScalePixel := outPixel;
end;

function DownScaleBitmap(inBmp: bmpArray; var inW, inH, outW, outH: integer; var scale: real): bmpArray;
var
  i, j, x, y: integer;
  outPixel: TPixel;
begin
  SetLength(outBmp, outH, outW);
  for i := 0 to outH - 1 do
  begin
    for j := 0 to outW - 1 do
    begin
      x := trunc(j / scale);
      y := trunc(i / scale);
      outPixel :=  DownScalePixel(x, y, scale, inBmp, inW, inH);
      outBmp[i][j] := outPixel;
    end;
  end;
  DownScaleBitmap := outBmp;
end;

function UpScaleBitmap(inBmp: bmpArray; var inW, inH, outW, outH: integer; var scale: real): bmpArray;
var
  r, i, j, x, y: integer;
  inPixel, outPixel: TPixel;
begin
  SetLength(outBmp, outH, outW);
  for i := 0 to outH - 1 do
  begin
     r := 0;
     for j := 0 to inW - 1 do
     begin
        x := round(j * scale);
        y := i; //round(i * scale);
        outPixel :=  UpScalePixel(x, y, scale, inBmp, inW, inH);
        if r < outW then
        begin
           while r < x do
           begin
              outBmp[i][r] := outPixel;
              r := Floor(r + scale);
           end;
        end;
     end;
  end;
  UpScaleBitmap := outBmp;
end;


var
  PixArray: bmpArray;
  arg: string;
  angle: float;

begin
  if ParamCount < 3 then
  begin
    Writeln('Usage: BitmapScaling input.bmp output.bmp scale');
    Halt;
  end;
  arg := ParamStr(1);
  input := ParamStr(2);
  output := ParamStr(3);
  if arg = '-s' then
  begin
  scale := StrToFloat(ParamStr(4));
  PixArray := LoadBitmap(input, inBmp, inW, inH);
  outW := Round(inW * scale);
  outH := Round(inH * scale);
  if StrToFloat(ParamStr(4)) <= 1 then
    outBmp := DownScaleBitmap(PixArray, inW, inH, outW, outH, scale)
  else
    outBmp := UpScaleBitmap(PixArray, inW, inH, outW, outH, scale);
  end;
  if arg = '-r' then
  begin
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    angle := StrtoFloat(ParamStr(4));
    outBmp := RotateBitmap(PixArray, inW, inH, angle);
  SaveBitmap(output, outBmp);
end;
end.
