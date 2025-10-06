unit V.Ledger.Chain.Index;

interface

uses
  System.SysUtils,
  V.Common.Types;

type
  PMemberInfo = ^TMemberInfo;
  TMemberInfo = record
    GenesisTime: TDateTime;
    PlanInterval: UInt64;
    // other fields as needed
  end;

  TIndexDB = class
    // This is a placeholder for the index database, which would handle
    // storing and retrieving chain index information.
  end;

implementation

end.