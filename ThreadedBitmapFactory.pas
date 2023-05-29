//
// Created by Matthew Abbott 23/4/2023
//

{$mode objfpc}
{$M+}

program BitmapToolFactory;

uses
   cthreads, math, sysutils, classes;

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

  TColourTable = array[0..255] of TPixel; // colour table for quantization
  bmpArray = array of array of TPixel; // Array to store images in
  arrayOfBmpArray = array of bmpArray; // array of images for threaded execution
  PPixel = ^TPixel; // pointer to a pixel
  PArray = ^bmpArray; // pointer to entire bmp array

  BmpArrayFacade = class
  private
    refArray: array of ^bmpArray;
    refArraySizes: array of integer;
  public
    constructor Create(inputArrays: arrayOfBmpArray);
    function getBlueByte(x, y: integer): byte;
    function getGreenByte(x, y: integer): byte;
    function getRedByte(x, y: integer): byte;
    function getBlueInt(x, y: integer): integer;
    function getGreenInt(x, y: integer): integer;
    function getRedInt(x, y: integer): integer;
    procedure setBlue(x, y: integer; inByte: byte);
    procedure setGreen(x, y: integer; inByte: byte);
    procedure setRed(x, y: integer; inByte: byte);
    function getInH(): integer;
    function getInW(): integer;
  end;
    
    
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
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray; virtual; abstract;
  end;

  { Box Blur Concrete Product }
  BitmapBoxBlur = class(BitmapTool)
    private 
//      function ApplyBoxBlur(x, y: integer; Bitmap: bmpArray): TPixel;
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray; override;
  end;

  { Box Blur Threaded Concrete Product } 
  BoxBlurThread = class(TThread)
  private
    inBmp: bmpArray;
    BlurredBitmap: bmpArray;
    function ApplyBoxBlur(x, y: integer; Bitmap: bmpArray): TPixel;
  protected
    procedure Execute(); override;
  public
    constructor Create(inputBmp: bmpArray);
    function GetResult(): bmpArray;
  end;

  { Rotate Concrete Product }
  BitmapRotate = class(BitmapTool)
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray; override;
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
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray; override;
  end;

  { Sharpen Concrete Product }
  BitmapSharpen = class(BitmapTool)
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray; override;
  end;

  { Quantize Concrete Product }
  BitmapQuantize = class(BitmapTool)
    private
      function Distance(Colour1, Colour2: TPixel): integer;
      function FindNearestColour(TargetColour: TPixel; ColourTable: TColourTable; NumColours: integer): TPixel;
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray; override;
  end;

  { Dither Concrete Product }
  BitmapDither = class(BitmapTool)
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray; override;
  end;

  { Edge Detection Concrete Product }
  BitmapEdgeDetect = class(BitmapTool)
    private
      function detect(inBmp: bmpArray; Threshold: TPixel; inH, inW: integer): bmpArray;
    public
      function use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray; override;
  end;


  { Factory for creating Bitmap Tool Products }
  BitmapFactory = class
    public
      function createProduct(productType: string): BitmapTool;
      function LoadBitmap(filename: string): arrayOfBmpArray;
      procedure SaveBitmap(filename: string; bmp: arrayOfBmpArray);
      function mitigateInput(): boolean;
  end;

  { Bridge implementor for file operations }
  TFileAPI = class
  public
    procedure SaveToFile(fileName: string; bmp: arrayOfBmpArray); virtual; abstract;
    function LoadFromFile(fileName: string): arrayOfBmpArray; virtual; abstract;
  end;

  { Bridge abstraction for file operations }
  TFileOperation = Class
  protected
    fFileAPI: TFileAPI;
  public
    constructor Create(FileAPI: TFileAPI);
    procedure Save(bmp: arrayOfBmpArray); virtual; abstract;
    function Load(): arrayOfBmpArray; virtual; abstract;
  end;

  { Bridge refined abstraction for file operations }
  TFileTransfer = class(TFileOperation)
  private
    fFileName: string;
  public
    constructor Create(fileName: string; FileAPI: TFileAPI);
    procedure Save(bmp: arrayOfBmpArray); override;
    function Load(): arrayOfBmpArray; override;
  end;

  { Bridge Concrete Implementor for Bitmap Format }
  TBmpFileAPI = class(TFileAPI)
  public
    procedure SaveToFile(fileName: string; bmp: arrayOfBmpArray); override;
    function LoadFromFile(fileName: string): arrayOfBmpArray; override;
  end;

