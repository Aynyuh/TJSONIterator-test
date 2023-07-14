unit Forms.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, JSON.Readers, JSON.Utils, System.TypInfo, System.JSON.Types,
  System.JSON.Builders, System.Generics.Collections, System.Rtti, System.Generics.Defaults, System.Diagnostics;

type
  TTGMessage = class
  public
    id: Integer;
    &type: string;
    from: string;
    from_id: string;
  end;

  TUsersDict = TDictionary<Int64, string>;
  TMessagesStat = TDictionary<Int64, Integer>;

  TUserStat = class
  private
    FName: string;
    FCount: Integer;
  public
    constructor Create(const AName: string; ACount: Integer);
    property Name: string read FName;
    property Count: Integer read FCount;
  end;

  TFormMain = class(TForm)
    btnOpenFile: TButton;
    Memo1: TMemo;
    btnCount: TButton;
    OpenDialog1: TOpenDialog;

    procedure btnOpenFileClick(Sender: TObject);
    procedure btnCountClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    procedure ReadAllMessages(const AIter: TJSONIterator);
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;
  sr1: TStreamReader;
  jr1: TJsonTextReader;
  ji1: TJSONIterator;

  g_names: TUsersDict;
  g_messages: TMessagesStat;

  /// <summary>Format number using user's regional settings.</summary>
function FormatNumber(ANumber: Integer; TrimDecimal: Boolean = True): string; overload;
/// <summary>Format number using user's regional settings.</summary>
function FormatNumber(const ANumberStr: string): string; overload;

implementation

{$R *.dfm}

function FormatNumber(ANumber: Integer; TrimDecimal: Boolean = True): string;
var
  decimalPos: Integer;
begin
  Result := FormatNumber(IntToStr(ANumber));

  if TrimDecimal then
  begin
    decimalPos := Result.LastIndexOf(FormatSettings.DecimalSeparator);

    if decimalPos > -1 then
      Result := Result.Substring(0, decimalPos);
  end;
end;

function FormatNumber(const ANumberStr: string): string;
var
  sLen: Integer;
begin
  sLen := GetNumberFormatEx(PChar(LOCALE_NAME_USER_DEFAULT), 0, PChar(ANumberStr), nil, nil, 0);
  SetLength(Result, Pred(sLen));

  if sLen > 1 then
    GetNumberFormatEx(PChar(LOCALE_NAME_USER_DEFAULT), 0, PChar(ANumberStr), nil, PChar(Result), sLen);
end;

function ParseTGMessage(AIter: TJSONIterator): TTGMessage;
var
  m: TTGMessage;
begin
  m := TTGMessage.Create;

  while AIter.Next() do
  begin
    if ji1.Key = 'id' then
      m.id := ji1.AsInteger;

    if ji1.Key = 'type' then
      m.&type := ji1.AsString;

    // 'from' is null for deleted accounts
    if ji1.Key = 'from' then
    begin
      if ji1.AsValue.IsEmpty then
        m.from := '(Deleted Account)'
      else
        m.from := ji1.AsString;
    end;

    if ji1.Key = 'from_id' then
      m.from_id := ji1.AsString;
  end;

  Result := m;
end;

procedure CountTGUser(const m: TTGMessage; var AMessages: TMessagesStat; var ANames: TUsersDict);

  function getUserId(const m: TTGMessage): Int64;
  begin
    Result := -1;

    if Length(m.from_id) > 4 then
    begin
      if m.from_id.StartsWith('user') then
        Result := StrToInt64(m.from_id.Substring(4))
      else
        if m.from_id.StartsWith('channel') then
        Exit
      else
        raise EArgumentOutOfRangeException.Create('Can''t parse user id "' + m.from_id + '".');
    end
    else
      raise EArgumentOutOfRangeException.Create('Incorrect length of id "' + m.from_id + '".');
  end;

