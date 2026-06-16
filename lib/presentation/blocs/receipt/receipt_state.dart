import 'package:equatable/equatable.dart';
import '../../../core/services/gemini_service.dart';

abstract class ReceiptState extends Equatable {
  const ReceiptState();

  @override
  List<Object?> get props => [];
}

class ReceiptInitial extends ReceiptState {
  const ReceiptInitial();
}

class ReceiptLoading extends ReceiptState {
  const ReceiptLoading();
}

class ReceiptSuccess extends ReceiptState {
  final ReceiptData receiptData;
  const ReceiptSuccess(this.receiptData);

  @override
  List<Object?> get props => [receiptData];
}

class ReceiptFailure extends ReceiptState {
  final String message;
  const ReceiptFailure(this.message);

  @override
  List<Object?> get props => [message];
}
