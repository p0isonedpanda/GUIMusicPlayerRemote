program GameMain;
uses SwinGame, sgTypes, math;

type
    UIButton = record
        rectLocX, rectLocY : Integer;
        rectWidth, rectHeight : Integer;
        rectColor, outlineColor : Color;
        labelText : String;
    end;

// It's best if we define these as constants since we may need to access these
// throughout the program for connection to the host
const
    CONN : Connection = nil;
    PORT : Integer = 4000;
    HOSTIP : String = '127.0.0.1'; // When testing locally

// Completely lock up the ENTIRE program to connect to the host, cause multithreaded
// applications are hard to make in pascal (thanks objfpc for not working)
procedure EstablishConnection();
begin
    while CONN = nil do
    begin
        CONN := CreateTCPConnection(HOSTIP, PORT);
    end;
    if CONN = nil then WriteLn('Whoops');
end;

function CreateUIButton (_x, _y, _w, _h : Integer; _rColor, _oColor : Color; _lbl : String) : UIButton;
begin
    result.rectLocX := _x;
    result.rectLocY := _y;
    result.rectWidth := _w;
    result.rectHeight := _h;
    result.rectColor := _rColor;
    result.outlineColor := _oColor;
    result.labelText := _lbl;
end;

function CheckButtonIsHovered(_btn : UIButton) : Boolean;
begin
    result := PointInRect
    (
        MouseX(), MouseY(),
        _btn.rectLocX, _btn.rectLocY,
        _btn.rectWidth, _btn.rectHeight
    );
end;

procedure ButtonHoverVisual(var _btn : UIButton);
begin
    if (CheckButtonIsHovered(_btn)) and (MouseDown(LeftButton)) then _btn.outlineColor := ColorPurple
    else if CheckButtonIsHovered(_btn) then _btn.outlineColor := ColorLightGrey
    else _btn.outlineColor := ColorBlack;
end;

function ButtonClicked(_btn : UIButton) : Boolean;
begin
    result := (CheckButtonIsHovered(_btn)) and (MouseClicked(LeftButton));
end;

procedure LoadAssets(var connectButton, pauseButton, nextButton, previousButton : UIButton);
begin
    // Create our UI buttons
    connectButton := CreateUIButton(10, 10, 80, 30, ColorGrey, ColorBlack, 'Connect!');
    pauseButton := CreateUIButton(10, 50, 80, 30, ColorGrey, ColorBlack, 'Pause');
    nextButton := CreateUIButton(10, 90, 80, 30, ColorGrey, ColorBlack, 'Next');
    previousButton := CreateUIButton(10, 130, 80, 30, ColorGrey, ColorBlack, 'Previous');
end;

procedure DrawUIButton(_btn : UIButton);
var
    textX, textY : Integer;
begin
    FillRectangle(_btn.outlineColor, _btn.rectLocX - 5, _btn.rectLocY - 1, _btn.rectWidth + 6, _btn.rectHeight + 2);
    FillRectangle(_btn.rectColor, _btn.rectLocX, _btn.rectLocY, _btn.rectWidth, _btn.rectHeight);
    textX := _btn.rectLocX + 5;
    textY := Floor((_btn.rectLocY + (_btn.rectLocY + _btn.rectHeight)) / 2);
    DrawText(_btn.labelText, _btn.outlineColor, textX, textY);
end;

procedure DrawMenu(connectButton, pauseButton, nextButton, previousButton : UIButton);
begin
    ButtonHoverVisual(connectButton);
    DrawUIButton(connectButton);

    // We only want to display these buttons if we have established a connection
    if CONN <> nil then
    begin
        ButtonHoverVisual(pauseButton);
        DrawUIButton(pauseButton);

        ButtonHoverVisual(nextButton);
        DrawUIButton(nextButton);

        ButtonHoverVisual(previousButton);
        DrawUIButton(previousButton);
    end;
end;

procedure MenuInput(var connectButton, pauseButton, nextButton, previousButton : UIButton);
begin
    if ButtonClicked(connectButton) then EstablishConnection();

    // We only want to check the input for these buttons if we have established a connection
    if CONN <> nil then
    begin
        if ButtonClicked(pauseButton) then
        begin
            SendTCPMessage('PAUSE', CONN);
            if pauseButton.labelText = 'Pause' then pauseButton.labelText := 'Play'
            else pauseButton.labelText := 'Pause';
        end;

        if ButtonClicked(nextButton) then SendTCPMessage('NEXTTRACK', CONN);
        if ButtonClicked(previousButton) then SendTCPMessage('PREVIOUSTRACK', CONN);
    end;
end;

procedure Main();
var
    connectButton, pauseButton, nextButton, previousButton : UIButton;
begin
    OpenGraphicsWindow('using TCP networked remotes to control music is my passion.', 800, 600);
  
    LoadAssets(connectButton, pauseButton, nextButton, previousButton);

    repeat // The game loop...
        ProcessEvents();
    
        ClearScreen(ColorWhite);

        MenuInput(connectButton, pauseButton, nextButton, previousButton);
        DrawMenu(connectButton, pauseButton, nextButton, previousButton);

        RefreshScreen(60);
    until WindowCloseRequested();
end;

begin
    Main();
end.
