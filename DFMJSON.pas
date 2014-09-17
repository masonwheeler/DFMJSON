unit DFMJSON;

interface
uses
   System.Classes,
   dwsJson;

function Dfm2JSON(dfm: TStream): TdwsJSONObject; overload;
function Dfm2JSON(const filename: string): TdwsJSONObject; overload;
function DfmBin2JSON(dfm: TStream): TdwsJSONObject; overload;
function DfmBin2JSON(const filename: string): TdwsJSONObject; overload;

procedure SaveJSON2Dfm(json: TdwsJSONObject; const filename: string);
function JSON2Dfm(json: TdwsJSONObject): string;

implementation
uses
  System.SysUtils,
  System.StrUtils,
  System.RTLConsts,
  System.IOUtils,
  Vcl.Clipbrd;

function ConvertOrderModifier(parser: TParser): Integer;
begin
  Result := -1;
  if Parser.Token = '[' then
  begin
    Parser.NextToken;
    Parser.CheckToken(toInteger);
    Result := Parser.TokenInt;
    Parser.NextToken;
    Parser.CheckToken(']');
    Parser.NextToken;
  end;
end;

function ConvertHeader(parser: TParser; IsInherited, IsInline: Boolean): TdwsJSONObject;
var
  ClassName, ObjectName: string;
  Flags: TFilerFlags;
  Position: Integer;
begin
  Parser.CheckToken(toSymbol);
  ClassName := Parser.TokenString;
  ObjectName := '';
  if Parser.NextToken = ':' then
  begin
    Parser.NextToken;
    Parser.CheckToken(toSymbol);
    ObjectName := ClassName;
    ClassName := Parser.TokenString;
    Parser.NextToken;
  end;
  Flags := [];
  Position := ConvertOrderModifier(parser);
  result := TdwsJSONObject.Create;
  try
    if IsInherited then
      result.AddValue('$Inherited', true);
    if IsInline then
      result.AddValue('$Inline', true);
    if Position >= 0 then
      result.AddValue('$ChildPos', Position);
    result.AddValue('$Class', ClassName);
    if ObjectName <> '' then
      result.AddValue('$Name', ObjectName);
  except
    result.Free;
    raise;
  end;
end;

procedure ConvertProperty(parser: TParser; obj: TdwsJSONObject); forward;

function ConvertValue(parser: TParser): TdwsJSONValue;
var
  Order: Integer;
  arr: TdwsJSONArray;
  sub: TdwsJSONObject;
  TokenStr: string;

  function CombineString: String;
  begin
    Result := Parser.TokenWideString;
    while Parser.NextToken = '+' do
    begin
      Parser.NextToken;
      if not CharInSet(Parser.Token, [System.Classes.toString, toWString]) then
        Parser.CheckToken(System.Classes.toString);
      Result := Result + Parser.TokenWideString;
    end;
  end;

