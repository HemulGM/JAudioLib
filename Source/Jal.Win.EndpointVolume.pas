unit Jal.Win.EndpointVolume;

interface

uses
  Winapi.Windows;

const
  IID_IAudioEndpointVolume: TGUID = '{5CDF2C82-841E-4546-9722-0CF74078229A}';

type
  TAudioVolumeNotificationData = record
    EventContext: TGUID;
    Muted: BOOL;
    MasterVolume: Single;
    Channels: DWORD;
    ChannelVolumes: Single;
  end;

  IAudioEndpointVolumeCallback = interface(IUnknown)
    ['{657804FA-D6AD-4496-8A60-352752AF4F89}']
    function OnNotify(Notify: TAudioVolumeNotificationData): HRESULT; stdcall;
  end;

  IAudioEndpointVolume = interface(IUnknown)
    ['{5CDF2C82-841E-4546-9722-0CF74078229A}']
    function RegisterControlChangeNotify(Notify: IAudioEndpointVolumeCallback): HRESULT; stdcall;
    function UnregisterControlChangeNotify(Notify: IAudioEndpointVolumeCallback): HRESULT; stdcall;
    function GetChannelCount(ChannelCount: PDWORD): HRESULT; stdcall;
    function SetMasterVolumeLevel(LevelDB: Single; EventContext: PGUID): HRESULT; stdcall;
    function SetMasterVolumeLevelScalar(LevelDB: Single; EventContext: PGUID): HRESULT; stdcall;
    function GetMasterVolumeLevel(out LevelDB: Single): HRESULT; stdcall;
    function GetMasterVolumeLevelScalar(Level: PSingle): HRESULT; stdcall;
    function SetChannelVolumeLevel(Channel: DWORD; LevelDB: Single; EventContext: PGUID): HRESULT; stdcall;
    function SetChannelVolumeLevelScalar(Channel: DWORD; Level: Single; EventContext: PGUID): HRESULT; stdcall;
    function GetChannelVolumeLevel(Channel: Integer; LevelDB: PSingle): HRESULT; stdcall;
    function GetChannelVolumeLevelScalar(Channel: DWORD; Level: PSingle): HRESULT; stdcall;
    function SetMute(Mute: BOOL; EventContext: PGUID): HRESULT; stdcall;
    function GetMute(Mute: PBOOL): HRESULT; stdcall;
    function GetVolumeStepInfo(Step: PDWORD; StepCount: PDWORD): HRESULT; stdcall;
    function VolumeStepUp(EventContext: PGUID): HRESULT; stdcall;
    function VolumeStepDown(EventContext: PGUID): HRESULT; stdcall;
    function QueryHardwareSupport(HardwareSupportMask: PDWORD): HRESULT; stdcall;
    function GetVolumeRange(VolumeMindB: PSingle; VolumeMaxdB: PSingle; VolumeIncrementdB: PSingle): HRESULT; stdcall;
  end;

implementation

end.

