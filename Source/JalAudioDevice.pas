unit JalAudioDevice;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Winapi.Windows,
  Winapi.ActiveX, Winapi.PropSys, Jal.Win.MMDeviceAPI, Jal.Win.EndpointVolume,
  JalNotificationClient;

type
  // ***************************************************************************
  // Volume Callback Handler
  TOnChangeVolume = procedure(const Data: TAudioVolumeNotificationData) of object;

  TAudioEndpointVolumeCallbackHandler = class(TInterfacedObject, IAudioEndpointVolumeCallback)
  private
    FOnChangeVolume: TOnChangeVolume;
  public
    constructor Create(const OnControlChangeNotify: TOnChangeVolume);
    destructor Destroy; override;
    function OnNotify(Notify: TAudioVolumeNotificationData): HRESULT; stdcall;
  end;

  // ***************************************************************************
  // Audio Streaming Device Class
  TOnChangeMasterLevel = procedure(const Value: Integer) of object;

  TOnChangeMute = procedure(const Value: Boolean) of object;

  TJalAudioDevice = class
  private
    FReady: Boolean;
    FVolumeCallbackHandler: TAudioEndpointVolumeCallbackHandler;
    FPropertyStore: IPropertyStore;

    // Device Emurator...
    FDeviceEnumerator: IMMDeviceEnumerator;
    FDataFlow: TDataFlow;
    FRole: TRole;
    FNotificationClient: TJalNotificationClient;
    FOnDefaultDeviceChanged: TOnDefaultDeviceChanged;

    // Device Props...
    FDevice: IMMDevice;
    FAudioEndpointVolume: IAudioEndpointVolume;
    FInterfaceFriendlyName: string;
    FDeviceDesc: string;
    FFriendlyName: string;
    FDeviceId: string;
    FContainerId: TGUID;

    // Endpoint Volume Props...
    FChannelCount: DWORD;
    FMasterLevel: Single;
    FMute: Boolean;
    FStep: DWORD;
    FStepCount: DWORD;
    FMin: Single;
    FMax: Single;
    FSpin: Single;

    FOnChangeMasterLevel: TOnChangeMasterLevel;
    FOnChangeMute: TOnChangeMute;

    function InitEmurator(const CoInitFlag: Integer; const DataFlowType: TDataFlow; const Role: TRole): Boolean;
    function InitDevice(const DataFlowType: TDataFlow; const Role: TRole): Boolean;

    procedure SetDeviceDesc(const Value: string);
    procedure SetMasterLevel(const Value: Single);
    procedure SetMute(const Value: Boolean);

    function GetDeviceProps(const PropertyStore: IPropertyStore): Boolean;
    function GetAudioEndpointVolumeProps(): Boolean;
    procedure OnControlChangeNotify(const Data: TAudioVolumeNotificationData);
  public
    constructor Create(const CoInitFlag: Longint; const DataFlowType: TDataFlow; const OnDefaultDeviceChanged: TOnDefaultDeviceChanged = nil);
    destructor Destroy; override;

    property Ready: Boolean read FReady;

    property Device: IMMDevice read FDevice;

    property DeviceDesc: string read FDeviceDesc write SetDeviceDesc;
    property FriendlyName: string read FFriendlyName;
    property DeviceId: string read FDeviceId;
    property ContainerId: TGUID read FContainerId;

    property ChannelCount: DWORD read FChannelCount;
    property MasterLevel: Single read FMasterLevel write SetMasterLevel;
    property Mute: Boolean read FMute write SetMute;
    property Step: DWORD read FStep;
    property StepCount: DWORD read FStepCount;
    property Min: Single read FMin;
    property Max: Single read FMax;
    property Spin: Single read FSpin;

    property OnChangeMasterLevel: TOnChangeMasterLevel write FOnChangeMasterLevel;
    property OnChangeMute: TOnChangeMute write FOnChangeMute;
  end;

implementation

{ TAudioEndpointVolumeCallbackHandler }

constructor TAudioEndpointVolumeCallbackHandler.Create(const OnControlChangeNotify: TOnChangeVolume);
begin
  inherited Create;

  FOnChangeVolume := OnControlChangeNotify; // Store Callback
