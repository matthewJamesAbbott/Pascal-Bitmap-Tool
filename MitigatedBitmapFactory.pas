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
      constructor Create(); 
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

    { Parent template mitigation strategy }
  TMitigationActionStrategy = class
    public
      function Execute(): boolean; virtual; abstract;
  end;

  { Scale mitigation strategy using -s switch }
  TsStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

  { Scale mitigation strategy using --scale switch }
  TscaleStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

  { Rotate mitigation strategy using -r switch }
  TrStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

  { Rotate mitigation strategy using --rotate switch }
  TrotateStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

  { Blur mitigation strategy using -b switch }
  TbStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

  { Blur mitigation strategy using --blur switch }
  TblurStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

  { Sharpen mitigation strategy using -# switch }
  TsharpStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

  { Sharpen mitigation strategy using --sharpen switch }
  TsharpenStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

  { Quantize mitigation strategy using -q switch }
  TqStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

  { Quantize mitigation strategy using --quantize switch }
  TquantizeStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

  { Dither mitigation strategy using -d switch }
  TdStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

  { Dither mitigation strategy using --dither switch }
  TditherStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

  { Edge detection mitigation strategy using -e switch }
  TeStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

  { Edge detection mitigation strategy using --edge switch }
  TedgeStrategy = class(TMitigationActionStrategy)
    public
      function Execute(): boolean; override;
  end;

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
      function mitigateInput(): boolean;
  end;
   
constructor TPixel.Create();
begin
  setBlue(0);
  setGreen(0);
  setRed(0);
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
  if productType = 'Blur' then
    result := BitmapBoxBlur.Create()
  else if productType = 'Rotate' then
    result := BitmapRotate.Create()
  else if productType = 'Scale' then
    result := BitmapScale.Create()
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
  rowSize, paddingSize: integer;
  i, j, w ,h: integer;
  bmp: bmpArray;
  tempColourChannel: byte;

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
      bmp[i][j] := TPixel.Create();
      BlockRead(inFile, tempColourChannel,1);
      bmp[i][j].setBlue(tempColourChannel);
      BlockRead(inFile, tempColourChannel,1); //round(pixelSize/3));
      bmp[i][j].setGreen(tempColourChannel);
      BlockRead(inFile, tempColourChannel,1); // round(pixelSize/3));
      bmp[i][j].setRed(tempColourChannel);
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
writeln('save started');
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
  
  outPixel := TPixel.Create();

  { Write bitmap pixels }
  for i := high(bmp) downto 0 do
  begin
    for j := 0 to high(bmp[high(bmp)]) do
    begin
      BlockWrite(outFile, bmp[i][j].getBlueByte,1);// round(pixelSize/3));
      BlockWrite(outFile, bmp[i][j].getGreenByte,1);// round(pixelSize/3));
      BlockWrite(outFile, bmp[i][j].getRedByte,1);// round(pixelSize/3));
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
  outPixel := TPixel.Create();
  outPixel.setBlue(Round(sumB / count));
  outPixel.setGreen(Round(sumG / count));
  outPixel.setRed(Round(sumR / count));

  result := outPixel;
end;

{ Rotate a bitmap }
function BitmapRotate.use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray;
var
x, y, i, j, xx, yy, inH, inW: integer;
cx, cy, sina, cosa, angle: real;
w2, h2, outW, outH: integer;
outBmp: bmpArray;
begin
  { Assign angle to input argument }
  angle := inputVariableReal;

  { Find dimensions of bitmap }
  inH := length(inBmp);
  inW := length(inBmp[high(inBmp)]);
  cx := inW /2;
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
      outBmp[i][j] := TPixel.Create();
    end;
  end;

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
        outBmp[i][j].setBlue(inBmp[yy][xx].getBlueByte);
        outBmp[i][j].setGreen(inBmp[yy][xx].getGreenByte);
        outBmp[i][j].setRed(inBmp[yy][xx].getRedByte);
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
  outPixel := TPixel.Create();
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
  outPixel := TPixel.Create();
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

  result := outBmp;
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

  result := outBmp;
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
  i, j, k, l: Integer;
  sumR, sumG, sumB, inH, inW: Integer;

begin
  
  { Find Bitmaps dimensions }
  inH := length(inBmp);
  inW := length(inBmp[high(inBmp)]);

  { Allocate memory for out bitmap }
  //setLength(outBmp, inH, inW);
  //outBmp := inBmp;
  { Loop through pixels in bitmap }
  for i := 1 to inH-2 do
    for j := 1 to inW-2 do
    begin
      sumR := 0;
      sumG := 0;
      sumB := 0;

      { Loop through pixels in kernel }
      for k := -1 to 1 do
      begin
        for l := -1 to 1 do
        begin

          { Apply sharpen to red green and blue colour channels in pixel }
          sumR := sumB + inBmp[i+k][j+l].getBlueInt * Kernel[k][l];
          sumG := sumG + inBmp[i+k][j+l].getGreenInt * Kernel[k][l];
          sumB := sumR + inBmp[i+k][j+l].getRedInt * Kernel[k][l];
        end;
      end;

      { Ensure pixel's red green and blue channels are within range }
      inBmp[i][j].setBlue(EnsureRange(sumB div 1, 0, 255));
      inBmp[i][j].setGreen(EnsureRange(sumG div 1, 0, 255));
      inBmp[i][j].setRed(EnsureRange(SumR div 1, 0, 255));
    end;

  result := inBmp;
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
      ColourTable[i-1] := TPixel.Create();
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

  NewPixel := TPixel.Create();
  Error := TPixel.Create();
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
      outBmp[y][x] := TPixel.Create();
      outBmp[y][x].setBlue(NewPixel.getBlueByte);
      outBmp[y][x].setGreen(NewPixel.getGreenByte);
      outBmp[y][x].setRed(NewPixel.getGreenByte);

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
      //writeln('Blue : ' + inttostr(outBmp[y][x].getGreenInt));
      //writeln('Green : ' + inttostr(outBmp[y][x].getGreenInt));
      //writeln('Red : ' + inttostr(outBmp[y][x].getGreenInt));
    end;
  end;
  NewPixel.Free;
  Error.Free;
  result := outBmp;
end;

{ Detect edges in bitmap based on colour gradient difference using a threshold }
function BitmapEdgeDetect.use(inputVariableInt: integer; inputVariableReal: real; inBmp: bmpArray): bmpArray;
var
  Threshold: TPixel;
  inH, inW: integer;
  outBmp : bmpArray;

begin
  Threshold := TPixel.Create();
  Threshold.setBlue(inputVariableInt);
  Threshold.setGreen(inputVariableInt);
  Threshold.setRed(inputVariableInt);
  inH := length(inBmp);
  inW := length(inBmp[high(inBmp)]);
  outBmp := detect(inBmp, Threshold, inH, inW);
  Threshold.Free;
  result := outBmp
end;

{ Calculate Edge Detection }
function BitmapEdgeDetect.detect(inBmp: bmpArray; Threshold: TPixel; inH, inW: integer): bmpArray;
var
  X, Y: Integer;
  GX, GY: TPixel; // Gradients in X and Y directions
  Gradient: GPixel; // Magnitude of gradient
  outBmp: bmpArray;

begin

  { Allocate memory for ouput bitmap }
  setLength(outBmp, inH, inW);
  
  GX := TPixel.Create();
  GY := TPixel.Create();
  Gradient := GPixel.Create();
  outBmp := inBmp;
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
      Gradient.setBlue(Abs(GX.getBlueInt) + Abs(GY.getBlueInt));

      //outBmp[y][x] := TPixel.Create();
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
    GY.Free;
    GX.Free;
    Gradient.Free;
    result := outBmp;
end;

{ Mitigate input from user }
function BitmapFactory.mitigateInput(): boolean;

var
  Strategy: TMitigationActionStrategy;
  return: boolean;
begin

  { Test if user has enter the correct number of input arguments }
  if ParamCount < 3 then
  begin
    Writeln('Usage: BitmapTool <switch> input.bmp output.bmp optional argument');
    result := false;
  end;
  return := true;
  { Check input arguments switching on first input argument }
  case (ParamStr(1)) of
    '-s':  Strategy := TsStrategy.Create;
    '--scale': Strategy := TscaleStrategy.Create;
    '-r':  Strategy := TrStrategy.Create;
    '--rotate':  Strategy := TrotateStrategy.Create;
    '-#':  Strategy := TsharpStrategy.Create;
    '--sharpen':  Strategy := TsharpenStrategy.Create;
    '-b':  Strategy := TbStrategy.Create;
    '--blur':  Strategy := TblurStrategy.Create;
    '-q':  Strategy := TqStrategy.Create;
    '--quantize':  Strategy := TquantizeStrategy.Create;
    '-d':   Strategy := TdStrategy.Create;
    '--dither':  Strategy := TditherStrategy.Create;
    '-e':  Strategy := TeStrategy.Create;
    '--edge':  Strategy := TedgeStrategy.Create;
    else

    { Give user list of switch options due to input error }
    begin
      writeln('switch needs to be defined');
      writeln('-s    scale image');
      writeln('--scale    scale image');
      writeln('-r    rotate image');
      writeln('--rotate   rotate image');
      writeln('-#    sharpen image');
      writeln('--sharpen    sharpen image');
      writeln('-b    blur image');
      writeln('--blur    blur image');
      writeln('-q    quantize image');
      writeln('--quantize    quantize image');
      writeln('-d    dither image');
      writeln('--dither    dither image');
      writeln('-e    edge detect image');
      writeln('--edge    edge detect image');
      return := false;
  end; end;
  if return then
  begin

    { Execute mitigation strategy for corrosponding concrete product }
    return := Strategy.Execute;
    Strategy.Free;
  end;

  { Return result of mitigation strategy testing }
  result := return;
end;

{ Mitigation strategy for input argument -s or scale concrete product }
function TsStrategy.Execute(): boolean;

var
  Attr: longint;
  testDouble: double;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return: boolean;

begin

  return := true;

  { Check correct number of arguments have been entered }
  if ParamCount <> 4 then
  begin
    writeln('Usage: BitmapTool -s input.bmp output.bmp <double> scale');
    return := false;
  end;
  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if (PChar(@header[1])^ <> 'M') and (return) then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
  end

  else if (FileExists(ParamStr(2)) = false) and (return) then
  begin
    writeln('Usage: BitmapTool -s input.bmp output.bmp <double> scale');
    writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

    { Check if output file already exists }
    if (FileExists(ParamStr(3))) and (return) then
    begin
      writeln('File already exists do you wish to overwrite it ?');
      writeln('Please press y and then enter to continue or another key and then enter to cancel process :');

      { Test any key other than y is pressed }
      readln(userInput);
      if userInput <> 'y' then
      begin
        writeln('Process canceled');
        return := false
      end

      { y is pressed continue }
      else
      begin

        { Test file is writable }
        AssignFile(F, ParamStr(3));
        try
          Rewrite(F);
        except
          writeln('File is not creatable');
          CloseFile(F);
          return := false;
        end;

        { Get the files attributes }
        Attr := FileGetAttr(ParamStr(3));

        { Check if the file is read-only }
        if (Attr and faReadOnly) = faReadOnly then
        begin
          writeln('File is read only');
          CloseFile(F);
          return := false;
        end;
      end;
    end

    { Output filename does not exist continue }
    else if (FileExists(ParamStr(3)) = false) and (return) then
    begin

      { Check file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;
      CloseFile(F);
    end;

    { Test if fourth input argument is a double }
    if return then
    begin
      try
        testDouble := StrToFloat(ParamStr(4));
      except
        on testDouble : Exception do
        begin
          writeln('Fourth argument must be a double example 0.5 is half scale 1.5 is one and a half scale');
          return := false;
        end; 
      end;
    end;

  { Return result of tests }
  result := return;
end;

{ Mitigation strategy for input argument --scale or scale concrete product }
function TscaleStrategy.Execute(): boolean;

var
  Attr: longint;
  testDouble: double;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return: boolean;

begin

  return := true;

  { Check correct number of arguments have been entered }
  if ParamCount <> 4 then
  begin
    Writeln('Usage: BitmapTool --scale input.bmp output.bmp <double> scale');
    return := false;
  end;

  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if (PChar(@header[1])^ <> 'M') and (return) then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end
  end

  else if (FileExists(ParamStr(2)) = false) and (return) then
  begin
    Writeln('Usage: BitmapTool --scale input.bmp output.bmp <double> scale');
    Writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

  { Check if output file already exists }
  if (FileExists(ParamStr(3))) and (return) then
  begin
    writeln('File already exists do you wish to overwrite it ?');
    writeln('Please press y and then enter to continue or another key and then enter to cancel process :');

    { Test any key other than y is pressed }
    readln(userInput);
    if  userInput <> 'y' then
    begin
      writeln('Process canceled');
      return := false
    end

    { y is pressed continue }
    else
    begin

      { Test file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;

      { Get the files attributes }
      Attr := FileGetAttr(ParamStr(3));

      { Check if the file is read-only }
      if (Attr and faReadOnly) = faReadOnly then
      begin
        writeln('File is read only');
        CloseFile(F);
        return := false;
      end
    end
  end

  { Output filename does not exist continue }
  else if (FileExists(ParamStr(3)) = false) and (return) then
  begin

    { Check file is writable }
    AssignFile(F, ParamStr(3));
    try
      Rewrite(F);
    except
      writeln('File is not creatable');
      CloseFile(F);
      return := false;
    end;
    CloseFile(F);
  end;

  { Test if fourth input argument is a double }
  if return then
  begin
    try
      testDouble := StrToFloat(ParamStr(4));
    except
      on testDouble : Exception do
      begin
        writeln('Fourth argument must be a double example 0.5 is half scale 1.5 is one and a half scale');
        return := false;
      end;
    end;
  end;

  { Return result of tests }
  result := return;
end;

{ Mitigation strategy for input argument -r or rotate concrete product }
function TrStrategy.Execute():boolean;

var
  Attr: longint;
  testDouble: double;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return: boolean;

begin

  return := true;

  { Check correct number of arguments have been entered }
  if ParamCount <> 4 then
  begin
    Writeln('Usage: BitmapTool -r input.bmp output.bmp <double> angle');
    return := false;
  end;

  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if (PChar(@header[1])^ <> 'M') and (return) then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end
  end

  else if (FileExists(ParamStr(2)) = false) and (return) then
  begin
    Writeln('Usage: BitmapTool -r input.bmp output.bmp <double> angle');
    writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

  { Check if output file already exists }
  if (FileExists(ParamStr(3))) and (return) then
  begin
    writeln('File already exists do you wish to overwrite it ?');
    writeln('Please press y and then enter to continue or another key and then enter to cancel process :');

    { Test any key other than y is pressed }
    readln(userInput);
    if userInput <> 'y' then
    begin
      writeln('Process canceled');
      return := false
    end

    { y is pressed continue }
    else
    begin

      { Test file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;

      { Get the files attributes }
      Attr := FileGetAttr(ParamStr(3));

      { Check if the file is read-only }
      if (Attr and faReadOnly) = faReadOnly then
      begin
        writeln('File is read only');
        CloseFile(F);
        return := false;
      end
    end
  end

  { Output filename does not exist continue }
  else if (FileExists(ParamStr(3)) = false) and (return) then
  begin

    { Check file is writable }
    AssignFile(F, ParamStr(3));
    try
      Rewrite(F);
    except
      writeln('File is not creatable');
      CloseFile(F);
      return := false;
    end;
    CloseFile(F);
  end;

  { Test if fourth input argument is a double }
  if (return) then
  begin
    try
      testDouble := StrToFloat(ParamStr(4));
    except
      on testDouble : Exception do
      begin
        writeln('Fourth argument must be a double between 0 and 1');
        return := false;
      end;
    end;
  end;

  { Return result of tests }
  result := return;
end;

{ Mitigation strategy for input argument --rotate or rotate concrete product }
function TrotateStrategy.Execute(): boolean;

var
  Attr: longint;
  testDouble: double;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return: boolean;

begin

  return := true;

  { Check correct number of arguments have been entered }
  if ParamCount <> 4 then
  begin
    Writeln('Usage: BitmapTool --rotate input.bmp output.bmp <double> angle');
    return := false;
  end;

  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if (PChar(@header[1])^ <> 'M') and (return) then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end
  end

  else if (FileExists(ParamStr(2)) = false) and (return) then
  begin
    Writeln('Usage: BitmapTool --rotate input.bmp output.bmp <double> angle');
    writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

  { Check if output file already exists }
  if (FileExists(ParamStr(3))) and (return) then
  begin
    writeln('File already exists do you wish to overwrite it ?');
    writeln('Please press y and then enter to continue or another key and then enter to cancel process :');

    { Test any key other than y is pressed }
    read(userInput);
    if userInput <> 'y' then
    begin
      writeln('Process canceled');
      return := false
    end

    { y is pressed continue }
    else
    begin

      { Test file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;

      { Get the files attributes }
      Attr := FileGetAttr(ParamStr(3));

      { Check if the file is read-only }
      if (Attr and faReadOnly) = faReadOnly then
      begin
        writeln('File is read only');
        CloseFile(F);
        return := false;
      end
    end
  end

  { Output filename does not exist continue }
  else if (FileExists(ParamStr(3)) = false) and (return) then
  begin

    { Check file is writable }
    AssignFile(F, ParamStr(3));
    try
      Rewrite(F);
    except
      writeln('File is not creatable');
      CloseFile(F);
      return := false;
    end;
    CloseFile(F);
  end;

  { Test if fourth input argument is a double }
  if (return) then
  begin
    try
      testDouble := StrToFloat(ParamStr(4));
    except
      on testDouble : Exception do
      begin
        writeln('Fourth argument must be a double between 0 and 1');
        return := false;
      end;
    end;
  end;

  { Return result of tests }
  result := return;
end;

{ Mitigation strategy for -# input argument or sharpen concrete product }
function TsharpStrategy.Execute(): boolean;

var
  Attr: longint;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return: boolean;

begin

  return := true;

  { Check correct number of arguments have been entered }
  if ParamCount <> 3 then
  begin
    Writeln('Usage: BitmapTool -# input.bmp output.bmp');
    return := false;
  end;

  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if (PChar(@header[1])^ <> 'M') and (return) then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end
  end

  else if (FileExists(ParamStr(2)) = false) and (return) then
  begin
    Writeln('Usage: BitmapTool -# input.bmp output.bmp <double>');
    Writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

  { Check if output file already exists }
  if (FileExists(ParamStr(3))) and (return) then
  begin
    writeln('File already exists do you wish to overwrite it ?');
    writeln('Please press y and then enter to continue or another key and then enter to cancel process :');

    { Test any key other than y is pressed }
    readln(userInput);
    if userInput <> 'y' then
    begin
      writeln('Process canceled');
      return := false
    end

    { y is pressed continue }
    else 
    begin

      { Test file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;

      { Get the files attributes }
      Attr := FileGetAttr(ParamStr(3));

      { Check if the file is read-only }
      if (Attr and faReadOnly) = faReadOnly then
      begin
        writeln('File is read only');
        CloseFile(F);
        return := false;
      end
    end
  end

  { Output filename does not exist continue }
  else if (FileExists(ParamStr(3)) = false) and (return) then
  begin

    { Check file is writable }
    AssignFile(F, ParamStr(3));
    try
      Rewrite(F);
    except
      writeln('File is not creatable');
      CloseFile(F);
      return := false;
    end;
    CloseFile(F);
  end;

  { Return result of tests }
  result := return;
end;

{ Mitigation strategy for --sharpen or sharpen concrete product }
function TsharpenStrategy.Execute(): boolean;

var
  Attr: longint;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return: boolean;

begin

  return := true;

  { Check correct number of arguments have been entered }
  if ParamCount <> 3 then
  begin
    Writeln('Usage: BitmapTool --sharpen input.bmp output.bmp');
    return := false;
  end;

  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if (PChar(@header[1])^ <> 'M') and (return) then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end
  end

  else if (FileExists(ParamStr(2)) = false) and (return) then
  begin
    Writeln('Usage: BitmapTool --sharpen input.bmp output.bmp');
    Writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

  { Check if output file already exists }
  if (FileExists(ParamStr(3))) and (return) then
  begin
    writeln('File already exists do you wish to overwrite it ?');
    writeln('Please press y and then enter to continue or another key and then enter to cancel process :');

    { Test any key other than y is pressed }
    readln(userInput);
    if userInput <> 'y' then
    begin
      writeln('Process canceled');
      return := false
    end

    { y is pressed continue }
    else
    begin

      { Test file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;

      { Get the files attributes }
      Attr := FileGetAttr(ParamStr(3));

      { Check if the file is read-only }
      if (Attr and faReadOnly) = faReadOnly then
      begin
        writeln('File is read only');
        CloseFile(F);
        return := false;
      end;
    end;
  end

  { Output filename does not exist continue }
  else if (FileExists(ParamStr(3)) = false) and (return) then
  begin

    { Check file is writable }
    AssignFile(F, ParamStr(3));
    try
      Rewrite(F);
    except
      writeln('File is not creatable');
      CloseFile(F);
      return := false;
    end;
    CloseFile(F);
  end;

  { Return result of tests }
  result := return;
end;

{ Mitigation strategy for -b input argument or blur concrete product }
function TbStrategy.Execute(): boolean;

var
  Attr: longint;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return: boolean;

begin

  return := true;

  { Check correct number of arguments have been entered }
  if ParamCount <> 3 then
  begin
    Writeln('Usage: BitmapTool -b input.bmp output.bmp');
    return := false;
  end;

  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if (PChar(@header[1])^ <> 'M') and (return) then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end
  end

  else if (FileExists(ParamStr(2)) = false) and (return) then
  begin
    Writeln('Usage: BitmapTool -b input.bmp output.bmp');
    writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

  { Check if output file already exists }
  if (FileExists(ParamStr(3))) and (return) then
  begin
    writeln('File already exists do you wish to overwrite it ?');
    writeln('Please press y and then enter to continue or another key and then enter to cancel process :');

    { Test any key other than y is pressed }
    readln(userInput);
    if userInput <> 'y' then
    begin
      writeln('Process canceled');
      return := false
    end

    { y is pressed continue }
    else
    begin

      { Test file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;

      { Get the files attributes }
      Attr := FileGetAttr(ParamStr(3));

      { Check if the file is read-only }
      if (Attr and faReadOnly) = faReadOnly then
      begin
        writeln('File is read only');
        CloseFile(F);
        return := false;
      end;
    end;
  end

  { Output filename does not exist continue }
  else if (FileExists(ParamStr(3)) = false) and (return) then
  begin

    { Check file is writable }
    AssignFile(F, ParamStr(3));
    try
      Rewrite(F);
    except
      writeln('File is not creatable');
      CloseFile(F);
      return := false;
    end;
    CloseFile(F);
  end;

  { Return result of tests }
  result := return;
end;

{ Mitigation strategy for --blur input argument or blur concrete product }
function TblurStrategy.Execute(): boolean;

var
  Attr: longint;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return: boolean;

begin

  return := true;

  { Check correct number of arguments have been entered }
  if ParamCount <> 3 then
  begin
    Writeln('Usage: BitmapTool --blur input.bmp output.bmp');
    return := false;
  end;

  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if (PChar(@header[1])^ <> 'M') and (return) then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end
  end

  else if (FileExists(ParamStr(2)) = false) and (return) then
  begin
    Writeln('Usage: BitmapTool --blur input.bmp output.bmp');
    writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

  { Check if output file already exists }
  if (FileExists(ParamStr(3))) and (return) then
  begin
    writeln('File already exists do you wish to overwrite it ?');
    writeln('Please press y and then enter to continue or another key and then enter to cancel process :');

    { Test any key other than y is pressed }
    readln(userInput);
    if userInput <> 'y' then
    begin
      writeln('Process canceled');
      return := false
    end

    { y is pressed continue }
    else
    begin

      { Test file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;

      { Get the files attributes }
      Attr := FileGetAttr(ParamStr(3));

      { Check if the file is read-only }
      if (Attr and faReadOnly) = faReadOnly then
      begin
        writeln('File is read only');
        CloseFile(F);
        return := false;
      end
    end
  end

  { Output filename does not exist continue }
  else if (FileExists(ParamStr(3)) = false) and (return) then
  begin

    { Check file is writable }
    AssignFile(F, ParamStr(3));
    try
      Rewrite(F);
    except
      writeln('File is not creatable');
      CloseFile(F);
      return := false;
    end;
    CloseFile(F);
  end;

  { Return result of tests }
  result := true;
end;

{ Mitigation strategy for -q input argument or quantize concrete product }
function TqStrategy.Execute(): boolean;

var
  Attr: longint;
  testInteger: integer;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return: boolean;

begin

  return := true;

  { Check correct number of arguments have been entered }
  if ParamCount <> 4 then
  begin
    Writeln('Usage: BitmapTool -q input.bmp output.bmp <integer> colours');
    return := false;
  end;

  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if PChar(@header[1])^ <> 'M' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end
  end

  else if (FileExists(ParamStr(2)) = false) and (return) then
  begin
    Writeln('Usage: BitmapTool -q input.bmp output.bmp <integer> colours');
    Writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

  { Check if output file already exists }
  if (FileExists(ParamStr(3))) and (return) then
  begin
    writeln('File already exists do you wish to overwrite it ?');
    writeln('Please press y and then enter to continue or another key and then enter to cancel process :');

    { Test any key other than y is pressed }
    readln(userInput);
    if userInput <> 'y' then
    begin
      writeln('Process canceled');
      return := false
    end

    { y is pressed continue }
    else
    begin

      { Test file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;

      { Get the files attributes }
      Attr := FileGetAttr(ParamStr(3));

      { Check if the file is read-only }
      if (Attr and faReadOnly) = faReadOnly then
      begin
        writeln('File is read only');
        CloseFile(F);
        return := false;
      end
    end
  end

  { Output filename does not exist continue }
  else if (FileExists(ParamStr(3)) = false) and (return) then
  begin

    { Check file is writable }
    AssignFile(F, ParamStr(3));
    try
      Rewrite(F);
    except
      writeln('File is not creatable');
      CloseFile(F);
      return := false;
    end;
    CloseFile(F);
  end;

  { Test if fourth input argument is an integer }
  if (return) then
  begin
    try
      testInteger := StrToInt(ParamStr(4));
    except
      on testInteger : Exception do
      begin
        writeln('Fourth argument must be an integer representing colour count');
        return := false;
      end;
    end;
  end;

  { Return result of tests }
  result := true;
end;

{ Mitigation strategy for --quantize or quantize concrete product }
function TquantizeStrategy.Execute(): boolean;

var
  Attr: longint;
  testInteger: integer;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return: boolean;

begin

  { Check correct number of arguments have been entered }
  if ParamCount <> 4 then
  begin
    Writeln('Usage: BitmapTool --quantize input.bmp output.bmp <integer> colours');
    return := false;
  end;

  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if (PChar(@header[1])^ <> 'M') and (return) then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end
  end

  else if (FileExists(ParamStr(2)) = false) and (return) then
  begin
    Writeln('Usage: BitmapTool --quantize input.bmp output.bmp <integer> colours');
    writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

  { Check if output file already exists }
  if (FileExists(ParamStr(3))) and (return) then
  begin
    writeln('File already exists do you wish to overwrite it ?');
    writeln('Please press y and then enter to continue or another key and then enter to cancel process :');

    { Test any key other than y is pressed }
    readln(userInput);
    if userInput <> 'y' then
    begin
      writeln('Process canceled');
      return := false
    end

    { y is pressed continue }
    else
    begin

      { Test file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;

      { Get the files attributes }
      Attr := FileGetAttr(ParamStr(3));

      { Check if the file is read-only }
      if (Attr and faReadOnly) = faReadOnly then
      begin
        writeln('File is read only');
        CloseFile(F);
        return := false;
      end
    end
  end

  { Output filename does not exist continue }
  else if (FileExists(ParamStr(3)) = false) and (return) then
  begin

    { Check file is writable }
    AssignFile(F, ParamStr(3));
    try
      Rewrite(F);
    except
      writeln('File is not creatable');
      CloseFile(F);
      return := false;
    end;
    CloseFile(F);
  end;

  { Test if fourth input argument is an integer }
  if (return) then
  begin
    try
      testInteger := StrToInt(ParamStr(4));
    except
      on testInteger : Exception do
      begin
        writeln('Fourth argument must be an integer representing colour count');
        return := false;
      end;
    end;
  end;

  { Return result from tests }
  result := return;
end;

{ Mitigation strategy for -d input argument or dither concrete product }
function TdStrategy.Execute(): boolean;

var
  Attr: longint;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return: boolean;

begin

  return := true;

  { Check correct number of arguments have been entered }
  if ParamCount <> 3 then
  begin
    Writeln('Usage: BitmapTool -d input.bmp output.bmp');
    return := false;
  end;

  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if (PChar(@header[1])^ <> 'M') and (return) then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end
  end

  else if (fileExists(ParamStr(2)) = false) and (return) then
  begin
    Writeln('Usage: BitmapTool -d input.bmp output.bmp');
    writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

  { Check if output file already exists }
  if (FileExists(ParamStr(3))) and (return) then
  begin
    writeln('File already exists do you wish to overwrite it ?');
    writeln('Please press y and then enter to continue or another key and then enter to cancel process :');

    { Test any key other than y is pressed }
    readln(userInput);
    if userInput <> 'y' then
    begin
      writeln('Process canceled');
      return := false
    end

    { y is pressed continue }
    else
    begin

      { Test file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;

      { Get the files attributes }
      Attr := FileGetAttr(ParamStr(3));

      { Check if the file is read-only }
      if (Attr and faReadOnly) = faReadOnly then
      begin
        writeln('File is read only');
        CloseFile(F);
        return := false;
      end
    end
  end

  { Output filename does not exist continue }
  else if (FileExists(ParamStr(3)) = false) and (return) then
  begin

    { Check file is writable }
    AssignFile(F, ParamStr(3));
    try
      Rewrite(F);
    except
      writeln('File is not creatable');
      CloseFile(F);
      return := false;
    end;
    CloseFile(F);
  end;

  { Return result of tests }
  result := true;
end;

{ Mitigation strategy for --dither input argument or dither concrete product }
function TditherStrategy.Execute(): boolean;

var
  Attr: longint;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return: boolean;

begin

  return := true;

  { Check correct number of arguments have been entered }
  if ParamCount <> 3 then
  begin
    Writeln('Usage: BitmapTool --dither input.bmp output.bmp');
    return := false;
  end;

  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if (PChar(@header[1])^ <> 'M') and (return) then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end
  end

  else if (FileExists(ParamStr(2)) = false) and (return) then
  begin
    Writeln('Usage: BitmapTool --dither input.bmp output.bmp');
    Writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

  { Check if output file already exists }
  if (FileExists(ParamStr(3))) and (return) then
  begin
    writeln('File already exists do you wish to overwrite it ?');
    writeln('Please enter y to continue or another key to cancel process :');

    { Test any key other than y is pressed }
    readln(userInput);
    if userInput <> 'y' then
    begin
      writeln('Process canceled');
      return := false
    end

    { y is pressed continue }
    else
    begin

      { Test file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;

      { Get the files attributes }
      Attr := FileGetAttr(ParamStr(3));

      { Check if the file is read-only }
      if (Attr and faReadOnly) = faReadOnly then
      begin
        writeln('File is read only');
        CloseFile(F);
        return := false;
      end
    end
  end

  { Output filename does not exist continue }
  else if (FileExists(ParamStr(3)) = false) and (return) then
  begin

    { Check file is writable }
    AssignFile(F, ParamStr(3));
    try
      Rewrite(F);
    except
      writeln('File is not creatable');
      CloseFile(F);
      return := false;
    end;
    CloseFile(F);
  end;

  { Return result of tests }
  result := true;
end;

{ Mitigation strategy for -e input arguement or edge concrete product }
function TeStrategy.Execute(): boolean;

var
  Attr: longint;
  testInteger: integer;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return : boolean;

begin

  return := true;

  { Check correct number of arguments have been entered }
  if ParamCount <> 4 then
  begin
    Writeln('Usage: BitmapTool -e input.bmp output.bmp <integer> threshold');
    return := false;
  end;

  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if (PChar(@header[1])^ <> 'M') and (return) then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end
  end

  else if (FileExists(ParamStr(2)) = false) and (return) then 
  begin
    Writeln('Usage: BitmapTool -e input.bmp output.bmp <integer> threshold');
    Writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

  { Check if output file already exists }
  if FileExists(ParamStr(3)) and (return) then
  begin
    writeln('File already exists do you wish to overwrite it ?');
    writeln('Please enter y to continue or another key to cancel process :');

    { Test any key other than y is pressed }
    readln(userInput);
    if userInput <> 'y' then
    begin
      writeln('Process canceled');
      return := false
    end

    { y is pressed continue }
    else
    begin

      { Test file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;

      { Get the files attributes }
      Attr := FileGetAttr(ParamStr(3));

      { Check if the file is read-only }
      if (Attr and faReadOnly) = faReadOnly then
      begin
        writeln('File is read only');
        CloseFile(F);
        return := false;
      end
    end
  end

  { Output filename does not exist continue }
  else
  begin

    { Check file is writable }
    AssignFile(F, ParamStr(3));
    try
      Rewrite(F);
    except
      writeln('File is not creatable');
      CloseFile(F);
      return := false;
    end;
    CloseFile(F);
  end;

  { Test if fourth input argument is an integer }
  if (return) then
  begin
    try
      testInteger := StrToInt(ParamStr(4));
    except
      on testInteger : Exception do
      begin
        writeln('Fourth argument must be an integer representing threshold');
        return := false;
      end;
    end;
  end;

  { Return result of tests }
  result := return;
end;

{ Mitigation strategy for --edge input argument or edge concrete product }
function TedgeStrategy.Execute(): boolean;

var
  Attr: longint;
  testInteger: integer;
  header: array[0..53] of byte;
  F, inFile: file;
  userInput: char;
  return: boolean;

begin

  return := true;

  { Check correct number of arguments have been entered }
  if ParamCount <> 4 then
  begin
    Writeln('Usage: BitmapTool --edge input.bmp output.bmp <integer> colours');
    return := false;
  end;

  { Check if second argument is a bitmap file }
  if (FileExists(ParamStr(2))) and (return) then
  begin
    Assign(inFile, ParamStr(2));
    Reset(inFile, 1);
    BlockRead(inFile, header, 54);
    if PChar(@header[0])^ <> 'B' then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end;
    if (PChar(@header[1])^ <> 'M') and (return) then
    begin
      writeln('Input file is not a valid bitmap');
      return := false;
    end
  end

  else if (FileExists(ParamStr(2)) = false) and (return) then
  begin
    Writeln('Usage: BitmapTool --edge input.bmp output.bmp <integer> threshold');
    writeln('Please use a valid bitmap file for the input.bmp argument');
    return := false;
  end;

  { Check if output file already exists }
  if (FileExists(ParamStr(3))) and (return) then
  begin
    writeln('File already exists do you wish to overwrite it ?');
    writeln('Please enter y to continue or another key to cancel process :');

    { Test any key other than y is pressed }
    readln(userInput);
    if userInput <> 'y' then
    begin
      writeln('Process canceled');
      return := false
    end

    { y is pressed continue }
    else
    begin

      { Test file is writable }
      AssignFile(F, ParamStr(3));
      try
        Rewrite(F);
      except
        writeln('File is not creatable');
        CloseFile(F);
        return := false;
      end;

      { Get the files attributes }
      Attr := FileGetAttr(ParamStr(3));

      { Check if the file is read-only }
      if (Attr and faReadOnly) = faReadOnly then
      begin
        writeln('File is read only');
        CloseFile(F);
        return := false;
      end;
    end
  end

  { Output filename does not exist continue }
  else if (FileExists(ParamStr(3)) = false) and (return) then
  begin

    { Check file is writable }
    AssignFile(F, ParamStr(3));
    try
      Rewrite(F);
    except
      writeln('File is not creatable');
      CloseFile(F);
      return := false;
    end;
    CloseFile(F);
  end;

  { Test if fourth input argument is a integer }
  if (return) then
  begin
    try
      testInteger := StrToInt(ParamStr(4));
    except
      on testInteger : Exception do
      begin
        writeln('Fourth argument must be an integer representing threshold');
        return := false;
      end;
    end;
  end;

  { Return result of tests }
  result := return;
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
  
  { Create Factory to build bitmap tools }
  BitmapFactoryVar := BitmapFactory.Create();

  { Mitigate user input and file errors }
  if BitmapFactoryVar.mitigateInput then
  begin

    { Scale }
    if (arg = '-s') or (arg = '--scale') then
    begin
      PixArray := BitmapFactoryVar.LoadBitmap(input);
      BitmapToolVar := BitmapFactoryVar.createProduct('Scale');
      outBmp := BitmapToolVar.use(0,StrToFloat(ParamStr(4)),PixArray);
      BitmapFactoryVar.SaveBitmap(output, outBmp);
    end;

    { Rotate }
    if (arg = '-r') or (arg = '--rotate') then
    begin
      PixArray := BitmapFactoryVar.LoadBitmap(input);
      BitmapToolVar := BitmapFactoryVar.createProduct('Rotate');
      outBmp := BitmapToolVar.use(0,StrToFloat(ParamStr(4)),PixArray);
      BitmapFactoryVar.SaveBitmap(output, outBmp);
    end;

    { Blur }
    if (arg = '-b') or (arg = '--blur') then
    begin
      PixArray := BitmapFactoryVar.LoadBitmap(input);
      BitmapToolVar := BitmapFactoryVar.createProduct('Blur');
      outBmp := BitmapToolVar.use(0,0,PixArray);
      BitmapFactoryVar.SaveBitmap(output, outBmp);
    end;

    { Sharpen }
    if (arg = '-#') or (arg = '--sharpen') then
    begin
      PixArray := BitmapFactoryVar.LoadBitmap(input);
      BitmapToolVar := BitmapFactoryVar.createProduct('Sharpen');
      outBmp := BitmapToolVar.use(0,0,PixArray);
      BitmapFactoryVar.SaveBitmap(output, outBmp);
    end;

    { Quantize }
    if (arg = '-q') or (arg = '--quantize') then
    begin
      PixArray := BitmapFactoryVar.LoadBitmap(input);
      BitmapToolVar := BitmapFactoryVar.createProduct('Quantize');
      outBmp := BitmapToolVar.use(StrToInt(ParamStr(4)),0,PixArray);
      BitmapFactoryVar.SaveBitmap(output, outBmp);
    end;

    { Dither }
    if (arg = '-d') or (arg = '--dither') then
    begin
      PixArray := BitmapFactoryVar.LoadBitmap(input);
      BitmapToolVar := BitmapFactoryVar.createProduct('Dither');
      outBmp := BitmapToolVar.use(0,0,PixArray);
      BitmapFactoryVar.SaveBitmap(output, outBmp);
    end;

    { Edge }
    if (arg = '-e') or (arg = '--edge') then
    begin
      PixArray := BitmapFactoryVar.LoadBitmap(input);
      BitmapToolVar := BitmapFactoryVar.createProduct('Edge');
      outBmp := BitmapToolVar.use(StrToInt(ParamStr(4)),0,PixArray);
      BitmapFactoryVar.SaveBitmap(output, outBmp);
    end;
  end;
end.