begin
  if m.&type = 'message' then
  begin
    var id := getUserId(m);

    if id = -1 then
      Exit;

    if AMessages.ContainsKey(id) then
      AMessages[id] := AMessages[id] + 1
    else
    begin
      AMessages.Add(id, 1);

      if not ANames.ContainsKey(id) then
        ANames.Add(id, m.from);
    end;
  end;
end;

procedure TFormMain.btnOpenFileClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    sr1.Free;
    jr1.Free;
    ji1.Free;
    g_names.Free;
    g_messages.Free;

    sr1 := TStreamReader.Create(OpenDialog1.FileName);
    jr1 := TJsonTextReader.Create(sr1);
    ji1 := TJSONIterator.Create(jr1);

    g_names := TUsersDict.Create;
    g_messages := TMessagesStat.Create;
  end;
end;

procedure TFormMain.btnCountClick(Sender: TObject);
const
  NameColWidth = 40;
  CountColWidth = 10;
var
  strFormat: string;
  sw: TStopwatch;
  log: TStrings;
  list: TObjectList<TUserStat>;
begin
  log := Memo1.Lines;
  strFormat := '%-' + NameColWidth.ToString + 's%' + CountColWidth.ToString + 's';

  ji1.Rewind;
  g_messages.Clear;
  g_names.Clear;

  if ji1.Next('name') then
  begin
    log.Add(string('-').PadLeft(NameColWidth + CountColWidth, '-'));
    log.Add('Group name: ' + ji1.AsString);
  end
  else
    Exit;

  if sr1.BaseStream is TFileStream then
    log.Add('File: ' + TFileStream(sr1.BaseStream).FileName);
  log.Add('Size: ' + FormatNumber(sr1.BaseStream.Size div 1024) + ' KB');

  // read messages in json array
  sw := TStopwatch.StartNew;
  if ji1.Next('messages') then
    if ji1.&Type = TJsonToken.StartArray then
      ReadAllMessages(ji1);
  sw.Stop;

  // combine user name and messages count, sort descending by messages count
  list := TObjectList<TUserStat>.Create(True);
  for var m in g_messages do
    list.Add(TUserStat.Create(g_names[m.Key], g_messages[m.Key]));

  list.Sort(TComparer<TUserStat>.Construct(
    function(const Left, Right: TUserStat): Integer
    begin
      Result := Right.Count - Left.Count;
    end));

  // print total count
  var total: Integer := 0;
  for var m in list do
    Inc(total, m.Count);

  log.BeginUpdate;

  log.Add('Total messages: ' + FormatNumber(total));
  log.Add('Parsing time: ' + FormatNumber(sw.ElapsedMilliseconds) + ' ms');
  log.Add('');

  // print table header
  log.Add(Format(strFormat, ['User', 'Messages']));
  log.Add(string('-').PadLeft(NameColWidth + CountColWidth, '-'));

  // user name and count (split every 10 records by empty line)
  for var i := 0 to Pred(list.Count) do
  begin
    log.Add(Format(strFormat, [list[i].Name, FormatNumber(list[i].Count)]));

    if ((i + 1) mod 10) = 0 then
      log.Add('');
  end;

  list.Free;

  log.Add('');
  log.Add(string('-').PadLeft(NameColWidth + CountColWidth, '-'));

  log.EndUpdate;
end;

procedure TFormMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  sr1.Free;
  jr1.Free;
  ji1.Free;
  g_names.Free;
  g_messages.Free;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Memo1.Clear;
end;

procedure TFormMain.ReadAllMessages(const AIter: TJSONIterator);
var
  tgMsg: TTGMessage;
begin
  // go inside messages array
  AIter.Recurse;

  // iterate over all messages
  while AIter.Next do
  begin

    if AIter.&Type = TJsonToken.StartObject then
    begin
      AIter.Recurse;

      tgMsg := ParseTGMessage(AIter);
      CountTGUser(tgMsg, g_messages, g_names);

      tgMsg.Free;

      AIter.Return;
    end;
  end;

  AIter.Return;
end;

{ TUserStat }

constructor TUserStat.Create(const AName: string; ACount: Integer);
begin
  FName := AName;
  FCount := ACount;
end;

end.
