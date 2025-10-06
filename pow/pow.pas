unit V.Pow;

interface

uses
  System.SysUtils,
  V.Pow.Remote;

type
  IPow = interface
    // This is a placeholder for the main Proof of Work interface.
    function get_Remote: IRemotePow;
    property Remote: IRemotePow read get_Remote;
  end;

implementation

end.