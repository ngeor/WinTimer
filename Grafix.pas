Unit Grafix;

{$MODE Delphi}

interface

Uses Windows;

const
  clWhite: LongInt = $00FFFFFF;
  clGray: LongInt = $00808080;
  clLtGray: LongInt = $00C0C0C0;

procedure Line(DC: HDC; left, top, right, bottom: Integer; Color: LongInt);

procedure DrawBitmap(DC: HDC; Pic: HBitMap; x,y,w,h: Integer; Stretch:Boolean);
procedure DrawPartOfBitmap(DC: HDC; Pic: HBitMap; x1,y1,w1,h1,x2,y2,w2,h2: Integer; Stretch:Boolean);

procedure RaisedRect(DC: HDC; Var R: TRect);
procedure SunkRect(DC: HDC; Var R: TRect);

procedure CarreEffect(DC: HDC; hPic: HBITMAP; BlockX, BlockY: Integer);
procedure CarreEffectThread(DC: HDC; hPic: HBITMAP; BlockX, BlockY: Integer);
procedure WallpaperFill(DC: HDC; hPic: HBITMAP; Width, Height: Integer);

function BitmapSize(hPic: HBITMAP): TSize;
function BitmapWidth(hPic: HBITMAP): Integer;
function BitmapHeight(hPic: HBITMAP): Integer;

implementation

procedure Line(DC: HDC; left, top, right, bottom: Integer; Color: LongInt);
var
  MyPen, OldPen: HPen;
  p: PPoint;
begin
  MyPen:=CreatePen(PS_Solid,1,Color);
  OldPen:=SelectObject(DC,MyPen);
  New(p);
  MoveToEx(DC,left,top,p);
  LineTo(DC,right,bottom);
  SelectObject(DC,OldPen);
  DeleteObject(MyPen);
  Dispose(p);
end;

function BitmapSize(hPic: HBITMAP): TSize;
var
  bm: TBitmap;
begin
  GetObject(hPic, SizeOf(bm), @bm);
  Result.cx:=bm.bmWidth;
  Result.cy:=bm.bmHeight;
end;

function BitmapWidth(hPic: HBITMAP): Integer;
var
  bm: TBitmap;
begin
  GetObject(hPic, SizeOf(bm), @bm);
  Result:=bm.bmWidth;
end;

function BitmapHeight(hPic: HBITMAP): Integer;
var
  bm: TBitmap;
begin
  GetObject(hPic, SizeOf(bm), @bm);
  Result:=bm.bmHeight;
end;

procedure DrawPartOfBitmap(DC: HDC; Pic: HBitMap; x1,y1,w1,h1,x2,y2,w2,h2: Integer; Stretch:Boolean);
var
  MemDC: HDC;
  oldPic: HBitmap;
begin
  MemDC:= CreateCompatibleDC(DC);
  oldPic:=SelectObject(MemDC, Pic);
  if Stretch then
    StretchBlt(DC,x2,y2,w2,h2,MemDC,x1,y1,w1,h1,SRCCOPY)
  else
    BitBlt(DC,x2,y2, w1, h1 ,MemDC,x1,y1,SRCCOPY);
  SelectObject(MemDC, oldPic);
  DeleteDC(MemDC);
end;

procedure DrawBitmap(DC: HDC; Pic: HBitMap; x,y,w,h: Integer; Stretch:Boolean);
var
  S: TSize;
begin
  S:=BitmapSize(Pic);
  DrawPartOfBitmap(DC, Pic, 0, 0, S.cx, S.cy, x, y, w, h, Stretch);
end;

procedure RaisedRect(DC: HDC; Var R: TRect);
begin
  Line(DC, R.Left, R.Top, R.Right, R.Top, clWhite);
  Line(DC, R.Left, R.Top, R.Left, R.Bottom, clWhite);
  Line(DC, R.Right-1, R.Top, R.Right-1, R.Bottom, 0);
  Line(DC, R.Left, R.Bottom-1, R.Right, R.Bottom-1, 0);
  InflateRect(R, -1, -1);
  Line(DC, R.Left, R.Top, R.Right, R.Top, clLtGray);
  Line(DC, R.Left, R.Top, R.Left, R.Bottom, clLtGray);
  Line(DC, R.Right-1, R.Top, R.Right-1, R.Bottom, clGray);
  Line(DC, R.Left, R.Bottom-1, R.Right, R.Bottom-1, clGray);
