//
// Created by Matthew Abbott 23/4/2023
//

{$mode objfpc}
{$M+}

program BitmapToolFactory;

uses
   math, sysutils;

const
  KERNEL_SIZE = 3;
type

  { Pixel }
  TPixel = class
    private
      B: Byte;
      G: Byte;
      R: Byte;
    public 
      function getBlueByte(): byte;
      function getBlueInt(): integer;
      function getGreenByte(): byte;
      function getGreenInt(): integer;
      function getRedByte(): byte;
      function getRedInt(): integer;
      procedure setBlue(inByte: byte);
      procedure setGreen(inByte: byte);
      procedure setRed(inByte: byte);
  end;

  { GPixels are pixel calculations that have yet to be clamped so may fall outside of the 256 limit of a byte }
  GPixel = class
    private
      B: integer;
      G: integer;
      R: integer;
    public
      function getBlueInt(): integer;
      function getGreenInt(): integer;
      function getRedInt(): integer;
      procedure setBlue(inInteger: integer);
      procedure setGreen(inInteger: integer);
      procedure setRed(inInteger: integer);
  end;

  TColourTable = array[0..255] of TPixel;
  bmpArray = array of array of TPixel;
  PPixel = ^TPixel; // pointer to a pixel
  PArray = ^bmpArray; // pointer to entire bmp array

  { Base Class for Bitmap Tools to inherit from or Product}
  BitmapTool = class
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray; virtual; abstract;
  end;

  { Box Blur Concrete Product }
  BitmapBoxBlur = class(BitmapTool)
    private 
      function ApplyBoxBlur(x, y: integer; Bitmap: bmpArray): TPixel;
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray; override;
  end;

  { Rotate Concrete Product }
  BitmapRotate = class(BitmapTool)
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray; override;
  end;

  { Scale Concrete Product }
  BitmapScale = class(BitmapTool)
    private
      function clamp(x, a, b: byte): byte;
      function DownScalePixel(x, y, inW, inH: integer; scale: real; inBmp: bmpArray): TPixel;
      function UpScalePixel(x, y, inW, inH: integer; scale: real; inBmp: bmpArray): TPixel;
      function DownScaleBitmap(inBmp: bmpArray; inW, inH, outW, outH: integer; scale: real): bmpArray;
      function UpScaleBitmap(inBmp: bmpArray; inW, inH, outW, outH: integer; scale: real): bmpArray;
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray; override;
  end;

  { Sharpen Concrete Product }
  BitmapSharpen = class(BitmapTool)
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray; override;
  end;

  { Quantize Concrete Product }
  BitmapQuantize = class(BitmapTool)
    private
      function Distance(Colour1, Colour2: TPixel): integer;
      function FindNearestColour(TargetColour: TPixel; ColourTable: TColourTable; NumColours: integer): TPixel;
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray; override;
  end;

  { Dither Concrete Product }
  BitmapDither = class(BitmapTool)
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray; override;
  end;

  { Edge Detection Concrete Product }
  BitmapEdgeDetect = class(BitmapTool)
    private
      function detect(inBmp: bmpArray; Threshold: TPixel; inH, inW: integer): bmpArray;
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray; override;
  end;


  { Factory for creating Bitmap Tool Products }
  BitmapFactory = class
    public
      function createProduct(productType: string): BitmapTool;
      function LoadBitmap(filename: string): bmpArray;
      procedure SaveBitmap(filename: string; bmp: bmpArray);
  end;

{ Set Pixel Blue }
procedure TPixel.setBlue(inByte: byte);
begin
  B := inByte;
end;

{ Set Pixel Green }
procedure TPixel.setGreen(inByte: byte);
begin
  G := inByte;
end;

{ Set Pixel Red }
procedure TPixel.setRed(inByte: byte);
begin
  R := inByte;
end;

{ Set GPixel Blue }
procedure GPixel.setBlue(inInteger: integer);
begin
  B := inInteger;
end;

{ Set GPixel Green }
procedure GPixel.setGreen(inInteger: integer);
begin
  G := inInteger;
end;

{ Set GPixel Red }
procedure GPixel.setRed(inInteger: integer);
begin
  R := inInteger;
end;

{ Return integer value for Pixel Blue }
function TPixel.getBlueInt(): integer;
begin
  result := integer(B);
end;

