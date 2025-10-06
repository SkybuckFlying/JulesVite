unit Go.LevelDB;

interface

uses
  System.SysUtils,
  Go.LevelDB.Util;

type
  IIterator = interface
    ['{F6A7B8C9-D0E1-4F80-9182-736E5F403122}']
    function Next: Boolean;
    function Key: TBytes;
    function Value: TBytes;
    function Error: Error;
    procedure Release;
  end;

  ILevelDB = interface
    ['{A7B8C9D0-E1F2-4081-9283-746F50413233}']
    function Get(key: TBytes; ro: Pointer): TTuple<TBytes, Error>;
    function Put(key, value: TBytes; wo: Pointer): Error;
    function Delete(key: TBytes; wo: Pointer): Error;
    function NewIterator(slice: IBytesPrefix; ro: Pointer): IIterator;
  end;

var
  ErrNotFound: Error;

implementation

initialization
  ErrNotFound := EProgrammerException.Create('leveldb: not found');

end.