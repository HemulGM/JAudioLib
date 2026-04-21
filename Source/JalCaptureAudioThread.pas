unit JalCaptureAudioThread;

interface

uses
  System.SysUtils, System.Classes, System.Win.ComObj, System.SyncObjs,
  System.StrUtils, Winapi.Windows, Winapi.ActiveX, Jal.Win.MMDeviceAPI,
  Jal.Win.AudioClient, JalAudioDevice, JalNotificationClient;

type
  {$SCOPEDENUMS ON}
  TAudioType = (Mic, System);

  TAudioShareMode = TAudioClientShareMode;

  TOnCaptureBuffer = procedure(const Sender: TThread; const Data: PByte; const Count: Integer) of object;

  TJalCaptureAudioThread = class(TThread)
  private
    FAudioType: TAudioType;
    FAudioShareMode: TAudioShareMode;
    FWaveFormat: TWaveFormatEx;
    FOnDefaultDeviceChanged: TOnDefaultDeviceChanged;
    FOnCaptureBuffer: TOnCaptureBuffer;

    FAudioDevice: TJalAudioDevice;
    FAudioClient: IAudioClient;

    FAudioCaptureClient: IAudioCaptureClient;
    FThreadIntervalMs: Cardinal;

    function StartCapture: Boolean;
  public
    constructor Create(const AudioType: TAudioType; const AudioShareMode: TAudioShareMode; const Format: TWaveFormatEx; const OnDefaultDeviceChanged: TOnDefaultDeviceChanged = nil);
    destructor Destroy; override;

    property OnCaptureBuffer: TOnCaptureBuffer write FOnCaptureBuffer;
  protected
    procedure Execute; override;
  end;

const
  // 1 REFTIMES = 100 nano sec
  REFTIMES_PER_SEC: TReferenceTime = 10000000; // REFTIMES to Sec
  REFTIMES_PER_MSEC: TReferenceTime = 10000;    // REFTIMES to MSec

  // For LowLatency Mode
  REFTIME_LOWLATENCY: TReferenceTime = 50000; // 5ms
  THREAD_INTERVALMS_LOWLATENCY: Integer = 10;

implementation

uses
  System.Math, JalWaveHelper;

{ TAudioStreamClientThread }

constructor TJalCaptureAudioThread.Create(const AudioType: TAudioType; const AudioShareMode: TAudioShareMode; const Format: TWaveFormatEx; const OnDefaultDeviceChanged: TOnDefaultDeviceChanged = nil);
begin
  FAudioType := AudioType;
  FAudioShareMode := AudioShareMode;
  FWaveFormat := Format;
  FOnDefaultDeviceChanged := OnDefaultDeviceChanged;

  FreeOnTerminate := False;
  inherited Create(False);
end;

destructor TJalCaptureAudioThread.Destroy;
begin
  if Assigned(FAudioDevice) then
    FreeAndNil(FAudioDevice);

  inherited;
end;

function TJalCaptureAudioThread.StartCapture: Boolean;
var
  LShareMode: TAudioClientShareMode;
  LStreamFlags: DWORD;
  LBufferFrameCount: DWORD;
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

      case FAudioType of
        TAudioType.Mic:
          LStreamFlags := AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM or AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY;
        TAudioType.System:
          LStreamFlags := AUDCLNT_STREAMFLAGS_LOOPBACK or AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM or
            AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY;
      else
        LStreamFlags := 0;
      end;

      LBufferDuration := REFTIMES_PER_SEC;
      LPeriodicity := 0;
    end;

    // Change to Extensible.
    LWaveFormatExtensible.Format := FWaveFormat;

    // Init AudioClient *AUTOCONVERTPCM makes the IsFormatSupported and GetMixFormat function unnecessary.
    if Succeeded(FAudioClient.Initialize(
        LShareMode, LStreamFlags, LBufferDuration, LPeriodicity, @LWaveFormatExtensible, nil)) then
    begin
      if Succeeded(FAudioClient.GetBufferSize(LBufferFrameCount)) then
      begin
        // Get optimal thread interval
        FThreadIntervalMs :=
          Ceil(LBufferDuration * LBufferFrameCount / FWaveFormat.SamplesPerSec / REFTIMES_PER_MSEC / 2);

        // Get Audio Capture Client
        if Succeeded(FAudioClient.GetService(IID_IAudioCaptureClient, FAudioCaptureClient)) then
        begin
          // Start Capture
          Result := Succeeded(FAudioClient.Start);
        end;
      end;
    end;
  end;
end;

procedure TJalCaptureAudioThread.Execute;
var
  LDataFlow: TDataFlow;
  LIncomingBufferSize: UInt32;
  LPacketLength: UInt32;
  LpBuffer: PByte;
  LNumFramesAvailable: UInt32;
  LFlags: DWORD;
  LDevicePosition: UInt64;
  LQPCPosition: UInt64;
begin
  case FAudioType of
    TAudioType.Mic:
      LDataFlow := TDataFlow.Capture;
    TAudioType.System:
      LDataFlow := TDataFlow.Render;
  else
    Exit;
  end;

  // Create Audio Device
  FAudioDevice := TJalAudioDevice.Create(COINIT_MULTITHREADED, LDataFlow, FOnDefaultDeviceChanged);

  // Check ready device and start capture
  if (FAudioDevice.Ready) and (StartCapture) then
  begin
    while (not Terminated) do
    begin
      // Wait...
      TThread.Sleep(FThreadIntervalMs);

      if Terminated then
        Break;

      // Get packet size
      if Succeeded(FAudioCaptureClient.GetNextPacketSize(@LPacketLength)) then
      begin
        // Process all packet
        while LPacketLength <> 0 do
        begin
          LpBuffer := nil;

          // Get buffer pointer
          if Succeeded(FAudioCaptureClient.GetBuffer(LpBuffer, @LNumFramesAvailable, @LFlags, @LDevicePosition,
              @LQPCPosition)) then
          begin
            // Check sirent
            if (LFlags and Ord(TAudioClientBufferFlags.Silent)) > 0 then
            begin
              LpBuffer := nil;
            end;

            if (LpBuffer <> nil) and (LNumFramesAvailable > 0) then
            begin
              // Get buffer size
              LIncomingBufferSize := FWaveFormat.BlockAlign * LNumFramesAvailable;

              // Callback Capture Buffer
              if Assigned(FOnCaptureBuffer) then
              begin
                FOnCaptureBuffer(Self, LpBuffer, LIncomingBufferSize);
              end;
            end;

            if Succeeded(FAudioCaptureClient.ReleaseBuffer(LNumFramesAvailable)) then
            begin
              // Get next packet size
              FAudioCaptureClient.GetNextPacketSize(@LPacketLength);
            end;
          end;
        end;
      end;
    end;

    // Stop Capture
    FAudioClient.Stop;
  end;
end;

end.

