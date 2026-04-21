unit JalWaveHelper;

interface

uses
  Winapi.MMSystem, Jal.Win.AudioClient;

type
  TJalWaveHelper = class
  public
    class function GetPCMFormat(const Samples: Cardinal; const Bits, Channels: Word): TWaveFormatEx;
  end;

  TMyWaveformatExHelper = record helper for TWaveFormatEx
    function ToExtensible: TWaveFormatExtensible;
  end;

implementation

{ TJalWaveHelper }

class function TJalWaveHelper.GetPCMFormat(const Samples: Cardinal; const Bits, Channels: Word): TWaveFormatEx;
begin
  Result.FormatTag := WAVE_FORMAT_PCM;
  Result.Channels := Channels;
  Result.SamplesPerSec := Samples;
  Result.BitsPerSample := Bits;
  Result.BlockAlign := Round(Result.Channels * Result.BitsPerSample / 8);
  Result.AvgBytesPerSec := Result.SamplesPerSec * Result.BlockAlign;
  Result.Size := 0;
end;

{ TMyWaveformatExHelper }

function TMyWaveformatExHelper.ToExtensible: TWaveFormatExtensible;
begin
  Result.Format := Self;

  Result.Format.FormatTag := WAVE_FORMAT_EXTENSIBLE;
  Result.Format.Size := 22;
  Result.ValidBitsPerSample := Result.Format.BitsPerSample;
  case Channels of
    1:
      Result.ChannelMask := SPEAKER_FRONT_LEFT;
    2:
      Result.ChannelMask := SPEAKER_FRONT_LEFT or SPEAKER_FRONT_RIGHT;
  else
    Result.ChannelMask := SPEAKER_ALL;
  end;
  Result.SubFormat := KSDATAFORMAT_SUBTYPE_PCM;
end;

end.

