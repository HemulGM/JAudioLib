unit Jal.Win.AudioClient;

interface

{$ALIGN 1}
{$MINENUMSIZE 4}
{$WEAKPACKAGEUNIT}

uses
  Winapi.Windows, Winapi.ActiveX, Winapi.PropSys;

const
  IID_IAudioClient: TGUID = '{1CB9AD4C-DBFA-4c32-B178-C2F568A703B2}';
  IID_IAudioRenderClient: TGUID = '{F294ACFC-3146-4483-A7BF-ADDCA7C260E2}';
  IID_IAudioCaptureClient: TGUID = '{C8ADBD64-E71E-48a0-A4DE-185C395CD317}';
  KSDATAFORMAT_SUBTYPE_PCM: TGUID = '{00000001-0000-0010-8000-00aa00389b71}';
  //
  WAVE_FORMAT_EXTENSIBLE = $FFFE;
  //
  SPEAKER_FRONT_LEFT = $00000001;
  SPEAKER_FRONT_RIGHT = $00000002;
  SPEAKER_FRONT_CENTER = $00000004;
  SPEAKER_LOW_FREQUENCY = $00000008;
  SPEAKER_BACK_LEFT = $00000010;
  SPEAKER_BACK_RIGHT = $00000020;
  SPEAKER_FRONT_LEFT_OF_CENTER = $00000040;
  SPEAKER_FRONT_RIGHT_OF_CENTER = $00000080;
  SPEAKER_BACK_CENTER = $00000100;
  SPEAKER_SIDE_LEFT = $00000200;
  SPEAKER_SIDE_RIGHT = $00000400;
  SPEAKER_TOP_CENTER = $00000800;
  SPEAKER_TOP_FRONT_LEFT = $00001000;
  SPEAKER_TOP_FRONT_CENTER = $00002000;
  SPEAKER_TOP_FRONT_RIGHT = $00004000;
  SPEAKER_TOP_BACK_LEFT = $00008000;
  SPEAKER_TOP_BACK_CENTER = $00010000;
  SPEAKER_TOP_BACK_RIGHT = $00020000;
  SPEAKER_RESERVED = $7FFC0000;
  SPEAKER_ALL = $80000000;

type
  //{$SCOPEDENUMS ON}
  {$MINENUMSIZE 4}
  TAudioClientShareMode = (
    Shared = $00000000,
    Exclusive = $00000001);

  TAudioClientBufferFlags = (
    DataDiscontinuity = $00000001,
    Silent = $00000002,
    TimestampError = $00000004);
  {$MINENUMSIZE 1}

  TReferenceTime = UInt64;

  PReferenceTime = ^TReferenceTime;

  PIAudioClient = ^IAudioClient;

  PWaveFormatEx = ^TWaveFormatEx;

  TWaveFormatEx = record
    FormatTag: Word;       { format type }
    Channels: Word;        { number of channels (i.e. mono, stereo, etc.) }
    SamplesPerSec: DWORD;  { sample rate }
    AvgBytesPerSec: DWORD; { for buffer estimation }
    BlockAlign: Word;      { block size of data }
    BitsPerSample: Word;   { number of bits per sample of mono data }
    Size: Word;            { the count in bytes of the size of }
  end;

  PWaveFormatExtensible = ^TWaveFormatExtensible;

  TWaveFormatExtensible = record
    Format: TWaveFormatEx;
    ValidBitsPerSample: Word;
    ChannelMask: DWord;
    SubFormat: TGUID;
  end;

  IAudioClient = interface(IUnknown)
    ['{1CB9AD4C-DBFA-4c32-B178-C2F568A703B2}']
    function Initialize(ShareMode: TAudioClientShareMode; StreamFlags: DWORD; BufferDuration: TReferenceTime; Periodicity: TReferenceTime; const pFormat: PWaveFormatExtensible; const AudioSessionGuid: PGUID): HRESULT; stdcall;
    function GetBufferSize(out NumBufferFrames: UInt32): HRESULT; stdcall;
    function GetStreamLatency(Latency: PReferenceTime): HRESULT; stdcall;
    function GetCurrentPadding(NumPaddingFrames: PUInt32): HRESULT; stdcall;
    function IsFormatSupported(ShareMode: TAudioClientShareMode; const Format: PWAVEFORMATEX; out ClosestMatch: PWaveFormatExtensible): HRESULT; stdcall;
    function GetMixFormat(out ppDeviceFormat: PWaveFormatExtensible): HRESULT; stdcall;
    function GetDevicePeriod(phnsDefaultDevicePeriod: PReferenceTime; phnsMinimumDevicePeriod: PReferenceTime): HRESULT; stdcall;
    function Start(): HRESULT; stdcall;
    function Stop(): HRESULT; stdcall;
    function Reset(): HRESULT; stdcall;
    function SetEventHandle(EventHandle: THandle): HRESULT; stdcall;
    function GetService(const RIID: TGUID; out ppv): HRESULT; stdcall;
  end;

  IAudioRenderClient = interface(IUnknown)
    ['{F294ACFC-3146-4483-A7BF-ADDCA7C260E2}']
    function GetBuffer(NumFramesRequested: UInt32; out Data: PBYTE): HRESULT; stdcall;
    function ReleaseBuffer(NumFramesWritten: UInt32; Flags: DWORD): HRESULT; stdcall;
  end;

  IAudioCaptureClient = interface(IUnknown)
    ['{C8ADBD64-E71E-48a0-A4DE-185C395CD317}']
    function GetBuffer(out Data: PBYTE; NumFramesToRead: PUInt32; Flags: PDWORD; DevicePosition: PUInt64; QPCPosition: PUInt64): HRESULT; stdcall;
    function ReleaseBuffer(NumFramesRead: UInt32): HRESULT; stdcall;
    function GetNextPacketSize(NumFramesInNextPacket: PUInt32): HRESULT; stdcall;
  end;

implementation

end.

