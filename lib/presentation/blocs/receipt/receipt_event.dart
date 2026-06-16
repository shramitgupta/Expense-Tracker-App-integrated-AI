import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ReceiptEvent extends Equatable {
  const ReceiptEvent();

  @override
  List<Object?> get props => [];
}

class ScanReceipt extends ReceiptEvent {
  final File imageFile;
  const ScanReceipt(this.imageFile);

  @override
  List<Object?> get props => [imageFile.path];
}

class ResetReceipt extends ReceiptEvent {
  const ResetReceipt();
}
