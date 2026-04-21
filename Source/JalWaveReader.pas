unit JalWaveReader;

interface

uses
  System.Classes, System.SysUtils, System.Types, Winapi.MMSystem,
  Jal.Win.AudioClient;

type
  TJalWaveReader = class
  private
    FAvailable: Boolean;
    FFileStream: TFileStream;
    FBinaryReader: TBinaryReader;
    FFormatExtensible: TWaveFormatExtensible;
  public
    constructor Create(const DirFileName: string);
    destructor Destroy; override;

    property Available: Boolean read FAvailable;
    property FormatExtensible: TWaveFormatExtensible read FFormatExtensible;

    function ReadBuffer(const Dest: PByte; const Count: Cardinal): Cardinal;
  end;

implementation

{ TWaveReader }

constructor TJalWaveReader.Create(const DirFileName: string);
var
  LRIFF: TArray<Char>;
  LRIFFStr: string;
  //LChunkSize: Cardinal;
  LFormat: TArray<Char>;
  LFormatStr: string;
  LFmtIdent: TArray<Char>;
  LFmtIdentStr: string;
  LFmtSize: Cardinal;
  LDataIdent: TArray<Char>;
  LDataIdentStr: string;
  LDataSize: Cardinal;
begin
  FAvailable := False;

  // Create Streams
  FFileStream := TFileStream.Create(DirFileName, fmOpenRead or fmShareDenyWrite);
  FBinaryReader := TBinaryReader.Create(FFileStream, TEncoding.ASCII);

  // Read Headers...
  LRIFF := FBinaryReader.ReadChars(4);
  //LChunkSize :=
  FBinaryReader.ReadCardinal;
  LFormat := FBinaryReader.ReadChars(4);

  SetString(LRIFFStr, PChar(LRIFF), Length(LRIFF));
  SetString(LFormatStr, PChar(LFormat), Length(LFormat));

  // Check Headers
  if (LRIFFStr = 'RIFF') and (LFormatStr = 'WAVE') then
  begin
    // Read fmt chunks...
    LFmtIdent := FBinaryReader.ReadChars(4);
    LFmtSize := FBinaryReader.ReadCardinal;

    SetString(LFmtIdentStr, PChar(LFmtIdent), Length(LFmtIdent));

    if (LFmtIdentStr = 'fmt ') and (LFmtSize >= 16) then
    begin
      FFormatExtensible.Format.FormatTag := FBinaryReader.ReadWord;
      FFormatExtensible.Format.Channels := FBinaryReader.ReadWord;
      FFormatExtensible.Format.SamplesPerSec := FBinaryReader.ReadCardinal;
      FFormatExtensible.Format.AvgBytesPerSec := FBinaryReader.ReadCardinal;
      FFormatExtensible.Format.BlockAlign := FBinaryReader.ReadWord;
      FFormatExtensible.Format.BitsPerSample := FBinaryReader.ReadWord;
    end;

    // PCM
    if FFormatExtensible.Format.FormatTag = WAVE_FORMAT_PCM then
    begin
      // Without extension block
      if LFmtSize = 16 then
      begin
        FFormatExtensible.Format.Size := 0;

        // Read Data chunk
        LDataIdent := FBinaryReader.ReadChars(4);

        SetString(LDataIdentStr, PChar(LDataIdent), Length(LDataIdent));

        if LDataIdentStr = 'data' then
        begin
          LDataSize := FBinaryReader.ReadCardinal;

          if LDataSize > 0 then
          begin
            FAvailable := True;
          end;
        end;
      end;
    end
    // Extensible
    else if FFormatExtensible.Format.FormatTag = WAVE_FORMAT_EXTENSIBLE then
    begin
      // Read extension block
      FFormatExtensible.Format.Size := FBinaryReader.ReadWord;
      FFormatExtensible.ValidBitsPerSample := FBinaryReader.ReadWord;
      FFormatExtensible.ChannelMask := FBinaryReader.ReadCardinal;
      FFormatExtensible.SubFormat := TGUID.Create(FBinaryReader.ReadBytes(16));
    end;
  end;
end;

destructor TJalWaveReader.Destroy;
begin
  FreeAndNil(FBinaryReader);
  FreeAndNil(FFileStream);

  inherited;
end;

function TJalWaveReader.ReadBuffer(const Dest: PByte; const Count: Cardinal): Cardinal;
var
  LData: TBytes;
begin
  // Read Data
  SetLength(LData, Count);
  Result := FBinaryReader.Read(LData, 0, Length(LData));

  Move(LData[0], Dest^, Result);
end;

end.

