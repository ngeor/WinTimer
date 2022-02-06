unit WinTimerCtl;

{$MODE Delphi}

interface

uses Windows, Messages, Grafix;

const
  WinTimerControlClassName = 'WinTimerCtl';
  propImage = 'Image';
  ID_Timer = 1;
  WTN_Timer = WM_User + 1;
  DigitWidth = 28;
  DigitHeight = 50;
  WinTimerHeight = DigitHeight + 5;


procedure GetWinTimerControlClass(var WndClass: TWndClass);
procedure RegisterWinTimerControl;
function WinTimerControlProc(Wnd: HWnd; Msg: UINT; wp: WPARAM;
  lp: LPARAM): LRESULT; stdcall;
procedure GetTimerText(Wnd: HWND; Buf: PChar);
function CreateWinTimerCtl(AParent: HWND; AnID, ALeft, ATop: integer): HWND;
function WinTimerWidth: integer;
function DigitCount: integer;

implementation

uses Math;

const
  ResName = 'DIGDISP';

function DigitCount: integer;
var
  hours: integer;
  hourDigits: integer;
begin
  hours := GetTickCount div (1000 * 3600);
  hourDigits := Max(2, Round(log10(hours)));
  Result := 6 + hourDigits;
end;

function WinTimerWidth: integer;
begin
  Result := DigitCount * DigitWidth + 5;
end;

function CreateWinTimerCtl(AParent: HWND; AnID, ALeft, ATop: integer): HWND;
begin
  Result := CreateWindowEx(WS_EX_STATICEDGE, WinTimerControlClassName,
    '', WS_CHILD or WS_VISIBLE, ALeft, ATop, WinTimerWidth, WinTimerHeight,
    AParent, AnID, HInstance, nil);
end;

procedure GetTimerText(Wnd: HWND; Buf: PChar);
begin
  GetWindowText(Wnd, Buf, DigitCount + 1);
end;

procedure WinTimerControl_Timer(Wnd: HWND); forward;

procedure WinTimerControl_Create(Wnd: HWND);
var
  Pic: HBitmap;
begin
  Pic := LoadBitmap(HInstance, ResName);
  SetProp(Wnd, propImage, Pic);
  WinTimerControl_Timer(Wnd);
  SetTimer(Wnd, ID_Timer, 1000, nil);
end;

procedure WinTimerControl_Paint(Wnd: HWND);
var
  PS: TPaintStruct;
  Buf: ansistring;
  b: integer;
  Pic: HBitmap;

begin
  b := DigitCount;
  BeginPaint(Wnd, PS);
  SetLength(Buf, b);
  GetTimerText(Wnd, PChar(Buf));
  Pic := GetProp(Wnd, propImage);

  while b > 0 do
  begin
    DrawPartOfBitmap(PS.hDC, Pic, (Ord(Buf[b]) - 48) * 28, 0, 28, 50,
      (b - 1) * 28 + 2, 2, 0, 0, False);
    b := b - 1;
  end;

  EndPaint(Wnd, PS);
end;

function IntToMyStr(Num: integer): string;
begin
  Str(Num, Result);
  if Num < 10 then
    Result := '0' + Result;
end;

procedure WinTimerControl_Timer(Wnd: HWND);
var
  TimeElapsed: longint;
  Hour, Min, Sec: integer;
  Buf: array [0..8] of char;
begin
  TimeElapsed := GetTickCount div 1000;
  Hour := TimeElapsed div 3600;
  TimeElapsed := TimeElapsed - Hour * 3600;
  Min := TimeElapsed div 60;
  TimeElapsed := TimeElapsed - Min * 60;
  Sec := TimeElapsed;
  LStrCpy(Buf, PChar(IntToMyStr(Hour) + ':' + IntToMyStr(Min) + ':' + IntToMyStr(Sec)));
  SetWindowText(Wnd, Buf);
  InvalidateRect(Wnd, nil, False);
  SendMessage(GetParent(Wnd), WTN_Timer, 0, longint(@Buf));
end;

procedure WinTimerControl_Destroy(Wnd: HWND);
begin
  DeleteObject(GetProp(Wnd, propImage));
  RemoveProp(Wnd, propImage);
  KillTimer(Wnd, ID_Timer);
end;

function WinTimerControlProc(Wnd: HWnd; Msg: UINT; wp: WPARAM; lp: LPARAM): LRESULT;
begin
  Result := 0;
  case Msg of
    WM_Create: WinTimerControl_Create(Wnd);
    WM_Paint: WinTimerControl_Paint(Wnd);
    WM_Timer: WinTimerControl_Timer(Wnd);
    WM_NCDestroy: WinTimerControl_Destroy(Wnd);
    WM_GetDlgCode: Result := DLGC_STATIC;
    else
      Result := DefWindowProc(Wnd, Msg, wp, lp);
  end;
end;

procedure GetWinTimerControlClass(var WndClass: TWndClass);
begin
  with WndClass do
  begin
    style := 0;
    lpfnWndProc := @WinTimerControlProc;
    cbClsExtra := 0;
    cbWndExtra := 0;
    hInstance := System.MainInstance;
    hIcon := 0;
    hCursor := LoadCursor(0, IDC_Arrow);
    hbrBackground := GetStockObject(BLACK_BRUSH);
    lpszMenuName := nil;
    lpszClassName := WinTimerControlClassName;
  end;
end;

procedure RegisterWinTimerControl;
var
  WinTimerControlClass: TWndClass;
begin
  if not GetClassInfo(HInstance, WinTimerControlClassName, WinTimerControlClass) then
  begin
    GetWinTimerControlClass(WinTimerControlClass);
    if RegisterClass(WinTimerControlClass) = 0 then
      Halt(255);
  end;
end;

initialization
  RegisterWinTimerControl;
end.
