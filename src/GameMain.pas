program GameMain;
uses SwinGame, sgTypes, math;

type
    UIButton = record
        rectLocX, rectLocY : Integer;
        rectWidth, rectHeight : Integer;
        rectColor, outlineColor : Color;
        labelText : String;
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

procedure LoadAssets(var connectButton : UIButton);
begin
    // Create our UI buttons
    connectButton := CreateUIButton(10, 10, 80, 30, ColorGrey, ColorBlack, 'Connect!');
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

procedure DrawMenu(connectButton : UIButton);
begin
    ButtonHoverVisual(connectButton);

    DrawUIButton(connectButton);
end;

procedure MenuInput(connectButton : UIButton);
begin
    if ButtonClicked(connectButton) then WriteLn('Click!');
end;

procedure Main();
var
    connectButton : UIButton;
begin
    OpenGraphicsWindow('using TCP networked remotes to control music is my passion.', 800, 600);
  
    LoadAssets(connectButton);

    repeat // The game loop...
        ProcessEvents();
    
        ClearScreen(ColorWhite);

        MenuInput(connectButton);
        DrawMenu(connectButton);

        RefreshScreen(60);
    until WindowCloseRequested();
end;

begin
    Main();
end.
