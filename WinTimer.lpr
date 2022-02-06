program WinTimer;

{$MODE Delphi}

uses
  Windows,
  Messages,
  ShellAPI,
  CommCtrl,
  WinTimerCtl,
  NGWindows in 'NGWindows.pas',
  ConfigureBox in 'ConfigureBox.pas',
  Grafix in 'Grafix.pas';

{$R WinTimer.res}

const
  MainWndClassName = 'WinTimerClass';
  WM_TRAYICON = WM_USER + 2;
  ID_FirstIcon = 1000;
  IDI_Main = '1';
  ID_ABOUT = 102;
  ID_CONFIGURE = 103;

  { Constants for the SetMenuDefaultItem function }
  SMDI_BYCOMMAND = 0;
  SMDI_BYPOS = 1;

var
  MainWnd: HWND = 0;

  function GetMyMenu: HMENU;
  begin
    Result := GetSystemMenu(MainWnd, False);
  end;

  procedure ResizeWindow(Wnd: HWND);
  var
    clientRect: TRect;
    windowRect: TRect;
  begin
    { Update my size }
    GetClientRect(Wnd, clientRect);
    GetWindowRect(Wnd, windowRect);
    SetWindowPos(Wnd, 0, 0, 0,
      WinTimerWidth + 16 + windowRect.Width - clientRect.Width,
      WinTimerHeight + 16 + windowRect.Height - clientRect.Height,
      SWP_NOMOVE or SWP_NOZORDER or SWP_NOREDRAW or SWP_NOACTIVATE);
  end;

  procedure MainWnd_Create(Wnd: HWND);
  var
    t: TNotifyIconData;
    SysMenu: HMENU;
    hIcon: HANDLE;
    hInst: HANDLE;
  begin
    { Make sure MainWnd is equal to Wnd }
    MainWnd := Wnd;

    { Create the taskbar icon }
    t.cbSize := SizeOf(t);
    t.hWnd := Wnd;
    t.uCallBackMessage := WM_TRAYICON;
    t.uID := ID_FirstIcon;
    t.uFlags := NIF_ICON or NIF_MESSAGE;
    hInst := HInstance;
    hIcon := LoadIcon(hInst, IDI_MAIN);
    t.hIcon := hIcon;
    Shell_NotifyIconA(NIM_ADD, @t);

    { Modify my system menu }
    SysMenu := GetMyMenu;
    DeleteMenu(SysMenu, SC_SIZE, MF_BYCOMMAND);
    InsertMenu(SysMenu, 0, MF_BYPOSITION or MF_STRING, SC_RESTORE, 'Restore');
    InsertMenu(SysMenu, 1, MF_BYPOSITION or MF_STRING, SC_MINIMIZE, 'Minimize');
    AppendMenu(SysMenu, MF_SEPARATOR, 0, nil);
    AppendMenu(SysMenu, 0, ID_ABOUT, 'About...');
    AppendMenu(SysMenu, 0, ID_CONFIGURE, 'Configure...');

    { Create the actual control }
    CreateWinTimerCtl(Wnd, -1, 8, 8);

    ResizeWindow(Wnd);
  end;

  procedure MainWnd_Restore;
  var
    w: HWND;
  begin
    ShowWindow(MainWnd, SW_RESTORE);
    w := GetLastActivePopup(MainWnd);
    if IsWindow(w) then
      SetForegroundWindow(w)
    else
      SetForegroundWindow(MainWnd);
  end;

  procedure MainWnd_Minimize;
  begin
    ShowWindow(MainWnd, SW_HIDE);
  end;

  procedure MainWnd_ToggleShow;
  begin
    if IsWindowVisible(MainWnd) then
      MainWnd_Minimize
    else
      MainWnd_Restore;
  end;

  procedure MainWnd_Destroy;
  var
    t: TNotifyIconData;
  begin
    t.cbSize := SizeOf(t);
    t.hWnd := MainWnd;
    t.uID := ID_FirstIcon;
    Shell_NotifyIconA(NIM_DELETE, @t);
    PostQuitMessage(0);
  end;

  procedure MainWnd_TrayIcon(Wnd: HWND; wp: WPARAM; lp: LPARAM);
  var
    P: TPoint;
  begin
    if wp = ID_FirstIcon then
      case lp of
        WM_LBUTTONUP:
          MainWnd_ToggleShow;
        WM_RBUTTONUP:
          if IsWindowEnabled(Wnd) then
          begin
            GetCursorPos(p);
            TrackPopupMenu(GetMyMenu, TPM_RIGHTBUTTON, p.x, p.y, 0, Wnd, nil);
            PostMessage(Wnd, 0, 0, 0);
          end
          else
            MainWnd_Restore;
      end;
  end;

  procedure MainWnd_UpdateTip(Wnd: HWND; lp: LPARAM);
  var
    t: TNotifyIconData;
  begin
    t.cbSize := SizeOf(t);
    t.hWnd := Wnd;
    t.uID := ID_FirstIcon;
    t.uFlags := NIF_TIP;
    LStrCpy(t.szTip, PChar(lp));
    Shell_NotifyIconA(NIM_MODIFY, @t);
  end;

  procedure MainWnd_InitMenu(AMenu: HMENU);
  begin
    if IsWindowVisible(MainWnd) then
    begin
      EnableMenuItem(AMenu, SC_RESTORE, MF_BYCOMMAND or MF_GRAYED);
      EnableMenuItem(AMenu, SC_MINIMIZE, MF_BYCOMMAND or MF_ENABLED);
      SetMenuDefaultItem(AMenu, SC_MINIMIZE, SMDI_ByCommand);
    end
    else
    begin
      EnableMenuItem(AMenu, SC_RESTORE, MF_BYCOMMAND or MF_ENABLED);
      EnableMenuItem(AMenu, SC_MINIMIZE, MF_BYCOMMAND or MF_GRAYED);
      EnableMenuItem(AMenu, SC_MOVE, MF_BYCOMMAND or MF_GRAYED);
      SetMenuDefaultItem(AMenu, SC_RESTORE, SMDI_ByCommand);
    end;
  end;

  function MainWndProc(Wnd: HWnd; Msg: UINT; wp: WPARAM; lp: LPARAM): longint; stdcall;
  begin
    Result := 0;
    case Msg of
      WM_CREATE: MainWnd_Create(Wnd);
      WM_DESTROY: MainWnd_Destroy;
      WM_TRAYICON: MainWnd_TrayIcon(Wnd, wp, lp);
      WM_INITMENU, WM_INITMENUPOPUP: MainWnd_InitMenu(LOWORD(wp));
      WM_SIZE:
        if wp = SIZE_MINIMIZED then
          MainWnd_Minimize;
      WM_COMMAND:
        case LOWORD(Wp) of
          SC_RESTORE: MainWnd_Restore;
          SC_MINIMIZE: MainWnd_Minimize;
          ID_ABOUT:
          begin
            SetForegroundWindow(Wnd);
            DialogBox(HInstance, PChar(ID_ABOUT), Wnd, @SimpleDlgProc);
          end;
          ID_CONFIGURE:
          begin
            SetForeGroundWindow(Wnd);
            DialogBox(HInstance, PChar(ID_CONFIGURE), Wnd, @SimpleDlgProc);
          end;
          SC_CLOSE: SendMessage(Wnd, WM_Close, 0, 0);
        end;
      WM_SYSCOMMAND:
        case wp of
          SC_RESTORE, SC_MINIMIZE, ID_ABOUT, ID_CONFIGURE, SC_CLOSE:
          begin
            Result := 1;
            SendMessage(Wnd, WM_COMMAND, wp, 0);
          end
          else
            Result := DefWindowProc(Wnd, Msg, wp, lp);
        end;
      WTN_TIMER: MainWnd_UpdateTip(Wnd, lp);
      else
        Result := DefWindowProc(Wnd, Msg, wp, lp);
    end;
  end;

  procedure GetMainWndClass(var WndClass: TWndClass);
  begin
    FillChar(WndClass, SizeOf(WndClass), #0);
    with WndClass do
    begin
      lpfnWndProc := @MainWndProc;
      hInstance := System.MainInstance;
      hIcon := LoadIcon(HInstance, IDI_MAIN);
      hCursor := LoadCursor(0, IDC_Arrow);
      hbrBackground := COLOR_BTNFACE + 1;
      lpszClassName := MainWndClassName;
    end;
  end;

  procedure RegisterMainWnd;
  var
    MainWndClass: TWndClass;
  begin
    if not GetClassInfo(HInstance, MainWndClassName, MainWndClass) then
    begin
      GetMainWndClass(MainWndClass);
      if RegisterClass(MainWndClass) = 0 then
        Halt(255);
    end;
  end;


  procedure MainLoop;
  var
    Msg: TMsg;
  begin
    while GetMessage(Msg, 0, 0, 0) do
    begin
      TranslateMessage(Msg);
      DispatchMessage(Msg);
    end;
  end;

begin
  RegisterMainWnd;
  MainWnd := FindWindow(MainWndClassName, nil);
  if not IsWindow(MainWnd) then
  begin
    InitCommonControls;
    MainWnd := CreateWindowEx(WS_EX_TOOLWINDOW, MainWndClassName,
      'WinTimer', WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT,
      CW_USEDEFAULT, CW_USEDEFAULT, 0, 0, HInstance, nil);
    MainLoop;
  end;
end.