{ Return byte value for Pixel Blue }
function TPixel.getBlueByte(): byte;
begin
  result := B;
end;

{ Return integer value for Pixel Green }
function TPixel.getGreenInt(): integer;
begin
  result := integer(G);
end;

{ Return byte value for Pixel Green }
function TPixel.getGreenByte(): byte;
begin
  result := G;
end;

{ Return integer value for Pixel Red }
function TPixel.getRedInt(): integer;
begin
  result := integer(R);
end;

{ Return byte value for Pixel Red }
function TPixel.getRedByte(): byte;
begin
  result := R;
end;

{ Return integer value for GPixel Blue }
function GPixel.getBlueInt(): integer;
begin
  result := B;
end;

{ Return integer value for GPixel Green }
function GPixel.getGreenInt(): integer;
begin
  result := G;
end;

{ Return integer value for GPixel Red }
function GPixel.getRedInt(): integer;
begin
  result := R;
end;


{ Factory Product creation function }
function BitmapFactory.createProduct(productType: string): BitmapTool;
begin
  if productType = 'BoxBlur' then
    result := BitmapBoxBlur.Create()
  else if productType = 'Rotate' then
    result := BitmapRotate.Create()
  else if productType = 'Scale' then
    result := BitmapRotate.Create()
  else if productType = 'Sharpen' then
    result := BitmapSharpen.Create()
  else if productType = 'Quantize' then
    result := BitmapQuantize.Create()
  else if productType = 'Dither' then
    result := BitmapDither.Create()
  else if productType = 'Edge' then
    result := BitmapEdgeDetect.Create()
  else
    result := nil;
end;

{ Load bitmap into a two dimensional array }
function BitmapFactory.LoadBitmap(filename: string): bmpArray;
var
  inFile: file;
  header: array[0..53] of byte;
  pixelSize, start: integer;
  rowSize, paddingSize, stepSize: integer;
  i, j, w ,h: integer;
  bmp: bmpArray;
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
  result := bmp;
end;

{ Saves Bitmap to file }
procedure BitmapFactory.SaveBitmap(filename: string; bmp: bmpArray);
var
  outFile: file;
  header: array[0..53] of byte;
  pixelSize: integer;
  rowSize, paddingSize: integer;
  i, j: integer;
  outPixel: TPixel;
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
      outPixel.setBlue(0);
      outPixel.setGreen(0);
      outPixel.setRed(0);
      BlockWrite(outFile, outPixel, paddingSize);
    end;
  end;
  Close(outFile);
end;

{ Apply a Box Blur to a bitmap }
function BitmapBoxBlur.use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray;
var
  x, y, inH, inW: Integer;
  BlurredBitmap: bmpArray;
begin
  inH := length(inBmp);
  inW := length(inBmp[high(inBmp)]);
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

  result := BlurredBitmap;
end;

{ Apply a Box Blur to kernel }
function BitMapBoxBlur.ApplyBoxBlur(x, y: integer; Bitmap: bmpArray): TPixel;
var
  i, j, count: Integer;
  sumR, sumG, sumB, inH, inW: Integer;
  outPixel: TPixel;
begin
  inH := length(Bitmap);
  inW := length(Bitmap[high(Bitmap)]);
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
        sumR := sumR + Bitmap[i][j].getRedInt;
        sumG := sumG + Bitmap[i][j].getGreenInt;
        sumB := sumB + Bitmap[i][j].getBlueInt;
        Inc(count);
      end;
    end;
  end;

  { Calculate average RGB value of kernel area and return pixel}
  outPixel.setBlue(Round(sumB / count));
  outPixel.setGreen(Round(sumG / count));
  outPixel.setRed(Round(sumR / count));

  result := outPixel;
end;

{ Rotate a bitmap }
function BitmapRotate.use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray;
var
x, y, i, j, xx, yy, inH, inW: integer;
cx, cy, sina, cosa, scale, angle: real;
w2, h2, outW, outH: integer;
outBmp: bmpArray;
begin

  { Assign angle to input argument }
  angle := inputVariableReal;

  { Find dimensions of bitmap }
  inH := length(inBmp);
  inW := length(inBmp[length(inBmp)]);

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
        outBmp[i][j] := inBmp[high(inBmp) - yy][ xx];
      end;
    end;
  end;

  result := outBmp;
end;