end;

destructor TAudioEndpointVolumeCallbackHandler.Destroy;
begin
  inherited;
end;

function TAudioEndpointVolumeCallbackHandler.OnNotify(Notify: TAudioVolumeNotificationData): HRESULT;
begin
  FOnChangeVolume(Notify); // Callback

  Result := S_OK;
end;

{ TAudioStreamDevice }

constructor TJalAudioDevice.Create(const CoInitFlag: Longint; const DataFlowType: TDataFlow; const OnDefaultDeviceChanged: TOnDefaultDeviceChanged = nil);
begin
  FDataFlow := DataFlowType;
  FRole := TRole.Console;
  FOnDefaultDeviceChanged := OnDefaultDeviceChanged;

  // Init Emurator and Init Device
  FReady := InitEmurator(CoInitFlag, FDataFlow, FRole) and InitDevice(FDataFlow, FRole);
end;

destructor TJalAudioDevice.Destroy;
begin
  if Assigned(FVolumeCallbackHandler) then
  begin
    // Unregister Callback Handler
    FAudioEndpointVolume.UnregisterControlChangeNotify(FVolumeCallbackHandler);
  end;

  if Assigned(FNotificationClient) then
  begin
    if FNotificationClient.RefCount > 0 then
    begin
      // Unregister Notification Client
      FDeviceEnumerator.UnregisterEndpointNotificationCallback(FNotificationClient);
    end;

    FreeAndNil(FNotificationClient);
  end;

  CoUninitialize();

  inherited;
end;

function TJalAudioDevice.InitEmurator(const CoInitFlag: Integer; const DataFlowType: TDataFlow; const Role: TRole): Boolean;
begin
  // Init COM
  Result := (Succeeded(CoInitializeEx(nil, CoInitFlag))) and // Get DeviceEnumerator
    (Succeeded(CoCreateInstance(CLSID_IMMDeviceEnumerator, nil, CLSCTX_ALL, IID_IMMDeviceEnumerator,
        FDeviceEnumerator)));
end;

function TJalAudioDevice.InitDevice(const DataFlowType: TDataFlow; const Role: TRole): Boolean;
var
  LId: PWideChar;
begin
  Result := False;

  // Get Device
  if Succeeded(FDeviceEnumerator.GetDefaultAudioEndpoint(DataFlowType, Role, FDevice)) then
  begin
    // Get Device ID
    if Succeeded(FDevice.GetId(LId)) then
    begin
      // Store ID
      FDeviceId := LId;

      FNotificationClient := TJalNotificationClient.Create(FDeviceId, DataFlowType, Role,
        FOnDefaultDeviceChanged);

      // Register Notification Client
      if Succeeded(FDeviceEnumerator.RegisterEndpointNotificationCallback(FNotificationClient)) then
      begin
        // Get Open Property Interface
        if Succeeded(FDevice.OpenPropertyStore(STGM_READWRITE, FPropertyStore)) then
        begin
          // Get Device Properties
          if GetDeviceProps(FPropertyStore) then
          begin
            // Get Audio Endpoint Volume
            if Succeeded(FDevice.Activate(IID_IAudioEndpointVolume, CLSCTX_ALL, nil, FAudioEndpointVolume)) then
            begin
              // Create Volume Callback Handler
              FVolumeCallbackHandler := TAudioEndpointVolumeCallbackHandler.Create(OnControlChangeNotify);

              // Register Volume Callback Handler
              if Succeeded(FAudioEndpointVolume.RegisterControlChangeNotify(FVolumeCallbackHandler)) then
              begin
                // Get Audio Endpoint Volume Properties
                Result := GetAudioEndpointVolumeProps;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TJalAudioDevice.SetDeviceDesc(const Value: string);
var
  LVariant: TPropVariant;
begin
  // Cast to Prop Variant
  if Succeeded(InitPropVariantFromString(PChar(Value), LVariant)) and
    Succeeded(FPropertyStore.SetValue(PKEY_Device_DeviceDesc, LVariant)) then
  begin
    // Commit Change..
    Succeeded(FPropertyStore.Commit);
  end;
end;