{ Pixel constructor }
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

constructor BmpArrayFacade.Create(inputArrays: arrayOfBmpArray);
var
  i: integer;

begin
  setLength(refArray, length(inputArrays));
  setLength(refArraySizes, length(inputArrays));

  for i := 0 to high(inputArrays) do
  begin
    refArray := @inputArrays[i];
    refArraySizes[i] := length(inputArrays[i]);
  end;
end;

function BmpArrayFacade.getBlueByte(x, y: integer): byte;
var
  arrayIndex, elementIndex, i, size: integer;

begin
  arrayIndex := 0;
  elementIndex := y;
  

  for i := 0 to high(refArraySizes) do
  begin
    size := refArraySizes[i];
    if (elementIndex < size) then
      break;

    elementIndex := elementIndex - size;
    inc(arrayIndex);
  end;

  result := refArray[arrayIndex]^[elementIndex div size][x].getBlueByte;
end;

function BmpArrayFacade.getGreenByte(x, y: integer): byte;
var
  arrayIndex, elementIndex, i, size: integer;

begin
  arrayIndex := 0;
  elementIndex := y;
  

  for i := 0 to high(refArraySizes) do
  begin
    size := refArraySizes[i];
    if (elementIndex < size) then
      break;

    elementIndex := elementIndex - size;
    inc(arrayIndex);
  end;

  result := refArray[arrayIndex]^[elementIndex div size][x].getGreenByte;
end;

function BmpArrayFacade.getRedByte(x, y: integer): byte;
var
  arrayIndex, elementIndex, i, size: integer;

begin
  arrayIndex := 0;
  elementIndex := y;
  

  for i := 0 to high(refArraySizes) do
  begin
    size := refArraySizes[i];
    if (elementIndex < size) then
      break;

    elementIndex := elementIndex - size;
    inc(arrayIndex);
  end;

 result := refArray[arrayIndex]^[elementIndex div size][x].getRedByte;
end;

function BmpArrayFacade.getBlueInt(x, y: integer): integer;
var
  arrayIndex, elementIndex, i, size: integer;

begin
  arrayIndex := 0;
  elementIndex := y;
  

  for i := 0 to high(refArraySizes) do
  begin
    size := refArraySizes[i];
    if (elementIndex < size) then
      break;

    elementIndex := elementIndex - size;
    inc(arrayIndex);
  end;

  result := refArray[arrayIndex]^[elementIndex div size][x].getBlueInt;
end;

function BmpArrayFacade.getGreenInt(x, y: integer): integer;
var
  arrayIndex, elementIndex, i, size: integer;

begin
  arrayIndex := 0;
  elementIndex := y;
  

  for i := 0 to high(refArraySizes) do
  begin
    size := refArraySizes[i];
    if (elementIndex < size) then
      break;

    elementIndex := elementIndex - size;
    inc(arrayIndex);
  end;

  result := refArray[arrayIndex]^[elementIndex div size][x].getGreenInt;
end;

function BmpArrayFacade.getRedInt(x, y: integer): integer;
var
  arrayIndex, elementIndex, i, size: integer;

begin
  arrayIndex := 0;
  elementIndex := y;
  

  for i := 0 to high(refArraySizes) do
  begin
    size := refArraySizes[i];
    if (elementIndex < size) then
      break;

    elementIndex := elementIndex - size;
    inc(arrayIndex);
  end;

 result := refArray[arrayIndex]^[elementIndex div size][x].getRedInt;
end;

procedure BmpArrayFacade.setBlue(x, y: integer; inByte: byte);
var
  arrayIndex, elementIndex, i, size: integer;

begin
  arrayIndex := 0;
  elementIndex := y;

  for i := 0 to high(refArraySizes) do
  begin
    size := refArraySizes[i];
    if elementIndex < size then
      break;

    elementIndex := elementIndex - size;
    inc(arrayIndex);
  end;

  refArray[arrayIndex]^[elementIndex div size][x].setBlue(inByte);
end;

procedure BmpArrayFacade.setGreen(x, y: integer; inByte: byte);
var
  arrayIndex, elementIndex, i, size: integer;

