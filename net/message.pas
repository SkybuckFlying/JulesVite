unit V.Net.Message;

interface

uses
  System.SysUtils,
  V.Common.Types;

type
  TMessage = record
    Code: UInt64;
    Payload: TBytes;
    // other fields as needed
  end;

implementation

end.