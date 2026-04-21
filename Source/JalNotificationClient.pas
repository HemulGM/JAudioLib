unit JalNotificationClient;

interface

uses
  System.SysUtils, Winapi.Windows, Winapi.ActiveX, Jal.Win.MMDeviceAPI;

type
  TOnDefaultDeviceChanged = procedure(const Flow: TDataFlow; const Role: TRole; const DeviceId: PWideChar) of object;

  TJalNotificationClient = class(TInterfacedObject, IMMNotificationClient)
  private
    FDeviceId: string;
    FFlow: TDataFlow;
    FRole: TRole;
    FOnDefaultDeviceChanged: TOnDefaultDeviceChanged;
  public
    constructor Create(const DeviceId: string; const Flow: TDataFlow; const Role: TRole; const OnDefaultDeviceChanged: TOnDefaultDeviceChanged);
    destructor Destroy; override;

    function OnDefaultDeviceChanged(Flow: TDataFlow; Role: TRole; DefaultDeviceId: PWideChar): HResult; stdcall;
    function OnDeviceAdded(DeviceId: PWideChar): HResult; stdcall;
    function OnDeviceRemoved(DeviceId: PWideChar): HResult; stdcall;
    function OnDeviceStateChanged(DeviceId: PWideChar; NewState: DWORD): HResult; stdcall;
    function OnPropertyValueChanged(DeviceId: PWideChar; key: PROPERTYKEY): HResult; stdcall;
  end;

implementation

{ TNotificationClient }

constructor TJalNotificationClient.Create(const DeviceId: string; const Flow: TDataFlow; const Role: TRole; const OnDefaultDeviceChanged: TOnDefaultDeviceChanged);
begin
  FDeviceId := DeviceId;
  FFlow := Flow;
  FRole := Role;
  FOnDefaultDeviceChanged := OnDefaultDeviceChanged;
end;

destructor TJalNotificationClient.Destroy;
begin
  inherited;
end;

function TJalNotificationClient.OnDefaultDeviceChanged(Flow: TDataFlow; Role: TRole; DefaultDeviceId: PWideChar): HResult;
begin
  if (Assigned(FOnDefaultDeviceChanged)) and (Flow = FFlow) and (Role = FRole) then
  begin
    FOnDefaultDeviceChanged(Flow, Role, DefaultDeviceId); // Callback
  end;

  Result := S_OK;
end;

function TJalNotificationClient.OnDeviceAdded(DeviceId: PWideChar): HResult;
begin
  Result := S_OK;
end;

function TJalNotificationClient.OnDeviceRemoved(DeviceId: PWideChar): HResult;
begin
  Result := S_OK;
end;

function TJalNotificationClient.OnDeviceStateChanged(DeviceId: PWideChar; NewState: DWORD): HResult;
begin
  Result := S_OK;
end;

function TJalNotificationClient.OnPropertyValueChanged(DeviceId: PWideChar; Key: PROPERTYKEY): HResult;
begin
  Result := S_OK;
end;

end.