begin
  arrayIndex := 0;
  elementIndex := y;

  for i := 0 to high(refArraySizes) do
  begin
    size := refArraySizes[i];
    if elementIndex < size then
      break;

    elementIndex := elementIndex - size;
    inc(arrayIndex);
  end;

  refArray[arrayIndex]^[elementIndex div size][x].setGreen(inByte);
end;



procedure BmpArrayFacade.setRed(x, y: integer; inByte: byte);
var
  arrayIndex, elementIndex, i, size: integer;

begin
  arrayIndex := 0;
  elementIndex := y;

  for i := 0 to high(refArraySizes) do
  begin
    size := refArraySizes[i];
    if elementIndex < size then
      break;

    elementIndex := elementIndex - size;
    inc(arrayIndex);
  end;

  refArray[arrayIndex]^[elementIndex div size][x].setRed(inByte);
end;

function BmpArrayFacade.getInH(): integer;
var
  i, inH: integer;

begin
  inH := 0;
  for i := 0 to high(refArraySizes) do
    inH := inH + refArraySizes[i];
  result := inH
end;

function BmpArrayFacade.getInW(): integer;
begin
  result := length(refArray[0]^[0]);
end;
  
{ Constructor for bridge abstraction }
constructor TFileOperation.Create(FileAPI: TFileAPI);
begin
  fFileAPI := FileAPI;
end;

{ Constructor for bridge refined abstraction }
constructor TFileTransfer.Create(fileName: string; FileAPI: TFileAPI);
begin
  inherited Create(FileAPI);
  fFilename := fileName;
end;

{ Save procedure for bridge refined abstraction }
procedure TFileTransfer.Save(bmp: arrayOfBmpArray);
begin
  fFileAPI.SaveToFile(fFileName, bmp);
end;

{ Load function for bridge refined abstraction }
function TFileTransfer.Load(): arrayOfBmpArray;
begin
  result := fFileAPI.LoadFromFile(fFileName);
end;

{ Load bitmap into a two dimensional array }
function TBmpFileAPI.LoadFromFile(filename: string): arrayOfBmpArray;

var
  inFile: file;
  header: array[0..53] of byte;
  pixelSize, start: integer;
  rowSize, paddingSize: integer;
  i, j, w ,h, e: integer;
  bmp: bmpArray;
  tempColourChannel: byte;
  NumCores: integer;
  Arrays: arrayOfBmpArray;

begin

  NumCores := 4;//TThread.ProcessorCount;
  SetLength(Arrays, NumCores);

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
  for i := 0 to NumCores -2 do
    SetLength(Arrays[i], round(h / NumCores), w);
  SetLength(Arrays[NumCores-1], (h) - (round(h / NumCores) * (NumCores -1)), w);
  
  { Read bitmap pixels }
  for e := 0 to NumCores -2 do
  begin
    for i := high(Arrays[i]) downto 0 do
    begin
      for j := 0 to w - 1 do
      begin
        Arrays[e][i, j] := TPixel.Create();
        BlockRead(inFile, tempColourChannel,1);
        Arrays[e][i, j].setBlue(tempColourChannel);
        BlockRead(inFile, tempColourChannel,1); //round(pixelSize/3));
        Arrays[e][i, j].setGreen(tempColourChannel);
        BlockRead(inFile, tempColourChannel,1); // round(pixelSize/3));
        Arrays[e][i, j].setRed(tempColourChannel);
      end;
      if paddingSize > 0 then
      begin
        Seek(inFile, FilePos(inFile) + paddingSize);
      end;
    end;
  end;
writeln('first few parts done');
  for i := high(Arrays[NumCores -1]) downto 0 do
  begin
    for j := 0 to w- 1 do
    begin
      Arrays[NumCores-1][i, j] := TPixel.Create();
      BlockRead(inFile, tempColourChannel, 1);
      Arrays[NumCores-1][i, j].setBlue(tempColourChannel);
      BlockRead(inFile, tempColourChannel, 1);
      Arrays[NumCores-1][i, j].setGreen(tempColourChannel);
      BlockRead(inFile, tempColourChannel, 1);
      Arrays[NumCores-1][i, j].setRed(tempColourChannel);
    end;
writeln('second part done');
    if paddingSize > 0 then
    begin
      Seek(inFile, FilePos(inFile) + paddingSize);
    end;
  end;
writeln('return');
  Close(inFile);
  result := Arrays;
