unit V.Net.MockCodec;

interface

uses
  System.SysUtils,
  V.Net.Codec,
  V.Net.Message;

type
  TMockCodec = class(TInterfacedObject, ICodec)
    // This is a placeholder for a mock codec implementation, used for testing.
  public
    function Decode(msg: TMessage): Error;
    function Encode(msg: TMessage): TBytes;
  end;

implementation

{ TMockCodec }

function TMockCodec.Decode(msg: TMessage): Error;
begin
  Result := nil; // Assume success for mock
end;

function TMockCodec.Encode(msg: TMessage): TBytes;
begin
  Result := msg.Payload; // Simple pass-through for mock
end;

end.