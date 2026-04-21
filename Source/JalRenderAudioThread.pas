unit JalRenderAudioThread;

interface

uses
  System.SysUtils, System.Classes, System.Win.ComObj, System.SyncObjs,
  System.StrUtils, Winapi.Windows, Winapi.ActiveX, Jal.Win.MMDeviceAPI,
  Jal.Win.AudioClient, JalAudioDevice;

type
  TAudioShareMode = TAudioClientShareMode;

  TOnRenderBuffer = procedure(const a_Sender: TThread; const a_pData: PByte; const a_AvailableCount: Cardinal; var a_Flags: DWORD) of object;

  TJalRenderAudioThread = class(TThread)
  private
    FAudioShareMode: TAudioShareMode;
    FWaveFormat: TWaveFormatExtensible;
    FOnRenderBuffer: TOnRenderBuffer;

    FAudioDevice: TJalAudioDevice;
    FAudioClient: IAudioClient;
    FAudioRenderClient: IAudioRenderClient;
    FBufferFrameCount: UInt32;
    FThreadIntervalMs: Cardinal;

    function StartRender: Boolean;
  public
    constructor Create(const AudioShareMode: TAudioShareMode; const Format: TWaveFormatExtensible);
    destructor Destroy; override;

    property OnRenderBuffer: TOnRenderBuffer write FOnRenderBuffer;
  protected
    procedure Execute; override;
  end;

const
  // 1 REFTIMES = 100 nano sec
  REFTIMES_PER_SEC: TReferenceTime = 10000000; // REFTIMES to Sec
  REFTIMES_PER_MSEC: TReferenceTime = 10000;    // REFTIMES to MSec
  REFTIME_LOWLATENCY: TReferenceTime = 50000; // 5ms

implementation

uses
  System.Math;

{ TRenderAudioThread }

constructor TJalRenderAudioThread.Create(const AudioShareMode: TAudioShareMode; const Format: TWaveFormatExtensible);
begin
  FAudioShareMode := AudioShareMode;
  FWaveFormat := Format;
  FreeOnTerminate := False;
  inherited Create(True);
  Priority := TThreadPriority.tpTimeCritical;
end;

destructor TJalRenderAudioThread.Destroy;
begin
  if Assigned(FAudioDevice) then
    FreeAndNil(FAudioDevice);

  inherited;
end;

function TJalRenderAudioThread.StartRender: Boolean;
var
  LpBuffer: PByte;
  LShareMode: TAudioClientShareMode;
  LStreamFlags: DWORD;
  LWaveFormatExtensible: TWaveFormatExtensible;
  LBufferDuration: TReferenceTime;
  LPeriodicity: TReferenceTime;
begin
  Result := False;

  // Get Audio Client
  if Succeeded(FAudioDevice.Device.Activate(IID_IAudioClient, CLSCTX_ALL, nil, FAudioClient)) then
  begin
    // Support exclusive mode.
    if FAudioShareMode = TAudioShareMode.Exclusive then
    begin
      LShareMode := TAudioClientShareMode.Exclusive;
      LStreamFlags := 0;
      LBufferDuration := REFTIME_LOWLATENCY;
      LPeriodicity := REFTIME_LOWLATENCY;
    end
    else
    begin
      LShareMode := TAudioClientShareMode.Shared;
      LStreamFlags := AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM or AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY;
      LBufferDuration := REFTIMES_PER_SEC; // Shared mode is impossible lowlatency.
      LPeriodicity := 0;
    end;

    // Change to Extensible.
    LWaveFormatExtensible := FWaveFormat;

    // Init AudioClient *AUTOCONVERTPCM makes the IsFormatSupported and GetMixFormat function unnecessary.
    if Succeeded(FAudioClient.Initialize(
        LShareMode, LStreamFlags, LBufferDuration, LPeriodicity, @LWaveFormatExtensible, nil)) then
    begin
      // Get Audio Render Client
      if Succeeded(FAudioClient.GetService(IID_IAudioRenderClient, FAudioRenderClient)) then
      begin
        // Get buffer size
        if Succeeded(FAudioClient.GetBufferSize(FBufferFrameCount)) then
        begin
          // Get optimal thread interval
          FThreadIntervalMs :=
            Ceil(LBufferDuration * FBufferFrameCount / FWaveFormat.Format.SamplesPerSec / REFTIMES_PER_MSEC / 2);

          // Destoroy initial buffer
          if Succeeded(FAudioRenderClient.GetBuffer(FBufferFrameCount, LpBuffer)) then
          begin
            if Succeeded(FAudioRenderClient.ReleaseBuffer(FBufferFrameCount, 0)) then
            begin
              // Start Render
              Result := Succeeded(FAudioClient.Start);
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TJalRenderAudioThread.Execute;
var
  LNumFramesPadding: UInt32;
  LNumFramesAvailable: UInt32;
  LpBuffer: PByte;
  LFlags: DWORD;
begin
  // Create Audio Device
  FAudioDevice := TJalAudioDevice.Create(COINIT_MULTITHREADED, TDataFlow.Render);

  // Check ready device and start render
  if (FAudioDevice.Ready) and (StartRender) then
  begin
    while (not Terminated) do
    begin
      // Wait...
      TThread.Sleep(10); //FThreadIntervalMs

      // See how much buffer space is available
      if Succeeded(FAudioClient.GetCurrentPadding(@LNumFramesPadding)) then
      begin
        LNumFramesAvailable := FBufferFrameCount - LNumFramesPadding;

        // Get buffer space
        if Succeeded(FAudioRenderClient.GetBuffer(LNumFramesAvailable, LpBuffer)) then
        begin
          // Callback Render Buffer
          // *Frame x BlockAlign = bufer size
          // *Flags is AUDCLNT_BUFFERFLAGS_...
          if Assigned(FOnRenderBuffer) then
          begin
            FOnRenderBuffer(Self, LpBuffer, LNumFramesAvailable * FWaveFormat.Format.BlockAlign, LFlags);
          end;

          FAudioRenderClient.ReleaseBuffer(LNumFramesAvailable, LFlags);
        end;
      end;
    end;

    // Wait for finish playing
    TThread.Sleep(FThreadIntervalMs);

    // Stop Capture
    FAudioClient.Stop;
  end;
end;

end.

