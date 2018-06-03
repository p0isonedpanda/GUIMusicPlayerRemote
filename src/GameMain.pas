program GameMain;
uses SwinGame, sgTypes, math, strutils, sysutils;

type
    UIButton = record
        rectLocX, rectLocY : Integer;
        rectWidth, rectHeight : Integer;
        rectColor, outlineColor : Color;
        labelText : String;
    end;
    
    MusicGenre = (ProgMetal, Remix, Rock, Electropop);

    Album = record
        name, artist : String;
        genre : MusicGenre;
        trackCount : Integer;
        tracks : Array of String;
    end;

    ProgressBar = record
        bX, bY : Integer;
        bW, bH : Integer;
        bColor : Color;
        fColor : Color;
        progress : Double; // Track what percentage we need to fill on the bar, ranges from 0 to 1
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
end;

function ClampDouble(value, min, max : Double) : Double;
begin
    if value < min then result := min
    else if value > max then result := max
    else result := value;
end;

function ReadInAlbum(longeBoi : String) : Album;
var
    count, i : Integer;
begin
    // First we count how many elements we need to read in by counting the delimited character "|"
    // Code from Stack Overflow question "Count how often a character appears in a string"
    count := 0;
    for i := 1 to Length(longeBoi) do
    begin
        if longeBoi[i] = '|' then count += 1;
    end;
    count += 1; // Just to account for the last element
    
    // Now we start assigning values to the album record
    result.name := ExtractDelimited(1, longeBoi, ['|']);
    result.artist := ExtractDelimited(2, longeBoi, ['|']);
    case ExtractDelimited(3, longeBoi, ['|']) of
        'ProgMetal' : result.genre := ProgMetal;
        'Remix' : result.genre := Remix;
        'Rock' : result.genre := Rock;
        'Electropop' : result.genre := Electropop;
    end;
    result.trackCount := StrToInt(ExtractDelimited(4, longeBoi, ['|']));
    // Time for some ARRAY GOODNESS WITH YA BOI
    SetLength(result.tracks, result.trackCount);
    i := 5;
    while i <= count do
    begin
        result.tracks[i - 5] := ExtractDelimited(i, longeBoi, ['|']);
        i += 1;
    end;
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

function CreateProgressBar(_bX, _bY, _bW, _bH : Integer; _bColor, _fColor : Color) : ProgressBar;
begin
    result.bX := _bX;
    result.bY := _bY;
    result.bW := _bW;
    result.bH := _bH;
    result.bColor := _bColor;
    result.fColor := _fColor;
    result.progress := 0.0;
end;

// This will allow us to add a modifier to the progress bar
procedure ModifyProgress(var _pb : ProgressBar; modifier : Double);
begin
    _pb.progress := ClampDouble(_pb.progress + modifier, 0.0, 1.0);
end;

// This will allow us to set the progress of a progress bar
procedure SetProgress(var _pb : Progressbar; value : Double);
begin
    _pb.progress := ClampDouble(value, 0.0, 1.0);
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

procedure LoadAssets(var connectButton, pauseButton, nextButton, previousButton : UIButton; var volumeBar : ProgressBar);
begin
    // Create our UI buttons
    connectButton := CreateUIButton(10, 10, 80, 30, ColorGrey, ColorBlack, 'Connect!');
    pauseButton := CreateUIButton(10, 50, 80, 30, ColorGrey, ColorBlack, 'Pause');
    nextButton := CreateUIButton(10, 90, 80, 30, ColorGrey, ColorBlack, 'Next');
    previousButton := CreateUIButton(10, 130, 80, 30, ColorGrey, ColorBlack, 'Previous');

    // Create our volume bar
    volumeBar := CreateProgressBar(10, 470, 780, 20, ColorRed, ColorGreen);
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

procedure DrawProgressBar(_pg : ProgressBar);
begin
    // First we draw the background
    FillRectangle(_pg.bColor, _pg.bX, _pg.bY, _pg.bW, _pg.bH);
    // Then we need to draw the foreground on that
    FillRectangle(_pg.fColor, _pg.bX, _pg.bY, Round(_pg.bW * _pg.progress), _pg.bH);
    // Then we can draw an outline for it
    DrawRectangle(ColorBlack, _pg.bX, _pg.bY, _pg.bW, _pg.bH);
end;

procedure DrawAlbumInfo(alb : Album);
var
    i, textY: Integer;
    temp : String;
begin
    DrawText('Name: ' + alb.name, ColorBlack, 100, 10);
    DrawText('Artist: ' + alb.artist, ColorBlack, 100, 25);
    case alb.genre of
        ProgMetal : temp := 'Prog Metal';
        Remix : temp := 'Remix';
        Rock : temp := 'Rock';
        Electropop : temp := 'Electropop';
    end;
    DrawText('Genre: ' + temp, ColorBlack, 100, 40);
    DrawText('Track count: ' + IntToStr(alb.trackCount), ColorBlack, 100, 55);
    i := 0;
    textY := 55;
    while i < alb.trackCount do
    begin
        textY += 15;
        DrawText('Track ' + IntToStr(i + 1) + ': ' + alb.tracks[i], ColorBlack, 100, textY);
        i += 1;
    end;
end;

procedure DrawMenu(connectButton, pauseButton, nextButton, previousButton : UIButton; volumeBar : ProgressBar;  var userAlbum : Album);
begin
    ButtonHoverVisual(connectButton);
    DrawUIButton(connectButton);

    // We only want to display these buttons if we have established a connection
    if CONN <> nil then
    begin
        if TCPMessageReceived() then userAlbum := ReadInAlbum(ReadMessage(CONN));
        DrawAlbumInfo(userAlbum);

        ButtonHoverVisual(pauseButton);
        DrawUIButton(pauseButton);

        ButtonHoverVisual(nextButton);
        DrawUIButton(nextButton);

        ButtonHoverVisual(previousButton);
        DrawUIButton(previousButton);
        
        DrawProgressbar(volumeBar);
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
    volumeBar : ProgressBar;
    userAlbum : Album;
begin
    OpenGraphicsWindow('using TCP networked remotes to control music is my passion.', 800, 600);
  
    LoadAssets(connectButton, pauseButton, nextButton, previousButton, volumeBar);

    repeat // The game loop...
        ProcessEvents();
    
        ClearScreen(ColorWhite);

        MenuInput(connectButton, pauseButton, nextButton, previousButton);
        DrawMenu(connectButton, pauseButton, nextButton, previousButton, volumeBar, userAlbum);

        RefreshScreen(60);
    until WindowCloseRequested();
end;

begin
    Main();
end.
