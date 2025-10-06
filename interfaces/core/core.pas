unit V.Interfaces.Core;

interface

uses
  System.SysUtils,
  V.Common.Types;

type
  IAccountBlock = interface
    ['{D4E5F6A7-B8C9-4D8E-9F80-716C5D4E3F2D}']
    function get_AccountAddress: TAddress;
    property AccountAddress: TAddress read get_AccountAddress;
  end;

implementation

end.