begin
  if CharInSet(Parser.Token, [System.Classes.toString, toWString]) then
  begin
    result := TdwsJSONImmediate.Create;
    result.AsString := QuotedStr(CombineString)
  end
  else
  begin
    case Parser.Token of
      toSymbol:
      begin
        tokenStr := Parser.TokenComponentIdent;
        result := TdwsJSONImmediate.Create;
        if tokenStr = 'True' then
          result.AsBoolean := true
        else if tokenStr = 'False' then
          result.AsBoolean := false
        else result.AsString := Parser.TokenComponentIdent;
      end;
      toInteger:
      begin
        result := TdwsJSONImmediate.Create;
        result.AsInteger := Parser.TokenInt
      end;
      toFloat:
      begin
        result := TdwsJSONObject.Create;
        if parser.FloatType = #0 then
           TdwsJSONObject(result).Add('$float', TdwsJSONImmediate.Create) //null
        else TdwsJSONObject(result).AddValue('$float', Parser.FloatType);
        TdwsJSONObject(result).AddValue('value', Parser.TokenFloat);
      end;
      '[':
      begin
        result := TdwsJSONObject.Create;
        TdwsJSONObject(result).AddValue('$set', true);
        arr := TdwsJSONObject(result).AddArray('value');
        Parser.NextToken;

        if Parser.Token <> ']' then
          while True do
          begin
            TokenStr := Parser.TokenString;
            case Parser.Token of
              toInteger: begin end;
              System.Classes.toString,toWString: TokenStr := '#' + IntToStr(Ord(TokenStr.Chars[0]));
            else
              Parser.CheckToken(toSymbol);
            end;
            arr.Add(TokenStr);
            if Parser.NextToken = ']' then Break;
            Parser.CheckToken(',');
            Parser.NextToken;
          end;
      end;
      '(':
      begin
        Parser.NextToken;
        result := TdwsJSONArray.Create;
        while Parser.Token <> ')' do
           TdwsJSONArray(result).add(ConvertValue(parser));
      end;
      '{':
      begin
        Parser.NextToken;
        result := TdwsJSONObject.Create;
        TdwsJSONObject(result).AddValue('$hex', true);
        tokenStr := '';
        while Parser.Token <> '}' do
        begin
           tokenStr := tokenStr + parser.TokenString;
           parser.NextToken;
        end;
        TdwsJSONObject(result).AddValue('value', tokenStr);
      end;
      '<':
      begin
        Parser.NextToken;
        result := TdwsJSONObject.Create;
        TdwsJSONObject(result).AddValue('$collection', true);
        arr := TdwsJSONObject(result).AddArray('values');
        while Parser.Token <> '>' do
        begin
          Parser.CheckTokenSymbol('item');
          Parser.NextToken;
          Order := ConvertOrderModifier(parser);
          sub := arr.AddObject;
          if Order <> -1 then
             sub.AddValue('$order', order);
          while not Parser.TokenSymbolIs('end') do
             ConvertProperty(parser, sub);
          Parser.NextToken;
        end;
      end;
      else begin
        Parser.Error(SInvalidProperty);
        result :=  nil;
      end;
    end;
    Parser.NextToken;
  end;
end;

procedure ConvertProperty(parser: TParser; obj: TdwsJSONObject);
var
  PropName: string;
begin
  Parser.CheckToken(toSymbol);
  PropName := Parser.TokenString;
  Parser.NextToken;
  while Parser.Token = '.' do
  begin
    Parser.NextToken;
    Parser.CheckToken(toSymbol);
    PropName := PropName + '.' + Parser.TokenString;
    Parser.NextToken;
  end;
  Parser.CheckToken('=');
  Parser.NextToken;
  obj.Add(propName, ConvertValue(parser));
end;

function ConvertObject(parser: TParser): TdwsJSONObject;
var
  InheritedObject: Boolean;
  InlineObject: Boolean;
  children: TdwsJSONArray;
begin
  InheritedObject := False;
  InlineObject := False;
  if Parser.TokenSymbolIs('INHERITED') then
    InheritedObject := True
  else if Parser.TokenSymbolIs('INLINE') then
    InlineObject := True
  else
    Parser.CheckTokenSymbol('OBJECT');
  Parser.NextToken;
  result := ConvertHeader(parser, InheritedObject, InlineObject);
  while not Parser.TokenSymbolIs('END') and
    not Parser.TokenSymbolIs('OBJECT') and
    not Parser.TokenSymbolIs('INHERITED') and
    not Parser.TokenSymbolIs('INLINE') do
    ConvertProperty(parser, result);
  children := result.AddArray('$Children');
  while not Parser.TokenSymbolIs('END') do
     children.Add(ConvertObject(parser));
  Parser.NextToken;
end;

function Dfm2JSON(dfm: TStream): TdwsJSONObject;
var
  parser: TParser;
begin
  parser := TParser.Create(dfm);
  try
    result := ConvertObject(parser);
  finally
    parser.Free;
  end;
end;

function Dfm2JSON(const filename: string): TdwsJSONObject;
var
  stream: TStringStream;
begin
  stream := TStringStream.Create(TFile.ReadAllText(filename), TEncoding.UTF8);
  try
    result := Dfm2JSON(stream);
  finally
    stream.Free;
  end;
end;

function DfmBin2JSON(dfm: TStream): TdwsJSONObject;
var
   outStream: TStringStream;
begin
  outStream := TStringStream.Create();
  try
    System.Classes.ObjectBinaryToText(dfm, outStream);
    result := Dfm2JSON(outStream);
  finally
    outStream.Free;
  end;
end;

function DfmBin2JSON(const filename: string): TdwsJSONObject;
var
  stream: TFileStream;
begin
  stream := TFile.OpenRead(filename);
  try
    result := DfmBin2JSON(stream);
  finally
    stream.Free;
  end;
