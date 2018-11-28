unit SQLCollection.Design.EditorsRegister;

interface

uses
  System.Classes,
  System.SysUtils,
  SQLCollection.Component,
  VCLEditors,
  DesignEditors,
  DesignIntf,
  ToolsAPI;

type
  TSQLCollectionEditor = class(TComponentEditor)
  private
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

  TSQLCollectionWizard = class(TInterfacedObject, IOTAWizard, IOTAMenuWizard, IOTAKeyboardBinding)
  private
    FBindingIndex: Integer;
    procedure ExecuteSQLCollectionEditor(const Context: IOTAKeyContext; KeyCode: TShortcut;
      var BindingResult: TKeyBindingResult);
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
  public
    constructor Create;
    destructor Destroy; override;
    { IOTANotifier }
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
    { IOTAWizard }
    function GetIDString: string;
    function GetName: string;
    function GetState: TWizardState;
    procedure Execute;
    { IOTAMenuWizard }
    function GetMenuText: string;
    { IOTAKeyboardBinding }
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
    property BindingType: TBindingType read GetBindingType;
    property DisplayName: string read GetDisplayName;
    property Name: string read GetName;
  end;

procedure Register;

implementation

uses
  Vcl.Forms,
  Vcl.Dialogs, Vcl.Menus;

procedure Register;
begin
  RegisterComponentEditor(TSQLCollection, TSQLCollectionEditor);

  RegisterPackageWizard(TSQLCollectionWizard.Create);
end;

{ TSQLCollectionEditor }

procedure TSQLCollectionEditor.ExecuteVerb(Index: Integer);
begin
  inherited;

  ShowMessage(GetActiveProject.FileName)
end;

function TSQLCollectionEditor.GetVerb(Index: Integer): string;
begin
  case Index of
    0:
      Result := 'SQLCollection Editor...';
  end;
end;

function TSQLCollectionEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

{ TSQLCollectionWizard }

procedure TSQLCollectionWizard.AfterSave;
begin

end;

procedure TSQLCollectionWizard.BeforeSave;
begin

end;

procedure TSQLCollectionWizard.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  BindingServices.AddKeyBinding([TextToShortCut('F10')], ExecuteSQLCollectionEditor, nil )
end;

constructor TSQLCollectionWizard.Create;
begin
  inherited;
  FBindingIndex := (BorlandIDEServices as IOTAKeyboardServices).AddKeyboardBinding(Self);
end;

destructor TSQLCollectionWizard.Destroy;
begin
  if FBindingIndex >= 0 then
    (BorlandIDEServices as IOTAKeyboardServices).RemoveKeyboardBinding(FBindingIndex);

  inherited Destroy;
end;

procedure TSQLCollectionWizard.Destroyed;
begin

end;

procedure TSQLCollectionWizard.Execute;
begin
  if wsEnabled in GetState then
    ShowMessage('Teste');
end;

procedure TSQLCollectionWizard.ExecuteSQLCollectionEditor(const Context: IOTAKeyContext; KeyCode: TShortcut;
  var BindingResult: TKeyBindingResult);
begin
  Execute;
  BindingResult := krHandled;
end;

function TSQLCollectionWizard.GetBindingType: TBindingType;
begin
  Result := btPartial;
end;

function TSQLCollectionWizard.GetDisplayName: string;
begin
  Result := GetMenuText;
end;

function TSQLCollectionWizard.GetIDString: string;
begin
  Result := 'SQLCollection Editor'
end;

function TSQLCollectionWizard.GetMenuText: string;
begin
  Result := 'SQLCollection Editor';
end;

function TSQLCollectionWizard.GetName: string;
begin
  Result := 'SQLCollection_Editor';
end;

function TSQLCollectionWizard.GetState: TWizardState;
begin
  Result := [];
end;

procedure TSQLCollectionWizard.Modified;
begin

end;

end.
