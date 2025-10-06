unit V.Ledger.Consensus.Core.TimeIndexer;

interface

uses
  System.SysUtils;

type
  ITimeIndex = interface
    ['{A9B8C7D6-E5F4-A3B2-9C8D-7E6F5A4B3C2D}']
    function Time2Index(t: TDateTime): UInt64;
    function Index2Time(i: UInt64): TTuple<TDateTime, TDateTime>;
  end;

  TTimeIndex = class(TInterfacedObject, ITimeIndex)
  private
    FGenesisTime: TDateTime;
    FInterval: TTimeSpan;
  public
    constructor Create(genesisTime: TDateTime; interval: TTimeSpan);
    function Time2Index(t: TDateTime): UInt64;
    function Index2Time(i: UInt64): TTuple<TDateTime, TDateTime>;
  end;

function NewTimeIndex(genesisTime: TDateTime; interval: TTimeSpan): ITimeIndex;

implementation

uses
  System.Math;

const
  OneNanoSecondAsTimeSpan: TTimeSpan = 1 / (24 * 60 * 60 * 1000 * 1000 * 1000);

{ TTimeIndex }

constructor TTimeIndex.Create(genesisTime: TDateTime; interval: TTimeSpan);
begin
  FGenesisTime := genesisTime;
  FInterval := interval;
end;

function TTimeIndex.Index2Time(i: UInt64): TTuple<TDateTime, TDateTime>;
var
  s, e: TDateTime;
begin
  s := FGenesisTime + i * FInterval;
  e := s + FInterval - OneNanoSecondAsTimeSpan;
  Result := TTuple.Create(s, e);
end;

function TTimeIndex.Time2Index(t: TDateTime): UInt64;
begin
  if t < FGenesisTime then
  begin
    Result := 0;
    Exit;
  end;
  if FInterval <= 0 then
  begin
    Result := High(UInt64); // or raise exception
    Exit;
  end;
  Result := Trunc((t - FGenesisTime) / FInterval);
end;

function NewTimeIndex(genesisTime: TDateTime; interval: TTimeSpan): ITimeIndex;
begin
  Result := TTimeIndex.Create(genesisTime, interval);
end;

end.