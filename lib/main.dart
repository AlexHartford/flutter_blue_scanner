import 'dart:convert';

import 'package:ble_test/uuidmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:convert/convert.dart';

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ScanPage(),
    );
  }
}

final bluetooth = Provider<FlutterBlue>((_) => FlutterBlue.instance);

final AutoDisposeFutureProvider<List<BluetoothDevice>>? connectedDevices =
    FutureProvider.autoDispose<List<BluetoothDevice>>(
  (ref) => ref.watch(bluetooth).connectedDevices,
);

class Scanning extends StateNotifier<bool> {
  final Reader _read;

  Scanning(this._read) : super(false) {
    _read(bluetooth).isScanning.listen((bool scanning) {
      state = scanning;
    });
  }
}

final scannedDevices = StreamProvider<List<BluetoothDevice>>(
  (ref) => ref.watch(bluetooth).scanResults.map(
        (results) => results
            .map((result) => result.device)
            .where((device) => device.name.isNotEmpty)
            .toList(),
      ),
);

final scanning = StateNotifierProvider<Scanning, bool>((ref) => Scanning(ref.read));

class ScanPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ConnectedDevicesSection(),
            ScannedDevicesSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => context.read(scanning)
            ? await context.read(bluetooth).stopScan()
            : await context.read(bluetooth).startScan(),
        child: Icon(useProvider(scanning) ? Icons.bluetooth_searching : Icons.bluetooth_disabled),
      ),
    );
  }
}

class ConnectedDevicesSection extends HookWidget {
  const ConnectedDevicesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Connected Devices'),
        ),
        useProvider(connectedDevices!).when(
          data: (devices) => ListView.builder(
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            itemCount: devices.length,
            itemBuilder: (_, index) => Card(
              color: devices[index].name == '01136B' ? Colors.blue[100] : null,
              child: ListTile(
                title: Text('${devices[index].name}\n${devices[index].id}'),
                onTap: () {
                  context.read(connectedDevice).state = devices[index];
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => DevicePage()));
                },
              ),
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, stack) => Text(
            err.toString(),
          ),
        ),
      ],
    );
  }
}

class ScannedDevicesSection extends HookWidget {
  const ScannedDevicesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Scanned Devices'),
        ),
        useProvider(scannedDevices).when(
          data: (devices) {
            return ListView.builder(
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              itemCount: devices.length,
              itemBuilder: (_, index) => Card(
                // color: devices[index].name == '01136B' ? Colors.blue[100] : null,
                color: devices[index].name == 'SudoBoard' ? Colors.blue[100] : null,
                child: ListTile(
                  title: Text('${devices[index].name}\n${devices[index].id}'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(primary: Colors.blue),
                    child: Text(
                      'CONNECT',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await devices[index].connect();
                        context.read(connectedDevice).state = devices[index];
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => DevicePage()));
                      } on PlatformException catch (e) {
                        if (e.code != 'already_connected') {
                          throw e;
                        }
                        context.read(connectedDevice).state = devices[index];
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => DevicePage()));
                      } catch (e) {
                        print('Error connecting: $e');
                      }
                    },
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, stack) => Text(
            err.toString(),
          ),
        ),
      ],
    );
  }
}

final connectedDevice = StateProvider<BluetoothDevice?>((_) => null);

final services = FutureProvider<List<BluetoothService>>(
  (ref) => ref.watch(connectedDevice).state!.discoverServices(),
);

class DevicePage extends HookWidget {
  const DevicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final device = useProvider(connectedDevice).state!;

    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: [
          TextButton(
            onPressed: () async {
              await device.disconnect();
              Navigator.of(context).pop();
            },
            child: Text(
              'DISCONNECT',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Services'),
          ),
          useProvider(services).when(
            data: (services) {
              return ListView.builder(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                itemCount: services.length,
                itemBuilder: (_, index) => Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                            uuidMap[services[index].uuid.toString()] ?? '${services[index].uuid}'),
                        subtitle: Text(
                          '${services[index].characteristics.length.toString()} characteristic(s)',
                        ),
                      ),
                      ...List.generate(
                        services[index].characteristics.length,
                        (i) => CharacteristicInfo(services[index].characteristics[i], i),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Text(
              err.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

final AutoDisposeStreamProviderFamily<List<int>, BluetoothCharacteristic>? characteristicValue =
    StreamProvider.autoDispose.family<List<int>, BluetoothCharacteristic>((ref, char) {
  return char.value;
});

class CharacteristicInfo extends HookWidget {
  CharacteristicInfo(this.char, int index, {Key? key})
      : this.color = Colors.blue[index > 0 ? index * 100 : 50],
        super(key: key);

  final BluetoothCharacteristic char;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    char.value.listen((value) {
      print('char value: $value');
    });
    return useProvider(characteristicValue!(char)).when(
      data: (data) {
        final decoded = Utf8Decoder().convert(data);
        return ListTile(
          tileColor: color,
          title: Text(
            '${uuidMap[char.uuid.toString()] ?? char.uuid.toString()} - $decoded',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: CharButtons(char),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Text(
        err.toString(),
      ),
    );
  }
}

class CharButtons extends HookWidget {
  const CharButtons(this.char, {Key? key}) : super(key: key);

  final BluetoothCharacteristic char;

  @override
  Widget build(BuildContext context) {
    List<ButtonTheme> buttons = [];

    if (char.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(primary: Colors.amber[800]),
              child: Text('READ', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await char.read();
              },
            ),
          ),
        ),
      );
    }
    if (char.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(primary: Colors.deepOrange),
              child: Text('WRITE', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final encoded = Utf8Encoder().convert('06-04-2021');
                await char.write(encoded);
              },
            ),
          ),
        ),
      );
    }
    if (char.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(primary: Colors.red),
              child: Text('NOTIFY', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await char.setNotifyValue(!char.isNotifying);
              },
            ),
          ),
        ),
      );
    }

    return Row(
      children: buttons,
    );
  }
}