end;

procedure SaveJSON2Dfm(json: TdwsJSONObject; const filename: string);
begin
  TFile.WriteAllText(filename, JSON2DFM(json));
end;

//------------------------------------------------------------------------------

function IndentStr(depth: integer): string;
begin
  result := StringOfChar(' ', depth * 2);
end;

procedure WriteJSONObject(json: TdwsJSONObject; sl: TStringList; indent: integer); forward;
procedure WriteJSONProperty(const name: string; value: TdwsJSONValue; sl: TStringList; indent: integer); forward;

function capitalize(value: string): string;
begin
  value[1] := UpCase(value[1]);
  result := value;
end;

procedure WriteJSONArrProperty(const name: string; value: TdwsJSONArray; sl: TStringList; indent: integer);

  function GetString(value: TdwsJSONValue): string;
  begin
    case value.ValueType of
       jvtString, jvtNumber: result := value.AsString;
       jvtBoolean: result := capitalize(value.AsString);
       else assert(false);
    end;
  end;

var
  i: integer;
  line: string;
begin
  sl.Add(IndentStr(indent) + format('%s = (', [name]));
  for i := 0 to value.ElementCount - 1 do
  begin

    line := IndentStr(indent + 1) + GetString(value.Elements[i]);
    if i = value.ElementCount - 1 then
    line := line + ')';
    sl.Add(line);
  end;
end;

procedure WriteFloatProperty(const name: string; value: TdwsJSONObject; sl: TStringList; indent: integer);
var
  float, fValue: TdwsJSONValue;
  num: single;
  numVal: string;
begin
  float := value.Items['$float'];
  fValue := value.Items['value'];
  num := fValue.AsNumber;
  if (frac(num) = 0.0) and (num.ToString.IndexOfAny(['e', 'E']) = -1) then
    numVal := num.ToString + '.000000000000000000'
  else numval := num.ToString;
  if float.ValueType = jvtUndefined then
    sl.Add(IndentStr(indent) + format('%s = %s', [name, numVal]))
  else sl.Add(IndentStr(indent) + format('%s = %s', [name, numVal + float.AsString]));
end;

procedure WriteSetProperty(const name: string; value: TdwsJSONObject; sl: TStringList; indent: integer);
var
  i: integer;
  line: string;
  sub: TdwsJSONArray;
begin
  line := '';
  sub := value.Items['value'] as TdwsJSONArray;
  for i := 0 to sub.ElementCount - 1 do
  begin
    if line = '' then
      line := sub.Elements[i].AsString
    else line := format('%s, %s', [line, sub.Elements[i].AsString]);
  end;
  sl.Add(IndentStr(indent) + format('%s = [%s]', [name, line]));
end;

procedure WriteHexProperty(const name: string; value: TdwsJSONObject; sl: TStringList; indent: integer);
var
  hex, line: string;
begin
  sl.Add(IndentStr(indent) + format('%s = {', [name]));
  hex := value.Items['value'].AsString;
  while hex <> '' do
  begin
    line := Copy(hex, 0, 64);
    delete(hex, 1, 64);
    if hex = '' then
      line := line + '}';
    sl.Add(IndentStr(indent + 1) + line);
  end;
end;

procedure WriteCollectionItem(value: TdwsJSONObject; sl: TStringList; indent: integer);
var
  i: integer;
begin
  if value.Items['$order'].IsDefined then
    sl.Add(IndentStr(indent) + format('item [%d]', [value.Items['$order'].AsInteger]))
  else sl.Add(IndentStr(indent) + 'item');
  for i := 0 to value.ElementCount - 1 do
    if not value.Names[i].StartsWith('$') then
      WriteJSONProperty(value.Names[i], value.Elements[i], sl, indent + 1);
  sl.Add(IndentStr(indent) + 'end');
end;

procedure WriteCollection(const name: string; value: TdwsJSONObject; sl: TStringList; indent: integer);
var
  values: TdwsJSONArray;
  sub: TdwsJSONValue;
begin
  sl.Add(IndentStr(indent) + format('%s = <', [name]));
  values := value.Items['values'] as TdwsJSONArray;
  for sub in values do
    WriteCollectionItem(sub as TdwsJSONObject, sl, indent + 1);
  sl[sl.Count - 1] := sl[sl.Count - 1] + '>';
end;

