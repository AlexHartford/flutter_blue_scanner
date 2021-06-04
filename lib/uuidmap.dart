typedef Characteristic = String;
typedef UUID = String;

final uuidMap = <UUID, Characteristic>{
  wrap('180a'): 'Device Service',
  wrap('2a25'): 'Serial Number',
  wrap('2a28'): 'Software Version',
  wrap('2a29'): 'Manufacturer',
  wrap('2a11'): 'Date/Time',
  wrap('180f'): 'Battery Service',
  wrap('2a19'): 'Battery',
  wrap('181d'): 'Weight Service',
  wrap('2a9e'): 'Weight',
  wrap('2b46'): 'Units',
  '00005ac7-60be-11eb-ae93-0242ac130002': 'Actions Service',
  '0000007a-60be-11eb-ae93-0242ac130002': 'OTA trigger',
  '0000b007-60be-11eb-ae93-0242ac130002': 'Reboot trigger',
  '000000ff-60be-11eb-ae93-0242ac130002': 'Off',
  '0000551d-60be-11eb-ae93-0242ac130002': 'SSID',
  '0000fa55-60be-11eb-ae93-0242ac130002': 'Password',
};

UUID wrap(UUID unique) {
  return '0000$unique-0000-1000-8000-00805f9b34fb';
}
