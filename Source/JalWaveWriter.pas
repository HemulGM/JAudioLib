unit JalWaveWriter;

interface

uses
  System.Classes, System.SysUtils, Winapi.MMSystem, Jal.Win.AudioClient;

type
  TJalWaveWriter = class
  private
    FFormat: TWaveFormatEx;
    FFileStream: TFileStream;
    FBinaryWriter: TBinaryWriter;
    FDataSizePosition: Int64;
    FDataSize: UInt32;
  public
    constructor Create(const DirFileName: string; const Format: TWaveFormatEx);
    destructor Destroy; override;

    property Format: TWaveFormatEx read FFormat;

    procedure WriteBuffer(const Source: PByte; const Count: Integer);
    procedure Close;
  end;

implementation

{ TWaveWriter }

constructor TJalWaveWriter.Create(const DirFileName: string; const Format: TWaveFormatEx);
begin
  FFormat := Format;

  // Create Streams
  FFileStream := TFileStream.Create(DirFileName, fmCreate);
  FBinaryWriter := TBinaryWriter.Create(FFileStream, TEncoding.ASCII);

  // Write Headers
  FBinaryWriter.Write('RIFF'.ToCharArray);
  FBinaryWriter.Write(UInt32(0));
  FBinaryWriter.Write('WAVE'.ToCharArray);
  FBinaryWriter.Write('fmt '.ToCharArray);
  FBinaryWriter.Write(UInt32(16 + Format.Size));
  FBinaryWriter.Write(Format.FormatTag);
  FBinaryWriter.Write(Format.Channels);
  FBinaryWriter.Write(Format.SamplesPerSec);
  FBinaryWriter.Write(Format.AvgBytesPerSec);
  FBinaryWriter.Write(Format.BlockAlign);
  FBinaryWriter.Write(Format.BitsPerSample);
  FBinaryWriter.Write('data'.ToCharArray);
  FDataSizePosition := FFileStream.Position; // Store Position
  FBinaryWriter.Write(UInt32(0));             // Reserve DataSize area

  FDataSize := 0;
end;

destructor TJalWaveWriter.Destroy;
begin
  FreeAndNil(FBinaryWriter);
  FreeAndNil(FFileStream);

  inherited;
end;

procedure TJalWaveWriter.WriteBuffer(const Source: PByte; const Count: Integer);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, Count);
  Move(Source^, LBytes[0], Length(LBytes));

  // Write to WAVE
  FBinaryWriter.Write(LBytes, 0, Count);

  // Store data size
  Inc(FDataSize, Count);
end;

procedure TJalWaveWriter.Close;
begin
  // Write Chunk
  FBinaryWriter.Seek(4, TSeekOrigin.soBeginning);
  FBinaryWriter.Write(UInt32(FBinaryWriter.BaseStream.Size - 8));

  // Write Data Size
  FBinaryWriter.Seek(FDataSizePosition, TSeekOrigin.soBeginning);
  FBinaryWriter.Write(FDataSize);
end;

end.