{ Scale a bitmap }
function BitmapScale.use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray;
var
  scale: real;
  inW, inH, outW, outH: integer;
  outBmp: bmpArray;

begin
  scale := inputVariableReal;
  inH := length(inBmp);
  inW := length(inBmp[high(inBmp)]);
  outW := Round(inW * scale);
  outH := Round(inH * scale);
  if scale <= 1 then
    outBmp := DownScaleBitmap(inBmp, inW, inH, outW, outH, scale)
  else
    outBmp := UpscaleBitmap(inBmp, inW, inH, outW, outH, scale);
  result := outBmp; 
end;

{ Locks a byte to an upper and lower limit. }
function BitmapScale.clamp(x, a, b: byte): byte;
begin
  if x < a then
    result := a
  else if x > b then
    result := b
  else
    result := x;
end;

{ Scale a pixel down }
function BitmapScale.DownScalePixel(x, y, inW, inH: integer; scale: real; inBmp: bmpArray): TPixel;
var
  i, j: integer;
  dx, dy: real;
  r, g, b: integer;
  a: real;
  outPixel: TPixel;
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
  r := Round((1 - a) * inBmp[i][j].getRedInt + a * inBmp[i][j + 1].getRedInt);
  g := Round((1 - a) * inBmp[i][j].getGreenInt + a * inBmp[i][j + 1].getGreenInt);
  b := Round((1 - a) * inBmp[i][j].getBlueInt + a * inBmp[i][j + 1].getBlueInt);

  { Clamp pixel red green and blue channels }
  outPixel.setBlue(Clamp(Round(b), 0, 255));
  outPixel.setGreen(Clamp(Round(g), 0, 255));
  outPixel.setRed(Clamp(Round(r), 0, 255));

  { Return scaled pixel }
  result := outPixel;
end;

{ Scale a pixel up }
function BitmapScale.UpScalePixel(x, y, inW, inH: integer; scale: real; inBmp: bmpArray): TPixel;
var
  dx, dy: real;
  r, g, b, i, j: integer;
  a: real;
  outPixel: TPixel;
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
      r := Round((1 - a) * inBmp[i][j].getRedInt + a * inBmp[i][j + 1].getRedInt);
      g := Round((1 - a) * inBmp[i][j].getGreenInt + a * inBmp[i][j + 1].getGreenInt);
      b := Round((1 - a) * inBmp[i][j].getBlueInt + a * inBmp[i][j + 1].getBlueInt);
    end;
  end;

  { Clamp pixel red green and blue channels }
  outPixel.setBlue(Clamp(Round(b), 0, 255));
  outPixel.setGreen(Clamp(Round(g), 0, 255));
  outPixel.setRed(Clamp(Round(r), 0, 255));

  { Return scaled pixel }
  result := outPixel;
end;

{ Scale bitmap down }
function BitmapScale.DownScaleBitmap(inBmp: bmpArray; inW, inH, outW, outH: integer; scale: real): bmpArray;
var
  i, j, x, y: integer;
  outPixel: TPixel;
  outBmp: bmpArray;
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
      outPixel :=  DownScalePixel(x, y, inW, inH, scale, inBmp);
      outBmp[i][j] := outPixel;
    end;
  end;
  DownScaleBitmap := outBmp;
end;

{ Scale bitmap up }
function BitmapScale.UpScaleBitmap(inBmp: bmpArray; inW, inH, outW, outH: integer; scale: real): bmpArray;
var
  r, i, j, x, y: integer;
  outPixel: TPixel;
  outBmp: bmpArray;
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
        outPixel :=  UpScalePixel(x, y, inW, inH, scale, inBmp);
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
function BitmapSharpen.use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray;
const

  { Kernel for applying sharpen on bitmap }
  Kernel: array[-1..1, -1..1] of Integer = (
    (0, -1, 0),
    (-1, 5, -1),
    (0, -1, 0)
  );
var
  I, J, K, L: Integer;
  sumR, sumG, sumB, inH, inW: Integer;
  outBmp: bmpArray;

