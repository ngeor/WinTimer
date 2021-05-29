unit NGWindows;

{$MODE Delphi}

interface

uses Windows, Messages;

function MsgBox(Wnd: HWND; Text, Title: string; Flags: Integer): Integer;
procedure ErrorDlg(Wnd: HWND; Text: string);
procedure InfoDlg(Wnd: HWND; Text: string);

function FocusTo(Wnd: HWND; idCtl: Integer): LongInt;

function GetWndText(Wnd: HWND): string;
function GetChildText(Wnd: HWND; idCtl: Integer): string;
function SimpleDlgProc(Wnd: HWND; Msg: UINT; wp: WPARAM; lp: LPARAM): BOOL; stdcall;

implementation

resourcestring
  ErrorMsg = 'Error';
  InfoMsg  = 'Information';

function MsgBox(Wnd: HWND; Text, Title: string; Flags: Integer): Integer;
begin
  Result:=MessageBox(Wnd, PChar(Text), PChar(Title), Flags);
end;

procedure ErrorDlg(Wnd: HWND; Text: string);
begin
  MsgBox(Wnd, Text, ErrorMsg, MB_ICONERROR);
end;

procedure InfoDlg(Wnd: HWND; Text: string);
begin
  MsgBox(Wnd, Text, InfoMsg, MB_ICONINFORMATION);
end;

function FocusTo(Wnd: HWND; idCtl: Integer): LongInt;
begin
  Result:=SendMessage(Wnd, WM_NEXTDLGCTL, GetDlgItem(Wnd, idCtl), 1);
end;

function GetWndText(Wnd: HWND): string;
var
  Len: Integer;
  Buf: PChar;
begin
  Len:=GetWindowTextLength(Wnd) + 1;
  GetMem(Buf, Len);
  GetWindowText(Wnd, Buf, Len);
  Result:=Buf;
  FreeMem(Buf);
end;

function GetChildText(Wnd: HWND; idCtl: Integer): string;
begin
  Result:=GetWndText(GetDlgItem(Wnd, idCtl));
end;

function SimpleDlgProc(Wnd: HWND; Msg: UINT; wp: WPARAM; lp: LPARAM): BOOL; stdcall;
begin
  Result:= Msg = WM_INITDIALOG;
  case Msg of
    WM_CLOSE: EndDialog(Wnd, 0);
    WM_COMMAND:
      case LOWORD(wp) of
        IDOK: EndDialog(Wnd, 1);
        IDCANCEL: EndDialog(Wnd, 0);
      end;
  end;
end;

end.
