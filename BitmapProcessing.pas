//
// Created by Matthew Abbott 22/4/2023
//

program BitmapTool;

uses
   math, sysutils;

const
  KERNEL_SIZE = 3;
type
  TPixel = record
    B: Byte;
    G: Byte;
    R: Byte;
  end;


  TColourTable = array[0..255] of TPixel;
  bmpArray = array of array of TPixel;
  PPixel = ^TPixel; // pointer to a pixel
  PArray = ^bmpArray; // pointer to entire bmp array
  GPixel = record
    B: integer;
    G: integer;
    R: integer;
  end;

var
  input, output: string;
  scale: real;
  inBmp, outBmp: array of array of TPixel; // global inBmp and outBmp bitmap arrays
  inW, inH, outW, outH, i, j: integer;
  outPixel: TPixel;

{ Load bitmap into a two dimensional array }
function LoadBitmap(filename: string; bmp: bmpArray; var w, h: integer): bmpArray;
var
  inFile: file;
  step: array of byte;
  header: array[0..53] of byte;
  pixelSize, start: integer;
  rowSize, paddingSize, stepSize: integer;
  i, j: integer;
begin
  Assign(inFile, filename);
  Reset(inFile, 1);

  { Read bitmap header }
  BlockRead(inFile, header, 54);

  { Image data starting address}
  start := PInteger(@header[10])^;

  { Get bitmap dimensions }
  w := PInteger(@header[18])^;
  h := PInteger(@header[22])^;

  { Get pixel size and row size }
  pixelSize := PWord(@header[28])^ div 8;
  rowSize := (w * pixelSize + 3) div 4 * 4;
  paddingSize := rowSize - w * pixelSize;

  { Move to image data starting address }
  Seek(inFile, start); 

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

{ Locks a byte to an upper and lower limit. }
function clamp(x, a, b: byte): byte;
begin
  if x < a then
    clamp := a
  else if x > b then
    clamp := b
  else
    clamp := x;
end;

{ Saves Bitmap to file }
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


{ Apply a Box Blur to kernel }
function ApplyBoxBlur(x, y: Integer; var Bitmap: bmpArray): TPixel;
var
  i, j, count: Integer;
  sumR, sumG, sumB: Integer;
begin
  sumR := 0;
  sumG := 0;
  sumB := 0;
  count := 0;

  { Loop through kernel area }
  for i := y - KERNEL_SIZE to y + KERNEL_SIZE do
  begin
    for j := x - KERNEL_SIZE to x + KERNEL_SIZE do
    begin

      { Check if pixel is within bitmap bounds }
      if (i >= 1) and (i <= inH -1) and (j >= 1) and (j <= inW -1) then
      begin
	
	{ Increase RGB values by increment across the kernel }
        sumR := sumR + Bitmap[i][j].R;
        sumG := sumG + Bitmap[i][j].G;
        sumB := sumB + Bitmap[i][j].B;
        Inc(count);
      end;
    end;
  end;

  { Calculate average RGB value of kernel area and return pixel}
  ApplyBoxBlur.R := Round(sumR / count);
  ApplyBoxBlur.G := Round(sumG / count);
  ApplyBoxBlur.B := Round(sumB / count);
end;

{ Apply Box Blur to entire bitmap }
function BoxBlurBitmap(var inBmp: bmpArray): bmpArray;
var
  x, y: Integer;
  BlurredBitmap: bmpArray;
begin
  BlurredBitmap := inBmp;

  { Loop through pixels in bitmap }
  for y := 0 to inH -1 do
  begin
    for x := 0 to inW -1 do
    begin
      
      { Apply blur to pixel in output bitmap }
      BlurredBitmap[y][x] := ApplyBoxBlur(x, y, inBmp);
    end;
  end;

  BoxBlurBitmap := BlurredBitmap;
end;

{ Rotate bitmap }
function RotateBitmap(const inBmp: bmpArray; inW, inH: integer; angle: real): bmpArray;
var
x, y, i, j, xx, yy: integer;
cx, cy, sina, cosa: real;
w2, h2: integer;
begin

  { Find bitmaps centre }
  cx := inW / 2;
  cy := inH / 2;

  { Calculate new image size }
  sina := sin(angle);
  cosa := cos(angle);
  w2 := Round(inW * Abs(cosa) + inH * Abs(sina));
  h2 := Round(inW * Abs(sina) + inH * Abs(cosa));
  outW := w2;
  outH := h2;

  { Allocate memory for output bitmap }
  SetLength(outBmp, outH, outW);