begin
  
  { Find Bitmaps dimensions }
  inH := length(inBmp);
  inW := length(inBmp[high(inBmp)]);

  { Allocate memory for out bitmap }
  setLength(outBmp, inH, inW);

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
          sumR := sumB + inBmp[I+K, J+L].getBlueInt * Kernel[K, L];
          sumG := sumG + inBmp[I+K, J+L].getGreenInt * Kernel[K, L];
          sumB := sumR + inBmp[I+K, J+L].getRedInt * Kernel[K, L];
        end;
      end;

      { Ensure pixel's red green and blue channels are within range }
      outBmp[I, J].setBlue(EnsureRange(sumB div 1, 0, 255));
      outBmp[I, J].setGreen(EnsureRange(sumG div 1, 0, 255));
      outBmp[I, J].setRed(EnsureRange(SumR div 1, 0, 255));
    end;

  result := outBmp;
end;

// this function needs the colourtables matched to colour bit ratios,
{ Quantize a bitmap to a set number of colours }
function BitmapQuantize.use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray;

var
  i, j, inW, inH, NumColours: integer;
  ColourTable: TColourTable;
  NearestColour: TPixel;
  outBmp: bmpArray;

begin
    NumColours := inputVariableInt;

    { Find dimensions of bitmap }
    inH := length(inBmp);
    inW := length(inBmp[high(inBmp)]);

    { Allocate Memory for output bitmap }
    setLength(outBmp, inH, inW);

    { Set ColourTable }
    for i := 1 to NumColours do
    begin
      ColourTable[i-1].setBlue(trunc(256 / i)); // random(256));
      ColourTable[i-1].setGreen(trunc(256 / (NumColours - i + 1))); // random(256));
      ColourTable[i-1].setRed(trunc(256 / i)); // random(256));
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
    result := outBmp;
end;


{ Calculate distance between two pixels }
function BitmapQuantize.Distance(Colour1, Colour2: TPixel): integer;
begin
  Distance := Sqr(Colour1.getRedInt - Colour2.getRedInt) + Sqr(Colour1.getGreenInt - Colour2.getGreenInt) + Sqr(Colour1.getBlueInt - Colour2.getBlueInt);
end;

{ Find the nearest colour to a pixel from a colour table }
function BitmapQuantize.FindNearestColour(TargetColour: TPixel; ColourTable: TColourTable; NumColours: integer): TPixel;
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
  result := ColourTable[BestIndex];
end;

// I think the ability to round to a decimal place might make this more useful.
{ Dither bitmap }
function BitmapDither.use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray;


var
  OldPixel, NewPixel, Error: TPixel;
  outBmp: bmpArray;
  x, y, inH, inW: integer;
begin

  { Find bitmap dimensions }
  inH := length(inBmp);
  inW := length(inBmp[high(inBmp)]);

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
      NewPixel.setBlue(Round((OldPixel.getBlueInt / 256) * 256));
      NewPixel.setGreen(Round((OldPixel.getGreenInt / 256) * 256));
      NewPixel.setRed(Round((OldPixel.getRedInt / 256) * 256));

      { Calculate error between old and new pixel }
      Error.setBlue(OldPixel.getBlueInt - NewPixel.getBlueInt);
      Error.setGreen(OldPixel.getGreenInt - NewPixel.getGreenInt);
      Error.setRed(OldPixel.getRedInt - NewPixel.getRedInt);

      { Write new pixel to output bitmap }
      outBmp[y][x] := NewPixel;

      { Calculate dither from error generated }
      if x < inW - 1 then
      begin
        inBmp[y, x + 1].setBlue(inBmp[y, x + 1].getBlueInt + Error.getBlueInt * 7 div 16);
        inBmp[y, x + 1].setGreen(inBmp[y, x + 1].getGreenInt + Error.getGreenInt * 7 div 16);
        inBmp[y, x + 1].setRed(inBmp[y, x + 1].getRedInt + Error.getRedInt * 7 div 16);
      end;
      if (x > 0) and (y < inH - 1) then
      begin
        inBmp[y + 1, x - 1].setBlue(inBmp[y + 1, x - 1].getBlueInt + Error.getBlueInt * 3 div 16);
        inBmp[y + 1, x - 1].setGreen(inBmp[y + 1, x - 1].getGreenInt + Error.getGreenInt * 3 div 16);
        inBmp[y + 1, x - 1].setRed(inBmp[y + 1, x - 1].getRedInt + Error.getRedInt * 3 div 16);
      end;
      if y < inH - 1 then
      begin
        inBmp[y + 1, x].setBlue(inBmp[y + 1, x].getBlueInt + Error.getBlueInt * 5 div 16);
        inBmp[y + 1, x].setGreen(inBmp[y + 1, x].getGreenInt + Error.getGreenInt * 5 div 16);
        inBmp[y + 1, x].setRed(inBmp[y + 1, x].getRedInt + Error.getRedInt * 5 div 16);
        end;
      if (x < inW - 1) and (y < inH - 1) then
      begin
        inBmp[y + 1, x + 1].setBlue(inBmp[y + 1, x + 1].getBlueInt + Error.getBlueInt div 16);
        inBmp[y + 1, x + 1].setGreen(inBmp[y + 1, x + 1].getGreenInt + Error.getGreenInt div 16);
        inBmp[y + 1, x + 1].setRed(inBmp[y + 1, x + 1].getRedInt + Error.getRedInt div 16);
      end;
    end;
  end;
  result := outBmp;
end;

{ Detect edges in bitmap based on colour gradient difference using a threshold }
function BitmapEdgeDetect.use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray;
var
  Threshold: TPixel;
  inH, inW: integer;
  outBmp : bmpArray;
begin
  Threshold.setBlue(inputVariableInt);
  Threshold.setGreen(inputVariableInt);
  Threshold.setRed(inputVariableInt);
  inH := length(inBmp);
  inW := length(inBmp[high(inBmp)]);
  outBmp := detect(inBmp, Threshold, inH, inW);
  result := outBmp
end;

{ Calculate Edge Detection }
function BitmapEdgeDetect.detect(inBmp: bmpArray; Threshold: TPixel; inH, inW: integer): bmpArray;
var
  X, Y, temp: Integer;
  GX, GY: TPixel; // Gradients in X and Y directions
  Gradient: GPixel; // Magnitude of gradient
  outBmp: bmpArray;
begin

  { Allocate memory for ouput bitmap }
  setLength(outBmp, inH, inW);

  { Loop over all pixels in the bitmap }
  for y := 1 to inH - 2 do
    for x := 1 to inW - 2 do
    begin

      { Calculate gradients in X and Y directions using Sobel operator }
      GX.setRed( (inBmp[y-1,x-1].getRedInt + 2*inBmp[y-1,x].getRedInt + inBmp[y-1,x+1].getRedInt) -
        (inBmp[y+1,x-1].getRedInt + 2*inBmp[y+1,x].getRedInt + inBmp[y+1,x+1].getRedInt));
      GX.setGreen( (inBmp[y-1,x-1].getGreenInt + 2*inBmp[y-1,x].getGreenInt + inBmp[y-1,x+1].getGreenInt) -
        (inBmp[y+1,x-1].getGreenInt + 2*inBmp[y+1,x].getGreenInt + inBmp[y+1,x+1].getGreenInt));
      GX.setBlue( (inBmp[y-1,x-1].getBlueInt + 2*inBmp[y-1,x].getBlueInt + inBmp[y-1,x+1].getBlueInt) -
            (inBmp[y+1,x-1].getBlueInt + 2*inBmp[y+1,x].getBlueInt + inBmp[y+1,x+1].getBlueInt));


      GY.setRed( (inBmp[y-1,x-1].getRedInt + 2*inBmp[y,x-1].getRedInt + inBmp[y+1,x-1].getRedInt) -
            (inBmp[y-1,x+1].getRedInt + 2*inBmp[y,x+1].getRedInt + inBmp[y+1,x+1].getRedInt));
      GY.setGreen( (inBmp[y-1,x-1].getGreenInt + 2*inBmp[y,x-1].getGreenInt+ inBmp[y+1,x-1].getGreenInt) -
            (inBmp[y-1,x+1].getGreenInt + 2*inBmp[y,x+1].getGreenInt + inBmp[y+1,x+1].getGreenInt));
      GY.setBlue((inBmp[y-1,x-1].getBlueInt + 2*inBmp[y,x-1].getBlueInt + inBmp[y+1,x-1].getBlueInt) -
            (inBmp[y-1,x+1].getBlueInt + 2*inBmp[y,x+1].getBlueInt + inBmp[y+1,x+1].getBlueInt));

      { Calculate magnitude of gradient }
      Gradient.setRed(Abs(GX.getRedInt) + Abs(GY.getRedInt));
      Gradient.setGreen(Abs(GX.getGreenInt) + Abs(GY.getGreenInt));
      Gradient.setRed(Abs(GX.getRedInt) + Abs(GY.getRedInt));

      { Threshold gradient and set output pixel }
      if Gradient.getRedInt > Threshold.getRedInt then
        outBmp[y,x].setRed(255)
      else
        outBmp[y,x].setRed(0);
      if Gradient.getGreenInt > Threshold.getGreenInt then
        outBmp[y,x].setGreen(255)
      else
        outBmp[y,x].setGreen(0);
      if Gradient.getBlueInt > Threshold.getBlueInt then
        outBmp[y,x].setBlue(255)
      else
        outBmp[y,x].setBlue(0);

    end;
    result := outBmp;
end;

{ Begining of main function }

var
  BitmapFactoryVar: BitmapFactory;
  BitmapToolVar: BitmapTool;
  PixArray: bmpArray;
  arg, input, output: string;
  outBmp: bmpArray;

begin
  if ParamCount < 3 then
  begin
    Writeln('Usage: BitmapScaling input.bmp output.bmp optional argument');
    Halt;
  end;
  arg := ParamStr(1);
  input := ParamStr(2);
  output := ParamStr(3);

  { Scale }
  if (arg = '-s') or (arg = '--scale') then
  begin
    BitmapFactoryVar := BitmapFactory.Create();
    PixArray := BitmapFactoryVar.LoadBitmap(input);
    BitmapToolVar := BitmapFactoryVar.createProduct('Scale');
    outBmp := BitmapToolVar.use(0,StrToFloat(ParamStr(4)),PixArray);
    BitmapFactoryVar.SaveBitmap(output, outBmp);
  end;

  { Rotate }
  if (arg = '-r') or (arg = '--rotate') then
  begin
    BitmapFactoryVar := BitmapFactory.Create();
    PixArray := BitmapFactoryVar.LoadBitmap(input);
    BitmapToolVar := BitmapFactoryVar.createProduct('Rotate');
    outBmp := BitmapToolVar.use(0,StrToFloat(ParamStr(4)),PixArray);
    BitmapFactoryVar.SaveBitmap(output, outBmp);
  end;

  { Blur }
  if (arg = '-b') or (arg = '--blur') then
  begin
    BitmapFactoryVar := BitmapFactory.Create();
    PixArray := BitmapFactoryVar.LoadBitmap(input);
    BitmapToolVar := BitmapFactoryVar.createProduct('Blur');
    outBmp := BitmapToolVar.use(0,0,PixArray);
    BitmapFactoryVar.SaveBitmap(output, outBmp);
  end;

  { Sharpen }
  if (arg = '-#') or (arg = '--sharpen') then
  begin
    BitmapFactoryVar := BitmapFactory.Create();
    PixArray := BitmapFactoryVar.LoadBitmap(input);
    BitmapToolVar := BitmapFactoryVar.createProduct('Sharpen');
    outBmp := BitmapToolVar.use(0,0,PixArray);
    BitmapFactoryVar.SaveBitmap(output, outBmp);
  end;

  { Quantize }
  if (arg = '-q') or (arg = '--quantize') then
  begin
    BitmapFactoryVar := BitmapFactory.Create();
    PixArray := BitmapFactoryVar.LoadBitmap(input);
    BitmapToolVar := BitmapFactoryVar.createProduct('Quantize');
    outBmp := BitmapToolVar.use(StrToInt(ParamStr(4)),0,PixArray);
    BitmapFactoryVar.SaveBitmap(output, outBmp);
  end;

  { Dither }
  if (arg = '-d') or (arg = '--dither') then
  begin
    BitmapFactoryVar := BitmapFactory.Create();
    PixArray := BitmapFactoryVar.LoadBitmap(input);
    BitmapToolVar := BitmapFactoryVar.createProduct('Dither');
    outBmp := BitmapToolVar.use(0,0,PixArray);
    BitmapFactoryVar.SaveBitmap(output, outBmp);
  end;

  { Edge }
  if (arg = '-e') or (arg = '--edge') then
  begin
    BitmapFactoryVar := BitmapFactory.Create();
    PixArray := BitmapFactoryVar.LoadBitmap(input);
    BitmapToolVar := BitmapFactoryVar.createProduct('Edge');
    outBmp := BitmapToolVar.use(StrToInt(ParamStr(4)),0,PixArray);
    BitmapFactoryVar.SaveBitmap(output, outBmp);
  end;
end.