end;

{ Saves Bitmap to file }
procedure TBmpFileAPI.SaveToFile(filename: string; bmp: arrayOfBmpArray);
var
  outFile: file;
  header: array[0..53] of byte;
  pixelSize: integer;
  rowSize, paddingSize: integer;
  i, j, h, e, NumCores: integer;
  outPixel: TPixel;

begin

  NumCores := TThread.ProcessorCount;
  Assign(outFile, filename);
  Rewrite(outFile, 1);
  writeln('save started');
  h := 0;
  for i := 0 to high(bmp) do
    h := h + length(bmp[i]);
  writeln(inttostr(h));
{ Set bitmap header }
  FillChar(header, SizeOf(header), 0);
  header[0] := $42;
  header[1] := $4D;
  PInteger(@header[2])^ := SizeOf(header) + Length(bmp[0][0]) * h * 3;
  header[10] := SizeOf(header);
  header[14] := 40;
  PInteger(@header[18])^ := Length(bmp[0][0]);
  PInteger(@header[22])^ := h;
  PWord(@header[26])^ := 1;
  PWord(@header[28])^ := 24;

  { Get pixel size and row size }
  pixelSize := PWord(@header[28])^ div 8;
  rowSize := (Length(bmp[0][0]) * pixelSize + 3) div 4 * 4;
  paddingSize := rowSize - Length(bmp[0][0]) * pixelSize;

  { Write bitmap header }
  BlockWrite(outFile, header, SizeOf(header));
  
  { Write bitmap pixels }
  outPixel := TPixel.Create();
  for e := 0 to high(bmp) do
  begin
    for i := high(bmp[e]) downto 0 do
    begin
      for j := 0 to high(bmp[e][high(bmp[e])]) do
      begin
        BlockWrite(outFile, bmp[e][i, j].getBlueByte,1);// round(pixelSize/3));
        BlockWrite(outFile, bmp[e][i, j].getGreenByte,1);// round(pixelSize/3));
        BlockWrite(outFile, bmp[e][i, j].getRedByte,1);// round(pixelSize/3));
      end;
      if paddingSize > 0 then
      begin
        outPixel.setBlue(0);
        outPixel.setGreen(0);
        outPixel.setRed(0);
        BlockWrite(outFile, outPixel, paddingSize);
      end;
    end;
  end;

  Close(outFile);
end;

{ Factory Product creation function }
function BitmapFactory.createProduct(productType: string): BitmapTool;
begin

  { Create bitmap tool switched on productType }
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

{ Bitmap factory save to bitmap procedure }
procedure BitmapFactory.SaveBitmap(fileName: string; bmp: arrayOfBmpArray);
var
  F: TFileOperation;
begin

  { Create bridge to bitmap saving procedure and save bitmap }
  F := TFileTransfer.Create(fileName, TBmpFileAPI.Create);
  F.Save(bmp);

end;

{ Bitmap factory load from bitmap function }
function BitmapFactory.LoadBitmap(fileName: string): arrayOfBmpArray;
var
  F: TFileOperation;
  e: integer;
begin

  { Create bridge to bitmap loading function and load bitmap into array }
  F := TFileTransfer.Create(fileName, TBmpFileAPI.Create);
  result := F.Load();

end;

{ BoxBlurThread constructor }
constructor BoxBlurThread.Create(inputBmp: bmpArray);
begin

  { Create thread }
  inherited Create(true);
  inBmp := inputBmp;
  writeln(inttostr(inBmp[0,0].getBlueInt));
  setLength(BlurredBitmap, length(inBmp), length(inBmp[0]));  

  BlurredBitmap := inBmp;
end;

{ Apply a Box Blur to kernel }
function BoxBlurThread.ApplyBoxBlur(x, y: integer; Bitmap: bmpArray): TPixel;
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
  count := 1;

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


{ BoxBlurThread execute procedure }
procedure BoxBlurThread.Execute();
var
  i, j, inH, inW: Integer;

begin

  inH := length(inBmp);
  inW := length(inBmp[high(inBmp)]);
  writeln('exec ' + inttostr(BlurredBitmap[0,0].getBlueInt));
  
  { Loop through pixels in bitmap }
  for i := 0 to inH - 1 do
  begin
      for j := 0 to inW - 1 do
      begin

          { Apply blur to pixels in output bitmap }
          BlurredBitmap[i, j] := ApplyBoxBlur(i, j, inBmp);
      end;
  end;
  
