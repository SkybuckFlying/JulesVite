{
  This file is a translation of the original Go source file:
  https://github.com/vitelabs/go-vite/blob/master/net/sync_cache_reader.go
}
unit V.Net.SyncCacheReader;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  V.Common.Types, V.Interfaces, V.Interfaces.Core, V.Net.Interface,
  V.Net.SyncDownloader, V.Log15;

type
  ISyncCacheReader = interface(IChunkReader)
    ['{A1B2C3D4-E5F6-4A8B-9C8D-7E6F5A4B3C2D}']
    procedure Start;
    procedure Stop;
    function CompareCache(Start: PHashHeight; const HHs: TArray<THashHeightPoint>): TArray<TSyncTask>;
    function Chunks: TArray<array[0..1] of PHashHeight>;
    function Caches: TSegmentList;
    procedure Reset;
  end;

  TCacheReader = class(TInterfacedObject, ISyncCacheReader)
  private
    FChain: ISyncChain;
    FVerifier: IVerifier;
    FDownloader: ISyncDownloader;
    FIrreader: IIrreversibleReader;
    FRunning: Boolean;
    FCritSect: TCriticalSection;
    FCond: TConditionVariable;
    FReadHeight: UInt64;
    FReadable: Integer;
    FBuffer: TList<TChunk>;
    FDownloadRecord: TDictionary<string, TNodeID>;
    FBlackBlocks: TDictionary<THash, Boolean>;
    FWait: TCountdownEvent;
    FLog: TLogger;
    procedure ReadLoop;
    procedure CleanLoop;
    function CanRead: Boolean;
  public
    constructor Create(AChain: ISyncChain; AVerifier: IVerifier; ADownloader: ISyncDownloader; AIrreader: IIrreversibleReader; ABlackBlocks: TDictionary<THash, Boolean>);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function Peek: TChunk;
    procedure Pop(const EndHash: THash);
    function CompareCache(Start: PHashHeight; const HHs: TArray<THashHeightPoint>): TArray<TSyncTask>;
    function Chunks: TArray<array[0..1] of PHashHeight>;
    function Caches: TSegmentList;
    procedure Reset;
  end;

implementation

uses System.Threading;

{ TCacheReader }

constructor TCacheReader.Create(AChain: ISyncChain; AVerifier: IVerifier; ADownloader: ISyncDownloader; AIrreader: IIrreversibleReader; ABlackBlocks: TDictionary<THash, Boolean>);
begin
  inherited Create;
  FChain := AChain;
  FVerifier := AVerifier;
  FDownloader := ADownloader;
  FIrreader := AIrreader;
  FBlackBlocks := ABlackBlocks;
  FCritSect := TCriticalSection.Create;
  FCond := TConditionVariable.Create;
  FBuffer := TList<TChunk>.Create;
  FDownloadRecord := TDictionary<string, TNodeID>.Create;
  FLog := V.Log15.GLog;
  FReadable := 1;
end;

destructor TCacheReader.Destroy;
begin
  Stop;
  FCritSect.Free;
  FCond.Free;
  FBuffer.Free;
  FDownloadRecord.Free;
  inherited Destroy;
end;

procedure TCacheReader.Start;
begin
  FCritSect.Enter;
  try
    if FRunning then Exit;
    FRunning := True;
  finally
    FCritSect.Leave;
  end;
  TThread.CreateAnonymousThread(ReadLoop).Start;
  TThread.CreateAnonymousThread(CleanLoop).Start;
end;

procedure TCacheReader.Stop;
begin
  FCritSect.Enter;
  try
    FRunning := False;
  finally
    FCritSect.Leave;
  end;
  Reset;
  // Wait for threads to finish, simplified
end;

procedure TCacheReader.ReadLoop;
begin
  while FRunning do
  begin
    // Simplified loop logic
    TThread.Sleep(1000);
  end;
end;

procedure TCacheReader.CleanLoop;
begin
  while FRunning do
  begin
    // Simplified loop logic
    TThread.Sleep(10000);
  end;
end;

function TCacheReader.Peek: TChunk;
begin
  FCritSect.Enter;
  try
    if FBuffer.Count > 0 then
      Result := FBuffer.First
    else
      FillChar(Result, SizeOf(TChunk), 0);
  finally
    FCritSect.Leave;
  end;
end;

procedure TCacheReader.Pop(const EndHash: THash);
begin
  FCritSect.Enter;
  try
    if (FBuffer.Count > 0) and CompareMem(@FBuffer.First.SnapshotRange[1].Hash, @EndHash, SizeOf(THash)) then
      FBuffer.Delete(0);
    FCond.Signal;
  finally
    FCritSect.Leave;
  end;
end;

function TCacheReader.CompareCache(Start: PHashHeight; const HHs: TArray<THashHeightPoint>): TArray<TSyncTask>;
begin
  // Placeholder logic
  Result := nil;
end;

function TCacheReader.Chunks: TArray<array[0..1] of PHashHeight>;
begin
  // Placeholder logic
  Result := nil;
end;

function TCacheReader.Caches: TSegmentList;
begin
  // Placeholder logic
  Result := nil;
end;

procedure TCacheReader.Reset;
begin
  FCritSect.Enter;
  try
    FReadHeight := 0;
    FBuffer.Clear;
  finally
    FCritSect.Leave;
  end;
  FCond.Signal;
end;

function TCacheReader.CanRead: Boolean;
begin
  Result := TInterlocked.Read(FReadable) = 1;
end;

end.