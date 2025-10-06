unit V.Node.Config;

interface

uses
  System.SysUtils,
  V.Common.Config;

type
  TNodeConfig = record
    // This is a placeholder for the node-specific configuration.
    // It would typically embed or reference the common TConfig.
    Common: TConfig;
  end;

implementation

end.