end;

{ Get result function }
function BoxBlurThread.GetResult(): bmpArray;
begin
  writeln('get ' + inttostr(BlurredBitmap[0,0].getBlueInt));
  
  { Return blurred bitmap }
  result := BlurredBitmap;
end;

{ Apply a Box Blur to a bitmap }
function BitmapBoxBlur.use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray;
var
  x, y, e, inH, inW: Integer;
  BlurredBitmap: arrayOfBmpArray;
  Threads: array of BoxBlurThread;
  NumCores: Integer;
  testArray: bmpArray;

begin
  
  { Get number of cores }
//  NumCores := TThread.ProcessorCount;

  { Create Array of threads }
  SetLength(Threads, length(inBmp));
  SetLength(BlurredBitmap, length(inBmp));
  BlurredBitmap := inBmp;
   
  { Create threads and start them }
  for e := 0 to high(Threads) do
  begin
    Threads[e] := BoxBlurThread.Create(inBmp[e]);
    Threads[e].Start;
  end;

  { Wait for all threads to finish, and gather their results }
  for e := 0 to high(Threads) do
  begin
    Threads[e].WaitFor;
    writeln('Thread ', e, ' finished');
    writeln('test ' + inttostr(Threads[e].GetResult[0,0].getRedInt));
//    setLength(testArray, length(Threads[e]), length(Threads[e].GetResult[0]));
{testArray := Threads[e];
    writeln('test ' + inttostr(testArray[0,0].getRedInt));}
    BlurredBitmap[e] := Threads[e].GetResult;
//    writeln(inttostr(BlurredBitmap[e][0][0].getRedInt));
  end;
  
  result := BlurredBitmap;
end;



{ Rotate a bitmap }
function BitmapRotate.use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray;
var
x, y, i, j, xx, yy, inH, inW: integer;
cx, cy, sina, cosa, angle: real;
e, h, w2, h2, outW, outH: integer;
outBmp: bmpArray;
facade: BmpArrayFacade;
begin
  
  facade := BmpArrayFacade.Create(inBmp);
  
  { Assign angle to input argument }
  angle := inputVariableReal;
  inH := facade.getInH;
  inW := facade.getInW;

  for i := 0 to high(inBmp) do
  begin
    inH := inH + length(inBmp[i]);
  end;

  { Find dimensions of bitmap }
  inW := length(inBmp[0][high(inBmp[0])]);
  cx := inW /2;
  cy := inH / 2;

  { Calculate new image size }
  sina := sin(angle);
  cosa := cos(angle);
  w2 := Round(inW * Abs(cosa) + inH * Abs(sina));
  h2 := Round(inW * Abs(sina) + inH * Abs(cosa));
  outW := w2;
  outH := h2;
  for e := 0 to inH - 1 do
  begin

    { Allocate memory for output bitmap }
    SetLength(outBmp, outH, outW);
  end;

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
        outBmp[i][j].setBlue(facade.getBlueByte(xx, yy));
        outBmp[i][j].setGreen(facade.getGreenByte(xx, yy));
        outBmp[i][j].setRed(facade.getRedByte(xx, yy));
      end;
    end;
  end;

  result[0] := outBmp;
end;

{ Scale a bitmap }
function BitmapScale.use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray;
var
  scale: real;
  inW, inH, outW, outH, e: integer;
  outBmp: arrayOfBmpArray;

begin

  { Assign scale to the value of input argument }
  scale := inputVariableReal;

  for e := 0 to high(inBmp) do
  begin

    { Find bitmaps dimensions }
    inH := length(inBmp[e]);
    inW := length(inBmp[e][high(inBmp[e])]);

    { Calculate scaled bitmaps dimensions }
    outW := Round(inW * scale);
    outH := Round(inH * scale);

    { Test if scale is higher or lower than 1 then execute upscale or downscale functions }
    if scale <= 1 then
      outBmp[e] := DownScaleBitmap(inBmp[e], inW, inH, outW, outH, scale)
    else
      outBmp[e] := UpscaleBitmap(inBmp[e], inW, inH, outW, outH, scale);
  end;

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

  { Calculate the difference in the x axis }
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
function BitmapSharpen.use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray;
const

  { Kernel for applying sharpen on bitmap }
  Kernel: array[-1..1, -1..1] of Integer = (
    (0, -1, 0),
    (-1, 5, -1),
    (0, -1, 0)
  );
