unit SQLCollection.Component;

interface

uses
  System.Classes,
  System.SysUtils;

type
  TSQLCategory   = class;
  TSQLCategories = class;
  TSQLScript     = class;
  TSQLScripts    = class;

  TSQLCollection = class(TComponent)
  private
    FItems : TSQLCategories;
    FSorted: Boolean;
    procedure SetItems(const Value: TSQLCategories);
    function GetSQLScriptsCount: Integer;
    procedure SortItems;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    class function IsValidName(AString: string): Boolean;

    property SQLScriptsCount: Integer read GetSQLScriptsCount;

    function AddSQLScript(ASQLScriptName, ASQLCategoryName: string): TSQLScript;
    function FindSQLScriptItem(ASQLScriptName, ASQLCategoryName: string): TSQLScript;
    function FindSQLScript(ASQLScriptName, ASQLCategoryName: string): string;
  published
    property Items: TSQLCategories read FItems write SetItems;
  end;

  TSQLCategories = class(TCollection)
  private
    FOwner: TSQLCollection;
    function GetSQLCategory(Index: Integer): TSQLCategory;
    function GetSQLCategoryByName(ASQLCategoryName: string): TSQLCategory;
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TSQLCollection);
    function Add(ASQLCategoryName: string): TSQLCategory;
    property SQLCategory[index: Integer]: TSQLCategory read GetSQLCategory;
    property SQLCategoryByName[ASQLCategoryName: string]: TSQLCategory read GetSQLCategoryByName; default;
  end;

  TSQLCategory = class(TCollectionItem)
  private
    FSQLScritps     : TSQLScripts;
    FSQLCategoryName: string;
    procedure SetSQLCategoryName(const Value: string);
    procedure SetSQLScripts(const Value: TSQLScripts);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
  published
    property SQLCategoryName: string read FSQLCategoryName write SetSQLCategoryName;
    property SQLScripts     : TSQLScripts read FSQLScritps write SetSQLScripts;
  end;

  TSQLScripts = class(TCollection)
  private
    FOwner: TSQLCategory;
    function GetSQLScript(Index: Integer): TSQLScript;
    function GetSQLScriptByName(ASQLScriptName: string): TSQLScript;
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TSQLCategory);
    function Add(ASQLCategoryName: string): TSQLScript; overload;
    procedure AddSQLScript(ASource: TSQLScript);
    property SQLScript[index: Integer]: TSQLScript read GetSQLScript;
    property SQLScriptByName[ASQLScriptName: string]: TSQLScript read GetSQLScriptByName; default;
  end;

  TSQLScript = class(TCollectionItem)
  private
    FSQLScriptName: string;
    FSQLScript    : TStrings;
    function GetCollection: TSQLCollection;
    procedure SetSQLScriptName(const Value: string);
    procedure AssignSQLScript(ASQLScript: TSQLScript);
    procedure SetSQLScript(const Value: TStrings);
    function GetSQLCategory: string;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    property SQLCollection: TSQLCollection read GetCollection;
  published
    property SQLCategory  : string read GetSQLCategory;
    property SQLScriptName: string read FSQLScriptName write SetSQLScriptName;
    property SQLScript    : TStrings read FSQLScript write SetSQLScript;
  end;

  TCollectionHelper = class helper for TCollection
  public
    procedure Sort;
    function BinarySearch(AKey: string): TCollectionItem;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('SQLCollection', [TSQLCollection]);
end;

{ TSQLScript }

procedure TSQLScript.Assign(Source: TPersistent);
begin
  if Source is TSQLScript then
    AssignSQLScript(TSQLScript(Source))
  else
    inherited Assign(Source);
end;

procedure TSQLScript.AssignSQLScript(ASQLScript: TSQLScript);
begin
  if ASQLScript <> nil then
  begin
    SQLScriptName := ASQLScript.SQLScriptName;
    SQLScript     := ASQLScript.SQLScript;
  end
end;

constructor TSQLScript.Create(Collection: TCollection);
begin
  inherited Create(Collection);

  FSQLScriptName  := '';
  FSQLScript      := TStringList.Create;
  FSQLScript.Text := '';
end;

destructor TSQLScript.Destroy;
begin
  FreeAndNil(FSQLScript);

  inherited Destroy;
end;

function TSQLScript.GetSQLCategory: string;
begin
  Result := (Self.Collection as TSQLScripts).FOwner.FSQLCategoryName;
end;

