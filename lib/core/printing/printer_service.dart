import 'dart:io';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:dartz/dartz.dart';
import '../error/failure.dart';

class PrinterService {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  Future<Either<Failure, void>> printViaNetwork(String ipAddress, int port, List<int> bytes) async {
    try {
      final socket = await Socket.connect(ipAddress, port, timeout: const Duration(seconds: 5));
      socket.add(bytes);
      await socket.flush();
      await socket.close();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to connect to network printer: $e'));
    }
  }

  Future<List<BluetoothDevice>> getBluetoothDevices() async {
    try {
      return await _bluetooth.getBondedDevices();
    } catch (e) {
      return [];
    }
  }

  Future<Either<Failure, void>> printViaBluetooth(BluetoothDevice device, List<int> bytes) async {
    try {
      final isConnected = await _bluetooth.isConnected;
      if (isConnected != true) {
        await _bluetooth.connect(device);
      }
      
      // We chunk the bytes because some bluetooth printers drop data if sent all at once
      const int chunkSize = 512;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        int end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        _bluetooth.writeBytes(Uint8List.fromList(bytes.sublist(i, end)));
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      await _bluetooth.disconnect();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to connect to bluetooth printer: $e'));
    }
  }
}