end;

procedure SunkRect(DC: HDC; Var R: TRect);
begin
  Line(DC, R.Left, R.Top, R.Right, R.Top, 0);
  Line(DC, R.Left, R.Top, R.Left, R.Bottom, 0);
  Line(DC, R.Right-1, R.Top, R.Right-1, R.Bottom, clWhite);
  Line(DC, R.Left, R.Bottom-1, R.Right, R.Bottom-1, clWhite);
  InflateRect(R, -1, -1);
  Line(DC, R.Left, R.Top, R.Right, R.Top, clGray);
  Line(DC, R.Left, R.Top, R.Left, R.Bottom, clGray);
  Line(DC, R.Right-1, R.Top, R.Right-1, R.Bottom, clLtGray);
  Line(DC, R.Left, R.Bottom-1, R.Right, R.Bottom-1, clLtGray);
end;


type
  PCarreEffectParam = ^TCarreEffectParam;
  TCarreEffectParam = Record
    DC: HDC;
    hPic: HBITMAP;
    BlockX: Integer;
    BlockY: Integer;
  end;

function CarreEffectFun(c: PCarreEffectParam): LongInt; stdcall;
var
  x, y, BlocksFilled: Integer;
  w, h: Double;
  Blocks: array of array of Boolean;
  bm: TBitmap;
begin
  GetObject(c^.hPic, SizeOf(bm), @bm);
  SetLength(Blocks, c^.BlockX, c^.BlockY);
  for y:=0 to c^.BlockY-1 do
  for x:=0 to c^.BlockX-1 do
  Blocks[x, y]:=False;
  w:=bm.bmWidth/c^.BlockX;
  h:=bm.bmHeight/c^.BlockY;
  BlocksFilled:=0;

  Repeat
    y:=Random(c^.BlockY);
    x:=Random(c^.BlockX);
    If Not Blocks[x, y] Then Begin
      DrawPartOfBitmap(c^.DC, c^.hPic,
                       Round(x*w), Round(y*h), Round(w), Round(h),
                       Round(x*w), Round(y*h), 0, 0, False);
      Blocks[x, y]:=True;
      Inc(BlocksFilled);
    End;
  Until BlocksFilled=c^.BlockX*c^.BlockY;
  Result:=0;
  Dispose(c);
end;

procedure CarreEffect(DC: HDC; hPic: HBITMAP; BlockX, BlockY: Integer);
var
  param: PCarreEffectParam;
begin
  New(param);
  param^.DC:=DC;
  param^.hPic:=hPic;
  param^.BlockX:=BlockX;
  param^.BlockY:=BlockY;
  CarreEffectFun(param);
end;

procedure CarreEffectThread(DC: HDC; hPic: HBITMAP; BlockX, BlockY: Integer);
var
  ThreadID: DWORD;
  param: PCarreEffectParam;
begin
  New(param);
  param^.DC:=DC;
  param^.hPic:=hPic;
  param^.BlockX:=BlockX;
  param^.BlockY:=BlockY;
  CreateThread(nil, 0, @CarreEffectFun, param, 0, ThreadID);
end;

procedure WallpaperFill(DC: HDC; hPic: HBITMAP; Width, Height: Integer);
var
  S: TSize;
  x, y: Integer;
begin
  S:=BitmapSize(hPic);
  x:=0;
  y:=0;
  repeat
    repeat
      DrawBitmap(DC, hPic, x, y, 0, 0, False);
      x:=x + S.cx;
    until x>=Width;
    x:=0;
    y:=y + S.cy;
  until y>=Height;
end;

procedure SlideImage(DC: HDC; hPic: HBITMAP; x1, y1, x2, y2: Integer);
begin
end;

end.