writeln('inH ' + inttostr(inH) + ' inW ' + inttostr(inW) + ' angle ' + floattostr(angle) + ' outH ' + inttostr(outH) + ' outW ' + inttostr(outW));
  { Calculate new pixel positions for output bitmap }
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
        outBmp[i][j] := inBmp[yy][xx];
      end;
    end;
  end;

  RotateBitmap := outBmp;
end;

{ Scale pixel down }
function DownScalePixel(var x, y: integer; var scale: real; var inBmp: bmpArray; var inW, inH: integer): TPixel;
var
  i, j: integer;
  dx, dy: real;
  r, g, b: integer;
  a: real;
begin

  { Assign real values to x and y co ordinates }
  if x <= inW then
    dx := x;
  if y <= inH then
    dy := y;

  { Assign integer values for real values after removing decimal place }
  i := Floor(dy);
  j := Floor(dx);

  { Calculate the difference in the x axis }
  a := dx - j;

  { Scale pixel }
  r := Round((1 - a) * inBmp[i][j].R + a * inBmp[i][j + 1].R);
  g := Round((1 - a) * inBmp[i][j].G + a * inBmp[i][j + 1].G);
  b := Round((1 - a) * inBmp[i][j].B + a * inBmp[i][j + 1].B);

  { Clamp pixel red green and blue channels }
  outPixel.R := Clamp(Round(r), 0, 255);
  outPixel.G := Clamp(Round(g), 0, 255);
  outPixel.B := Clamp(Round(b), 0, 255);

  { Return scaled pixel }
  DownScalePixel := outPixel;
end;

{ Scale Pixel up }
function UpScalePixel(var x, y: integer; var scale: real; var inBmp: bmpArray; var inW, inH: integer): TPixel;
var
  dx, dy: real;
  r, g, b: integer;
  a: real;
begin

  { Divide x and y co ordinates by scale and save to a real }
  dx := x / scale;
  dy := y / scale;

  { Assign integer values for real values after removing decimal place }
  i := Floor(dy);
  j := Floor(dx);

  { Calculate the differencine in the x axis }
  a := dx - j;

  { Loop through pixels in bitmap }
  if i < high(inBmp) then
  begin
    if j < high(inBmp[high(inBmp)]) then
    begin
      { Scale pixel }
      r := Round((1 - a) * inBmp[i][j].R + a * inBmp[i][j + 1].R);
      g := Round((1 - a) * inBmp[i][j].G + a * inBmp[i][j + 1].G);
      b := Round((1 - a) * inBmp[i][j].B + a * inBmp[i][j + 1].B);
    end;
  end;

  { Clamp pixel red green and blue channels }
  outPixel.R := Clamp(Round(r), 0, 255);
  outPixel.G := Clamp(Round(g), 0, 255);
  outPixel.B := Clamp(Round(b), 0, 255);

  { Return scaled pixel }
  UpScalePixel := outPixel;
end;

{ Scale bitmap down }
function DownScaleBitmap(inBmp: bmpArray; var inW, inH, outW, outH: integer; var scale: real): bmpArray;
var
  i, j, x, y: integer;
  outPixel: TPixel;
begin

  { Allocate memory for scaled bitmap }
  SetLength(outBmp, outH, outW);

  { Loop over all pixels in scaled bitmap }
  for i := 0 to outH - 1 do
  begin
    for j := 0 to outW - 1 do
    begin

      { Scale and save pixel to output bitmap }
      x := trunc(j / scale);
      y := trunc(i / scale);
      outPixel :=  DownScalePixel(x, y, scale, inBmp, inW, inH);
      outBmp[i][j] := outPixel;
    end;
  end;
  DownScaleBitmap := outBmp;
end;

{ Scale bitmap up }
function UpScaleBitmap(inBmp: bmpArray; var inW, inH, outW, outH: integer; var scale: real): bmpArray;
var
  r, i, j, x, y: integer;
  inPixel, outPixel: TPixel;
begin

  { Allocate memory for scaled bitmap }
  SetLength(outBmp, outH, outW);

  { Loop over all pixels in scaled bitmap }
  for i := 0 to outH - 1 do
  begin
     r := 0;
     for j := 0 to inW - 1 do
     begin

	{ Scale and save pixel to output bitmap }
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

