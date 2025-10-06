unit V.Net.Skeleton;

interface

uses
  System.SysUtils,
  V.Common.Types,
  V.Interfaces;

type
  ISkeleton = interface
    ['{D4E5F6A7-B8C9-4D8E-9F80-716C5D4E3F2F}']
    // This is a placeholder for the skeleton interface, which likely deals
    // with block skeletons for synchronization.
    function GetSegments(from, to: UInt64): TSegmentList;
  end;

implementation

end.