var
  i, j, k, l, e: Integer;
  sumR, sumG, sumB, inH, inW: Integer;

begin
 
  for e := 0 to high(inBmp) do
  begin

    { Find Bitmaps dimensions }
    inH := length(inBmp[e]);
    inW := length(inBmp[high(inBmp[e])]);

    { Allocate memory for out bitmap }
    //setLength(outBmp, inH, inW);
    //outBmp := inBmp;
    { Loop through pixels in bitmap }
    for i := 1 to inH-2 do
    begin
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
            sumR := sumB + inBmp[e][i+k][j+l].getBlueInt * Kernel[k][l];
            sumG := sumG + inBmp[e][i+k][j+l].getGreenInt * Kernel[k][l];
            sumB := sumR + inBmp[e][i+k][j+l].getRedInt * Kernel[k][l];
          end;
        end;

        { Ensure pixel's red green and blue channels are within range }
        inBmp[e][i][j].setBlue(EnsureRange(sumB div 1, 0, 255));
        inBmp[e][i][j].setGreen(EnsureRange(sumG div 1, 0, 255));
        inBmp[e][i][j].setRed(EnsureRange(SumR div 1, 0, 255));
      end;
    end;
  end;

  result := inBmp;
end;

// this function needs the colourtables matched to colour bit ratios,
{ Quantize a bitmap to a set number of colours }
function BitmapQuantize.use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray;

var
  i, j, e, inW, inH, NumColours: integer;
  ColourTable: TColourTable;
  NearestColour: TPixel;
  bmp: bmpArray;
  outBmp: arrayOfBmpArray;

begin

  { Assign NumColours to the value of input argument }
  NumColours := inputVariableInt;

  { Set ColourTable }
  for i := 1 to NumColours do
  begin
    ColourTable[i-1] := TPixel.Create();
    ColourTable[i-1].setBlue(trunc(256 / i)); // random(256));
    ColourTable[i-1].setGreen(trunc(256 / (NumColours - i + 1))); // random(256));
    ColourTable[i-1].setRed(trunc(256 / i)); // random(256));
  end;

  for e := 0 to high(inBmp) do
  begin

    { Find dimensions of bitmap }
    inH := length(inBmp[e]);
    inW := length(inBmp[e][high(inBmp[e])]);

    { Allocate Memory for output bitmap }
    setLength(Bmp, inH, inW);

    { Loop through pixels in bitmap }
    for i := 0 to inH -1 do
    begin
      for j := 0 to inW -1 do
      begin

        { Find nearest colour in colour table to pixel then write to output bitmap }
        NearestColour := FindNearestColour(inBmp[e][i][j], ColourTable, NumColours);
        bmp[i][j] := NearestColour;
      end;
    end;

    outBmp[e] := bmp;
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
function BitmapDither.use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray;


var
  OldPixel, NewPixel, Error: TPixel;
  bmp: bmpArray;
  outBmp: arrayOfBmpArray;
  x, y, e, inH, inW: integer;
begin

  for e := 0 to high(inBmp) do
  begin

    { Find bitmap dimensions }
    inH := length(inBmp[e]);
    inW := length(inBmp[e][high(inBmp[e])]);

    { Allocate memory to output bitmap }
    setLength(Bmp, inH, inW);

    NewPixel := TPixel.Create();
    Error := TPixel.Create();
    { Loop over pixels in bitmap }
    for y := 0 to inH - 1 do
    begin
      for x := 0 to inW - 1 do
      begin

        { Set old pixel to equal current iteration of bitmap }
        OldPixel := inBmp[e][y][x];

        { Set new pixel }
        NewPixel.setBlue(Round((OldPixel.getBlueInt / 256) * 256));
        NewPixel.setGreen(Round((OldPixel.getGreenInt / 256) * 256));
        NewPixel.setRed(Round((OldPixel.getRedInt / 256) * 256));

        { Calculate error between old and new pixel }
        Error.setBlue(OldPixel.getBlueInt - NewPixel.getBlueInt);
        Error.setGreen(OldPixel.getGreenInt - NewPixel.getGreenInt);
        Error.setRed(OldPixel.getRedInt - NewPixel.getRedInt);

        { Write new pixel to output bitmap }
        Bmp[y][x] := TPixel.Create();
        Bmp[y][x].setBlue(NewPixel.getBlueByte);
        Bmp[y][x].setGreen(NewPixel.getGreenByte);
        Bmp[y][x].setRed(NewPixel.getGreenByte);

        { Calculate dither from error generated }
        if x < inW - 1 then
        begin
          inBmp[e][y, x + 1].setBlue(inBmp[e][y, x + 1].getBlueInt + Error.getBlueInt * 7 div 16);
          inBmp[e][y, x + 1].setGreen(inBmp[e][y, x + 1].getGreenInt + Error.getGreenInt * 7 div 16);
          inBmp[e][y, x + 1].setRed(inBmp[e][y, x + 1].getRedInt + Error.getRedInt * 7 div 16);
        end;
        if (x > 0) and (y < inH - 1) then
        begin
          inBmp[e][y + 1, x - 1].setBlue(inBmp[e][y + 1, x - 1].getBlueInt + Error.getBlueInt * 3 div 16);
          inBmp[e][y + 1, x - 1].setGreen(inBmp[e][y + 1, x - 1].getGreenInt + Error.getGreenInt * 3 div 16);
          inBmp[e][y + 1, x - 1].setRed(inBmp[e][y + 1, x - 1].getRedInt + Error.getRedInt * 3 div 16);
        end;
        if y < inH - 1 then
        begin
          inBmp[e][y + 1, x].setBlue(inBmp[e][y + 1, x].getBlueInt + Error.getBlueInt * 5 div 16);
          inBmp[e][y + 1, x].setGreen(inBmp[e][y + 1, x].getGreenInt + Error.getGreenInt * 5 div 16);
          inBmp[e][y + 1, x].setRed(inBmp[e][y + 1, x].getRedInt + Error.getRedInt * 5 div 16);
        end;
        if (x < inW - 1) and (y < inH - 1) then
        begin
          inBmp[e][y + 1, x + 1].setBlue(inBmp[e][y + 1, x + 1].getBlueInt + Error.getBlueInt div 16);
          inBmp[e][y + 1, x + 1].setGreen(inBmp[e][y + 1, x + 1].getGreenInt + Error.getGreenInt div 16);
          inBmp[e][y + 1, x + 1].setRed(inBmp[e][y + 1, x + 1].getRedInt + Error.getRedInt div 16);
        end;
      end;
    end;
    outBmp[e] := bmp;
  NewPixel.Free;
  Error.Free;
  end;
  
  result := outBmp;
end;

{ Detect edges in bitmap based on colour gradient difference using a threshold }
function BitmapEdgeDetect.use(inputVariableInt: integer; inputVariableReal: real; inBmp: arrayOfBmpArray): arrayOfBmpArray;
var
  Threshold: TPixel;
  inH, inW, e: integer;
  Bmp: bmpArray;
  outBmp: arrayOfBmpArray; 

begin

 { Create and Assign values for Threshold R, G and B to input argument }
  Threshold := TPixel.Create();
  Threshold.setBlue(inputVariableInt);
  Threshold.setGreen(inputVariableInt);
  Threshold.setRed(inputVariableInt);

  for e := 0 to high(inBmp) do
  begin
 
  { Find image dimensions }
  inH := length(inBmp[e]);
  inW := length(inBmp[e][high(inBmp[e])]);

  { Calculate edge detection }
  Bmp := detect(inBmp[e], Threshold, inH, inW);
  Threshold.Free;

  outBmp[e] := bmp;
  end;

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

  { Set test bias to true unless failed }
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

  { Set test bias to true unless failed }
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

  { Set test bias to true unless failed }
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

  { Set test bias to true unless failed }
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

  { Set test bias to true unless failed }
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

  { Set test bias to true unless failed }
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

  { Set test bias to true unless failed }
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

  { Set test bias to true unless failed }
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

  { Set test bias to true unless failed }
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

  { Set test bias to true unless failed }
  return := true;

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

  { Set test bias to true unless failed }
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

  { Set test bias to true unless failed }
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

  { Set test bias to true unless failed }
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

  { Set test bias to true unless failed }
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
  PixArray: arrayOfBmpArray;
  arg, input, output: string;
  outBmp: arrayOfBmpArray;

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

