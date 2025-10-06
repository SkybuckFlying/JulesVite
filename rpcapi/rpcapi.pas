unit V.RPCAPI;

interface

uses
  System.SysUtils,
  V.RPCAPI.API.Filters;

type
  IAPI = interface
    // This is a placeholder for a general RPC API, which might
    // include the filter API as a sub-component.
    function get_Filters: IFilterAPI;
    property Filters: IFilterAPI read get_Filters;
  end;

implementation

end.