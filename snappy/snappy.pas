unit V.Snappy;

interface

uses
  System.SysUtils;

type
  IReader = interface
    // Placeholder for snappy reader
  end;

  IWriter = interface
    // Placeholder for snappy writer
  end;

function NewReader(r: TStream): IReader;
function NewWriter(w: TStream): IWriter;

implementation

function NewReader(r: TStream): IReader;
begin
  Result := nil; // Placeholder
end;

function NewWriter(w: TStream): IWriter;
begin
  Result := nil; // Placeholder
end;

end.