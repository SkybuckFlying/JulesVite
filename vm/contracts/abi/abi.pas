unit V.VM.Contracts.ABI;

interface

uses
  System.SysUtils;

type
  IABI = interface
    ['{D4E5F6A7-B8C9-4D8E-9F80-716C5D4E3F30}']
    // This is a placeholder for the ABI interface, which would handle
    // encoding and decoding of contract calls and data.
    function Pack(name: string; args: array of const): TBytes;
    procedure Unpack(out v: TObject; name: string; data: TBytes);
  end;

implementation

end.