function TSQLScript.GetDisplayName: string;
begin
  Result := FSQLScriptName;
  if FSQLScriptName = '' then
    Result := inherited GetDisplayName;
end;

function TSQLScript.GetCollection: TSQLCollection;
begin
  Result := ((Self.Collection as TSQLScripts).FOwner.Collection as TSQLCategories).FOwner;
end;

procedure TSQLScript.SetSQLScriptName(const Value: string);
var
  I: Integer;
begin
  if not TSQLCollection.IsValidName(Value) then
    raise Exception.CreateFmt('A descrição "%s" do item contém dígitos inválidos.' +
      ' Remova acentuações e caracteres especiais e tente novamente.', [Value]);

  if (Value.Trim <> FSQLScriptName.Trim) and (Collection.Count > 0) then
    for I := 0 to Pred(Collection.Count) do
      if UpperCase(TSQLScript(Collection.Items[I]).SQLScriptName) = UpperCase(Trim(Value)) then
        raise Exception.CreateFmt('A descrição "%s" já consta na lista de SQLs. Por favor escolha outra descrição',
          [Value.Trim]);

  FSQLScriptName := Value.Trim;
end;

procedure TSQLScript.SetSQLScript(const Value: TStrings);
begin
  FSQLScript.Assign(Value);
end;

{ TSQLScripts }

function TSQLScripts.Add(ASQLCategoryName: string): TSQLScript;
begin
  Result := inherited Add as TSQLScript;

  if ASQLCategoryName.IsEmpty then
    ASQLCategoryName := Format('Script_%d', [Self.Count + 1]);

  Result.SQLScriptName  := ASQLCategoryName;
  Result.SQLScript.Text := '';

  Self.Sort;
end;

procedure TSQLScripts.AddSQLScript(ASource: TSQLScript);
var
  SQLScript: TSQLScript;
begin
  if ASource <> nil then
  begin
    SQLScript           := Add(ASource.SQLScriptName);
    SQLScript.SQLScript := ASource.SQLScript;
  end;
end;

constructor TSQLScripts.Create(AOwner: TSQLCategory);
begin
  inherited Create(TSQLScript);
  FOwner := AOwner;
end;

function TSQLScripts.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

function TSQLScripts.GetSQLScript(Index: Integer): TSQLScript;
begin
  Result := inherited Items[index] as TSQLScript;
end;

function TSQLScripts.GetSQLScriptByName(ASQLScriptName: string): TSQLScript;
begin
  Result := Self.BinarySearch(ASQLScriptName) as TSQLScript;
end;

{ TSQLCollection }

function TSQLCollection.AddSQLScript(ASQLScriptName, ASQLCategoryName: string): TSQLScript;
var
  SQLCategory: TSQLCategory;
begin
  SQLCategory := Items[ASQLCategoryName];
  if SQLCategory = nil then
    SQLCategory := Items.Add(ASQLCategoryName);

  Result := SQLCategory.SQLScripts[ASQLScriptName];

  if Result = nil then
    Result := SQLCategory.SQLScripts.Add(ASQLScriptName);
end;

constructor TSQLCollection.Create(AOwner: TComponent);
begin
  inherited;
  FItems  := TSQLCategories.Create(Self);
  FSorted := false;
end;

destructor TSQLCollection.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

function TSQLCollection.FindSQLScript(ASQLScriptName, ASQLCategoryName: string): string;
var
  SQLScript: TSQLScript;
begin
  Result    := '';
  SQLScript := Self.FindSQLScriptItem(ASQLScriptName, ASQLCategoryName);

  if SQLScript <> nil then
    Result := SQLScript.SQLScript.Text
  else
    raise Exception.CreateFmt('SQLItem Categoria: %s - Descrição: %s não encontrado',
      [ASQLCategoryName, ASQLScriptName]);
end;

function TSQLCollection.FindSQLScriptItem(ASQLScriptName, ASQLCategoryName: string): TSQLScript;
var
  LCategory: TSQLCategory;
begin
  if not FSorted then
  begin
    SortItems;
    FSorted := true;
  end;

  Result := nil;

  LCategory := Items[ASQLCategoryName];

  if LCategory <> nil then
    Result := LCategory.SQLScripts[ASQLScriptName];
end;

function TSQLCollection.GetSQLScriptsCount: Integer;
var
  I: Integer;
begin
  Result   := 0;
  for I    := 0 to Pred(Items.Count) do
    Result := Result + Items.SQLCategory[I].FSQLScritps.Count;
