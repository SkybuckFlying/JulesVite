unit V.Tools.List;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TList = class(TObjectList<TObject>)
    // This class inherits from TObjectList to provide a basic list implementation.
    // It can be extended if more specific functionality is needed.
  end;

implementation

end.