{ Sharpen bitmap }
function SharpenBitmap(inBmp: bmpArray; inW, inH: integer): bmpArray;
const

  { Kernel for applying sharpen on bitmap }
  Kernel: array[-1..1, -1..1] of Integer = (
    (0, -1, 0),
    (-1, 5, -1),
    (0, -1, 0)
  );
var
  I, J, K, L: Integer;
  sumR, sumG, sumB: Integer;
begin
  { Allocate memory for out bitmap }
  SetLength(outBmp, inH, inW);

  { Loop through pixels in bitmap }
  for I := 1 to inH-2 do
    for J := 1 to inW-2 do
    begin
      sumR := 0;
      sumG := 0;
      sumB := 0;

      { Loop through pixels in kernel }
      for K := -1 to 1 do
      begin
        for L := -1 to 1 do
	begin

          { Apply sharpen to red green and blue colour channels in pixel }
          sumR := sumR + inBmp[I+K, J+L].R * Kernel[K, L];
	  sumG := sumG + inBmp[I+K, J+L].G * Kernel[K, L];
	  sumB := sumB + inBmp[I+K, J+L].B * Kernel[K, L]; 
	end;
      end;

      { Ensure pixel's red green and blue channels are within range }
      outBmp[I, J].R := EnsureRange(sumR div 1, 0, 255);
      outBmp[I, J].G := EnsureRange(sumG div 1, 0, 255);
      outBmp[I, J].B := EnsureRange(SumB div 1, 0, 255);
    end;
  
  SharpenBitmap := outBmp;
end;

{ Calculate distance between two pixels }
function Distance(Colour1, Colour2: TPixel): integer;
begin
  Distance := Sqr(Colour1.R - Colour2.R) + Sqr(Colour1.G - Colour2.G) + Sqr(Colour1.B - Colour2.B);
end;

{ Find the nearest colour to a pixel from a colour table }
function FindNearestColour(TargetColour: TPixel; ColourTable: TColourTable; NumColours: integer): TPixel;
var
  i, BestIndex, BestDistance: integer;
  DistanceToTarget: integer;
begin

  { Calculate the distance between pixel and first position in the colour table }
  BestIndex := 0;
  BestDistance := Distance(TargetColour, ColourTable[0]);

  { Calculate the distance between pixel and the rest of colour table }
  for i := 1 to NumColours - 1 do
  begin
    DistanceToTarget := Distance(TargetColour, ColourTable[i]);
    if DistanceToTarget < BestDistance then
    begin
      BestIndex := i;
      BestDistance := DistanceToTarget;
    end;
  end;

  { Return the closest colour in colour table to pixel }
  FindNearestColour := ColourTable[BestIndex];
end;

// this function needs the colourtables matched to colour bit ratios, 
{ Quantize a bitmap to a set number of colours }
function QuantizeBitmap(inBmp: bmpArray; var inW, inH, NumColours: integer): bmpArray;

var
  i, j: integer;
  ColourTable: TColourTable;
  NearestColour: TPixel;
  outBmp: bmpArray;

begin
    { Allocate Memory for output bitmap }
    setLength(outBmp, inH, inW);	

    { Set ColourTable }
    for i := 1 to NumColours do
    begin
      ColourTable[i-1].R := trunc(256 / i); // random(256);
      ColourTable[i-1].G := trunc(256 / (NumColours - i + 1)); // random(256);
      ColourTable[i-1].B := trunc(256 / i); // random(256);
    end;
    
    { Loop through pixels in bitmap }
    for i := 0 to inH -1 do
    begin
      for j := 0 to inW -1 do
      begin
	
	{ Find nearest colour in colour table to pixel then write to output bitmap }
        NearestColour := FindNearestColour(inBmp[i][j], ColourTable, NumColours);
	outBmp[i][j] := NearestColour;
      end;
    end;
    QuantizeBitmap := outBmp;
end;

// I think the ability to round to a decimal place might make this more useful.
{ Dither bitmap }
function DitherBitmap(inBmp: bmpArray; var inW, inH: integer): bmpArray;

var
  OldPixel, NewPixel, Error: TPixel;
  outBmp: bmpArray;
  x, y: integer;
begin

  { Allocate memory to output bitmap }
  setLength(outBmp, inH, inW);

  { Loop over pixels in bitmap }
  for y := 0 to inH - 1 do
  begin
    for x := 0 to inW - 1 do
    begin

      { Set old pixel to equal current iteration of bitmap }
      OldPixel := inBmp[y][x];

      { Set new pixel }
      NewPixel.R := Round((OldPixel.R / 256) * 256);
      NewPixel.G := Round((OldPixel.G / 256) * 256);
      NewPixel.B := Round((OldPixel.B / 256) * 256);

      { Calculate error between old and new pixel }
      Error.R := OldPixel.R - NewPixel.R;
      Error.G := OldPixel.G - NewPixel.G;
      Error.B := OldPixel.B - NewPixel.B;

      { Write new pixel to output bitmap }
      outBmp[y][x] := NewPixel;

      { Calculate dither from error generated }
      if x < inW - 1 then
      begin
        inBmp[y, x + 1].R := inBmp[y, x + 1].R + Error.R * 7 div 16;
        inBmp[y, x + 1].G := inBmp[y, x + 1].G + Error.G * 7 div 16;
        inBmp[y, x + 1].B := inBmp[y, x + 1].B + Error.B * 7 div 16;
      end;
      if (x > 0) and (y < inH - 1) then
      begin
        inBmp[y + 1, x - 1].R := inBmp[y + 1, x - 1].R + Error.R * 3 div 16;
        inBmp[y + 1, x - 1].G := inBmp[y + 1, x - 1].G + Error.G * 3 div 16;
        inBmp[y + 1, x - 1].B := inBmp[y + 1, x - 1].B + Error.B * 3 div 16;
      end;
      if y < inH - 1 then
      begin
        inBmp[y + 1, x].R := inBmp[y + 1, x].R + Error.R * 5 div 16;
        inBmp[y + 1, x].G := inBmp[y + 1, x].G + Error.G * 5 div 16;
        inBmp[y + 1, x].B := inBmp[y + 1, x].B + Error.B * 5 div 16;
      end;
      if (x < inW - 1) and (y < inH - 1) then
      begin
        inBmp[y + 1, x + 1].R := inBmp[y + 1, x + 1].R + Error.R div 16;
        inBmp[y + 1, x + 1].G := inBmp[y + 1, x + 1].G + Error.G div 16;
        inBmp[y + 1, x + 1].B := inBmp[y + 1, x + 1].B + Error.B div 16;
      end;
    end;
  end;
  DitherBitmap := outBmp;
end;

{ Detect edges in bitmap based on colour gradient difference using a threshold }
function EdgeDetectBitmap(inBmp: bmpArray; Threshold: TPixel; inH, inW: integer): bmpArray;
var
  X, Y, temp: Integer;
  GX, GY: TPixel; // Gradients in X and Y directions
  Gradient: GPixel; // Magnitude of gradient
begin

  { Allocate memory for ouput bitmap }
  setLength(outBmp, inH, inW);

  { Loop over all pixels in the bitmap }
  for y := 1 to inH - 2 do
    for x := 1 to inW - 2 do
    begin

      { Calculate gradients in X and Y directions using Sobel operator }
      GX.R := (inBmp[y-1,x-1].R + 2*inBmp[y-1,x].R + inBmp[y-1,x+1].R) -
        (inBmp[y+1,x-1].R + 2*inBmp[y+1,x].R + inBmp[y+1,x+1].R);
      GX.G := (inBmp[y-1,x-1].G + 2*inBmp[y-1,x].G + inBmp[y-1,x+1].G) -
        (inBmp[y+1,x-1].G + 2*inBmp[y+1,x].G + inBmp[y+1,x+1].G);
      GX.B := (inBmp[y-1,x-1].B + 2*inBmp[y-1,x].B + inBmp[y-1,x+1].B) -
            (inBmp[y+1,x-1].B + 2*inBmp[y+1,x].B + inBmp[y+1,x+1].B);


      GY.R := (inBmp[y-1,x-1].R + 2*inBmp[y,x-1].R + inBmp[y+1,x-1].R) -
            (inBmp[y-1,x+1].R + 2*inBmp[y,x+1].R + inBmp[y+1,x+1].R);
      GY.G := (inBmp[y-1,x-1].G + 2*inBmp[y,x-1].G + inBmp[y+1,x-1].G) -
            (inBmp[y-1,x+1].G + 2*inBmp[y,x+1].G + inBmp[y+1,x+1].G);
      GY.B := (inBmp[y-1,x-1].B + 2*inBmp[y,x-1].B + inBmp[y+1,x-1].B) -
            (inBmp[y-1,x+1].B + 2*inBmp[y,x+1].B + inBmp[y+1,x+1].B);

      { Calculate magnitude of gradient }
      Gradient.R := Abs(GX.R) + Abs(GY.R);
      Gradient.G := Abs(GX.G) + Abs(GY.G);
      Gradient.B := Abs(GX.B) + Abs(GY.B);

      { Threshold gradient and set output pixel }
      if Gradient.R > Threshold.R then
        outBmp[y,x].R := 255
      else
        outBmp[y,x].R := 0;
      if Gradient.G > Threshold.G then
        outBmp[y,x].G := 255
      else
        outBmp[y,x].G := 0;
      if Gradient.B > Threshold.B then
        outBmp[y,x].B := 255
      else
        outBmp[y,x].B := 0;

    end;
    EdgeDetectBitmap := outBmp;
end;


var
  PixArray: bmpArray;
  arg: string;
  angle: float;
  x, y, numColours: integer;
  Threshold: TPixel;

begin
  if ParamCount < 3 then
  begin
    Writeln('Usage: BitmapScaling input.bmp output.bmp scale');
    Halt;
  end;
  arg := ParamStr(1);
  input := ParamStr(2);
  output := ParamStr(3);

  { Scale bitmap }
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
    SaveBitmap(output, outBmp);
  end;
  if arg = '--scale' then
  begin
    scale := StrToFloat(ParamStr(4));
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    outW := Round(inW * scale);
    outH := Round(inH * scale);
    if StrToFloat(ParamStr(4)) <= 1 then
      outBmp := DownScaleBitmap(PixArray, inW, inH, outW, outH, scale)
    else
      outBmp := UpScaleBitmap(PixArray, inW, inH, outW, outH, scale);
    SaveBitmap(output, outBmp);
  end;

  { Rotate bitmap }
  if arg = '-r' then
  begin
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    angle := StrtoFloat(ParamStr(4));
    outBmp := RotateBitmap(PixArray, inW, inH, angle);
    SaveBitmap(output, outBmp);
  end;
  if arg = '--rotate' then
  begin
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    angle := StrtoFloat(ParamStr(4));
    outBmp := RotateBitmap(PixArray, inW, inH, angle);
    SaveBitmap(output, outBmp);
  end;

  { Blur bitmap }
  if arg = '-b' then
  begin
    // initialize bitmap
    Randomize;
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    outBmp := BoxBlurBitmap(PixArray);
    SaveBitmap(output, outBmp);
  end;
  if arg = '--blur' then
  begin
    // initialize bitmap
    Randomize;
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    outBmp := BoxBlurBitmap(PixArray);
    SaveBitmap(output, outBmp);
  end;

  { Sharpen bitmap }
  if arg = '-#' then
  begin
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    outBmp :=  SharpenBitmap(PixArray, inW, inH);
    SaveBitmap(output, outBmp);
  end;
  if arg = '--sharpen' then
  begin
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    outBmp :=  SharpenBitmap(PixArray, inW, inH);
    SaveBitmap(output, outBmp);
  end;

  { Quantize bitmap }
  if arg = '-q' then
  begin
    numColours := StrToInt(ParamStr(4));
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    outBmp := QuantizeBitmap(PixArray, inW, inH, NumColours);
    SaveBitmap(output, outBmp);
  end;
  if arg = '--quantize' then
  begin
    numColours := StrToInt(ParamStr(4));
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    outBmp := QuantizeBitmap(PixArray, inW, inH, NumColours);
    SaveBitmap(output, outBmp);
  end;

  { Dither bitmap }
  if arg = '-d' then
  begin
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    outBmp := DitherBitmap(PixArray, inW, inH);
    SaveBitmap(output, outBmp);
  end;
  if arg = '--dither' then
  begin
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    outBmp := DitherBitmap(PixArray, inW, inH);
    SaveBitmap(output, outBmp);
  end;

  { Edge Detect bitmap }
  if arg = '-e' then
  begin

    Threshold.R := StrToInt(ParamStr(4));
    Threshold.G := StrToInt(ParamStr(5));
    Threshold.B := StrToInt(ParamStr(6));
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    outBmp := EdgeDetectBitmap(PixArray, Threshold, inH, inW);
    SaveBitmap(output, outBmp);
  end;
  if arg = '--edge' then
  begin
    Threshold.R := StrToInt(ParamStr(4));
    Threshold.G := StrToInt(ParamStr(5));
    Threshold.B := StrToInt(ParamStr(6));
    PixArray := LoadBitmap(input, inBmp, inW, inH);
    outBmp := EdgeDetectBitmap(PixArray, Threshold, inH, inW);
    SaveBitmap(output, outBmp);
  end;
end.