procedure WriteJSONObjProperty(const name: string; value: TdwsJSONObject; sl: TStringList; indent: integer);
begin
  if assigned(value.Items['$float']) then
    WriteFloatProperty(name, value, sl, indent)
  else if assigned(value.Items['$set']) then
    WriteSetProperty(name, value, sl, indent)
  else if assigned(value.Items['$hex']) then
    WriteHexProperty(name, value, sl, indent)
  else if assigned(value.Items['$collection']) then
    WriteCollection(name, value, sl, indent)
  else
    asm int 3 end;
end;

function StringNeedsWork(const str: string): boolean;
begin
  result := (str.Length > 66) or (str.IndexOfAny([#13, #10]) > -1);
end;

function DfmQuotedStr(const value: string): string;
const separators: array[0..2] of string = (#13#10, #13, #10);
var
  lines: TArray<string>;
  i: integer;
begin
  lines := value.Split(separators, None);
  for i := 0 to high(lines) do
    if lines[i] <> '' then
      lines[i] := QuotedStr(lines[i]);
  result := String.join('#13', lines);
end;

procedure WriteStringProperty(const name: string; value: TdwsJSONValue; sl: TStringList; indent: integer);
var
  str, sub: string;
begin
  str := value.AsString;;
  if str.StartsWith('''') and StringNeedsWork(str) then //66 = 64 limit + 2 quotes
  begin
    str := AnsiDequotedStr(str, '''');
    sl.Add(IndentStr(indent) + format('%s = ', [name]));
    while str.Length > 0 do
    begin
      sub := DfmQuotedStr(Copy(str, 0, 64));
      delete(str, 1, 64);
      if str <> '' then
        sub := sub + ' +';
      sl.Add(IndentStr(indent + 1) + sub);
    end;
  end
  else sl.Add(IndentStr(indent) + format('%s = %s', [name, str]));
end;

procedure WriteJSONProperty(const name: string; value: TdwsJSONValue; sl: TStringList; indent: integer);
begin
  case value.ValueType of
     jvtUndefined, jvtNull: assert(false);
     jvtObject: WriteJSONObjProperty(name, value as TdwsJSONObject, sl, indent);
     jvtArray: WriteJSONArrProperty(name, value as TdwsJSONArray, sl, indent);
     jvtString: WritestringProperty(name, value, sl, indent);
     jvtNumber: sl.Add(IndentStr(indent) + format('%s = %s', [name, value.AsString]));
     jvtBoolean: sl.Add(IndentStr(indent) + format('%s = %s', [name, capitalize(value.AsString)]));
  end;
end;

procedure WriteJSONProperties(json: TdwsJSONObject; sl: TStringList; indent: integer);
var
  i: integer;
  name: string;
  children, child: TdwsJSONValue;
begin
  for i := 0 to json.ElementCount - 1 do
  begin
    name := json.Names[i];
    if not name.StartsWith('$') then
      WriteJSONProperty(name, json.Elements[i], sl, indent);
  end;

  children := json.Items['$Children'];
  if children.IsDefined then
    for child in children do
      WriteJSONObject(child as TdwsJSONObject, sl, indent);
end;

procedure WriteJSONObject(json: TdwsJSONObject; sl: TStringList; indent: integer);
var
  dfmType, name, cls, header: string;
begin
  if json.Items['$Inherited'].IsDefined then
    dfmType := 'inherited'
  else if json.Items['$Inline'].IsDefined then
    dfmType := 'inline'
  else dfmType := 'object';
  if json.Items['$Name'].IsDefined then
     name := json.Items['$Name'].AsString
  else name := '';
  cls := json.Items['$Class'].AsString;
  if name = '' then
    header := format('%s %s', [dfmType, cls])
  else header := format('%s %s: %s', [dfmType, name, cls]);
  if json.Items['$ChildPos'].IsDefined then
    header := format('%s [%d]', [header, json.Items['$ChildPos'].AsInteger]);
  sl.Add(indentStr(indent) + header);
  WriteJSONProperties(json, sl, indent + 1);
  sl.add(indentStr(indent) + 'end');
end;

function JSON2Dfm(json: TdwsJSONObject): string;
var
  sl: TStringList;
begin
  sl := TStringList.Create();
  try
    WriteJSONObject(json, sl, 0);
    result := sl.Text;
  finally
    sl.free;
  end;
end;

end.
