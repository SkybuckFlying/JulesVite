{
  This unit is a temporary placeholder for the Go 'rpcapi/api/filters' package.
  It provides a minimal TEventSystem class to allow the conversion of dependent units.
}
unit V.RPCAPI.API.Filters;

interface

uses
  System.SysUtils, V.Vite;

type
  TEventSystem = class
  public
    procedure Start;
    procedure Stop;
  end;

function NewEventSystem(AVite: TVite): TEventSystem;

var
  Es: TEventSystem;

implementation

{ TEventSystem }

procedure TEventSystem.Start;
begin
  // Placeholder
end;

procedure TEventSystem.Stop;
begin
  // Placeholder
end;

function NewEventSystem(AVite: TVite): TEventSystem;
begin
  Result := TEventSystem.Create;
end;

end.