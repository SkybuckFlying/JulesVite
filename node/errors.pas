unit V.Node.Errors;

interface

uses
  System.SysUtils;

var
  ErrNodeStopped: Error;
  ErrNodeAlreadyStarted: Error;
  ErrNodeNotStarted: Error;

implementation

initialization
  ErrNodeStopped := EProgrammerException.Create('node is stopped');
  ErrNodeAlreadyStarted := EProgrammerException.Create('node is already started');
  ErrNodeNotStarted := EProgrammerException.Create('node is not started');
end.