procedure TJalAudioDevice.SetMasterLevel(const Value: Single);
begin
  FAudioEndpointVolume.SetMasterVolumeLevelScalar(Value, nil);
end;

procedure TJalAudioDevice.SetMute(const Value: Boolean);
begin
  FAudioEndpointVolume.SetMute(Value, nil);
end;

function TJalAudioDevice.GetDeviceProps(const PropertyStore: IPropertyStore): Boolean;
var
  LPropInterfaceFriendlyName: TPropVariant;
  LPropDeviceDesc: TPropVariant;
  LPropFriendlyName: TPropVariant;
  LPropContainerId: TPropVariant;
begin
  Result := False;

  // Get All Properties
  // [ PKEY_Device_InstanceId ] is IMMDevice::GetId Value
  if (Succeeded(PropertyStore.GetValue(PKEY_DeviceInterface_FriendlyName, LPropInterfaceFriendlyName))) and
    (Succeeded(PropertyStore.GetValue(PKEY_Device_DeviceDesc, LPropDeviceDesc))) and
    (Succeeded(PropertyStore.GetValue(PKEY_Device_FriendlyName, LPropFriendlyName))) and
    (Succeeded(PropertyStore.GetValue(PKEY_Device_ContainerId, LPropContainerId))) then
  begin
    // Store Properties
    FInterfaceFriendlyName := LPropInterfaceFriendlyName.pwszVal;
    FDeviceDesc := LPropDeviceDesc.pwszVal;
    FFriendlyName := LPropFriendlyName.pwszVal;
    FContainerId := LPropContainerId.puuid^;

    Result := True;
  end;
end;

function TJalAudioDevice.GetAudioEndpointVolumeProps: Boolean;
var
  LChannelCount: DWORD;
  LMasterLevel: Single;
  LChannelLevel: Single;
  LChannelLevelList: TList<Single>;
  LMute: LongBool;
  LStep: DWORD;
  LStepCount: DWORD;
  LMin: Single;
  LMax: Single;
  LSpin: Single;
begin
  Result := False;

  // Get All Properties
  if (Succeeded(FAudioEndpointVolume.GetChannelCount(@LChannelCount))) and
    (Succeeded(FAudioEndpointVolume.GetMasterVolumeLevelScalar(@LMasterLevel))) and
    (Succeeded(FAudioEndpointVolume.GetMute(@LMute))) and
    (Succeeded(FAudioEndpointVolume.GetVolumeStepInfo(@LStep, @LStepCount))) and
    (Succeeded(FAudioEndpointVolume.GetVolumeRange(@LMin, @LMax, @LSpin))) then
  begin
    LChannelLevelList := TList<Single>.Create;

    try
      // Get All Channel Volume
      for var ii: DWORD := 0 to LChannelCount - 1 do
      begin
        if (Succeeded(FAudioEndpointVolume.GetChannelVolumeLevelScalar(ii, @LChannelLevel))) then
        begin
          // Add Value
          LChannelLevelList.Add(LChannelLevel);
        end;
      end;

      // Check Get All Channel Result
      if LChannelCount = DWORD(LChannelLevelList.Count) then
      begin
        // Store Properties
        FChannelCount := LChannelCount;
        FMasterLevel := LMasterLevel;
        FMute := LMute;
        FStep := LStep;
        FStepCount := LStepCount;
        FMin := LMin;
        FMax := LMax;
        FSpin := LSpin;

        Result := True;
      end;
    finally
      LChannelLevelList.Free;
    end;
  end;
end;

procedure TJalAudioDevice.OnControlChangeNotify(const Data: TAudioVolumeNotificationData);
begin
  FChannelCount := Data.Channels;

  if FMasterLevel <> Data.MasterVolume then
  begin
    FMasterLevel := Data.MasterVolume;

    if Assigned(FOnChangeMasterLevel) then
    begin
      FOnChangeMasterLevel(Round(FMasterLevel * 100)); // Callback
    end;
  end;

  if FMute <> Data.Muted then
  begin
    FMute := Data.Muted;

    if Assigned(FOnChangeMute) then
    begin
      FOnChangeMute(FMute); // Callback
    end;
  end;
end;

end.

