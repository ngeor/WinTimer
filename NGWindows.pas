unit NGWindows;

{$MODE Delphi}

interface

uses Windows, Messages;

function MsgBox(Wnd: HWND; Text, Title: String; Flags: Integer): Integer;
procedure ErrorDlg(Wnd: HWND; Text: String);
procedure InfoDlg(Wnd: HWND; Text: String);

function FocusTo(Wnd: HWND; idCtl: Integer): Longint;

function GetWndText(Wnd: HWND): String;
function GetChildText(Wnd: HWND; idCtl: Integer): String;
function SimpleDlgProc(Wnd: HWND; Msg: UINT; wp: WPARAM; lp: LPARAM): BOOL; stdcall;

implementation

resourcestring
  ErrorMsg = 'Error';
  InfoMsg = 'Information';

function MsgBox(Wnd: HWND; Text, Title: String; Flags: Integer): Integer;
begin
  Result := MessageBox(Wnd, PChar(Text), PChar(Title), Flags);
end;

procedure ErrorDlg(Wnd: HWND; Text: String);
begin
  MsgBox(Wnd, Text, ErrorMsg, MB_ICONERROR);
end;

procedure InfoDlg(Wnd: HWND; Text: String);
begin
  MsgBox(Wnd, Text, InfoMsg, MB_ICONINFORMATION);
end;

function FocusTo(Wnd: HWND; idCtl: Integer): Longint;
begin
  Result := SendMessage(Wnd, WM_NEXTDLGCTL, GetDlgItem(Wnd, idCtl), 1);
end;

function GetWndText(Wnd: HWND): String;
var
  Len: Integer;
  Buf: PChar;
begin
  Len := GetWindowTextLength(Wnd) + 1;
  GetMem(Buf, Len);
  GetWindowText(Wnd, Buf, Len);
  Result := Buf;
  FreeMem(Buf);
end;

function GetChildText(Wnd: HWND; idCtl: Integer): String;
begin
  Result := GetWndText(GetDlgItem(Wnd, idCtl));
end;

function SimpleDlgProc(Wnd: HWND; Msg: UINT; wp: WPARAM; lp: LPARAM): BOOL; stdcall;
begin
  Result := Msg = WM_INITDIALOG;
  case Msg of
    WM_CLOSE: EndDialog(Wnd, 0);
    WM_COMMAND:
      case LOWORD(wp) of
        idOk: EndDialog(Wnd, 1);
        idCancel: EndDialog(Wnd, 0);
      end;
  end;
end;

end.
