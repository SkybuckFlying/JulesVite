unit V.VM.IntPool;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Go.Big;

type
  TIntPool = class
  private
    FPool: TObjectPool<TObject>; // TObject is a placeholder for a pooled BigInt wrapper
  public
    constructor Create;
    destructor Destroy; override;
    function Get: IBigInt;
    procedure Put(i: IBigInt);
  end;

implementation

{ TIntPool }

constructor TIntPool.Create;
begin
  // In a real implementation, the pool would be initialized here.
  // For now, this is a placeholder.
end;

destructor TIntPool.Destroy;
begin
  // FPool.Free;
  inherited;
end;

function TIntPool.Get: IBigInt;
begin
  // var obj := FPool.GetObject;
  // Result := obj as IBigInt;
  Result := TBigInt.New; // Simplified for now
end;

procedure TIntPool.Put(i: IBigInt);
begin
  // FPool.PutObject(i as TObject);
end;

end.