end;

class function TSQLCollection.IsValidName(AString: string): Boolean;
const
  ValidChars: TSysCharSet = ['A' .. 'Z', 'a' .. 'z', '0' .. '9', '_', '-', '.', ' '];
var
  I: Integer;
begin
  Result := true;
  for I  := low(AString) + 1 to high(AString) do
  begin
    if not CharInSet(AString[I], ValidChars) then
    begin
      Result := false;
      Break;
    end;
  end;
end;

procedure TSQLCollection.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
end;

procedure TSQLCollection.SetItems(const Value: TSQLCategories);
begin
  FItems.Assign(Value);
end;

procedure TSQLCollection.SortItems;
var
  I: Integer;
begin
  Self.Items.Sort;
  for I := 0 to Self.Items.Count - 1 do
    Self.Items.SQLCategory[I].SQLScripts.Sort;
end;

{ TSQLCategory }

constructor TSQLCategory.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FSQLScritps := TSQLScripts.Create(Self);
end;

destructor TSQLCategory.Destroy;
begin
  FreeAndNil(FSQLScritps);
  inherited;
end;

function TSQLCategory.GetDisplayName: string;
begin
  Result := FSQLCategoryName;
  if FSQLCategoryName = '' then
    Result := inherited GetDisplayName;
end;

procedure TSQLCategory.SetSQLCategoryName(const Value: string);
var
  I: Integer;
begin
  if not TSQLCollection.IsValidName(Value) then
    raise Exception.CreateFmt('O nome "%s" da categoria contém dígitos inválidos.' +
      ' Remova acentuações e caracteres especiais e tente novamente.', [Value]);

  if Collection.Count > 0 then
    for I := 0 to Pred(Collection.Count) do
      if UpperCase(TSQLCategory(Collection.Items[I]).SQLCategoryName) = UpperCase(Value) then
        raise Exception.Create('O nome escolhido já consta na lista de categorias. Por favor escolha outro nome');

  FSQLCategoryName := Value;

  SetDisplayName(FSQLCategoryName);
end;

procedure TSQLCategory.SetSQLScripts(const Value: TSQLScripts);
begin
  FSQLScritps.Assign(Value);
end;

{ TSQLCategories }

function TSQLCategories.Add(ASQLCategoryName: string): TSQLCategory;
begin
  Result := inherited Add as TSQLCategory;

  if ASQLCategoryName.IsEmpty then
    ASQLCategoryName := Format('Category_%d', [Self.Count + 1]);

  Result.SQLCategoryName := ASQLCategoryName;
  Result.FSQLScritps     := TSQLScripts.Create(Result);

  Self.Sort;
end;

constructor TSQLCategories.Create(AOwner: TSQLCollection);
begin
  inherited Create(TSQLCategory);
  FOwner := AOwner;
end;

function TSQLCategories.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

function TSQLCategories.GetSQLCategory(Index: Integer): TSQLCategory;
begin
  Result := inherited Items[index] as TSQLCategory;
end;

function TSQLCategories.GetSQLCategoryByName(ASQLCategoryName: string): TSQLCategory;
begin
  Result := Self.BinarySearch(ASQLCategoryName) as TSQLCategory;
end;

{ TCollectionHelper }

function TCollectionHelper.BinarySearch(AKey: string): TCollectionItem;
var
  LMin, LMax, LMed: Integer;
begin
  Result := nil;
  LMin   := 0;
  LMax   := Self.Count - 1;
  while LMin <= LMax do
  begin
    LMed := (LMin + LMax) div 2;
    if AnsiCompareText(AKey, Self.Items[LMed].DisplayName) = 0 then
    begin
      Result := Self.Items[LMed];
      Break;
    end
    else if AnsiCompareText(AKey, Self.Items[LMed].DisplayName) < 0 then
      LMax := LMed - 1
    else
      LMin := LMed + 1;
  end;
end;

procedure TCollectionHelper.Sort;
var
  I, LMax: Integer;
  LList  : TStringList;
begin
  LList := TStringList.Create;
  try
    for I := Self.Count - 1 downto 0 do
      LList.AddObject(Items[I].DisplayName, Pointer(Items[I].ID));
    LList.Sort;
    LMax  := LList.Count - 1;
    for I := 0 to LMax do
    begin
      Self.FindItemID(Integer(LList.Objects[I])).Index := I;
    end;
  finally
    FreeAndNil(LList);
  end;
end;

end.
