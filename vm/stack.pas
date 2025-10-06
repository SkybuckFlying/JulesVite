unit V.VM.Stack;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Go.Big;

type
  TStack = class
  private
    FData: TList<IBigInt>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Push(d: IBigInt);
    function Pop: IBigInt;
    function Len: Integer;
    function Peek: IBigInt;
  end;

implementation

{ TStack }

constructor TStack.Create;
begin
  FData := TList<IBigInt>.Create;
end;

destructor TStack.Destroy;
begin
  FData.Free;
  inherited;
end;

procedure TStack.Push(d: IBigInt);
begin
  FData.Add(d);
end;

function TStack.Pop: IBigInt;
begin
  if FData.Count = 0 then
    raise EStackOverflow.Create('stack underflow');
  Result := FData[FData.Count - 1];
  FData.Delete(FData.Count - 1);
end;

function TStack.Len: Integer;
begin
  Result := FData.Count;
end;

function TStack.Peek: IBigInt;
begin
  if FData.Count = 0 then
    raise EStackOverflow.Create('stack underflow');
  Result := FData[FData.Count - 1];
end;

end.