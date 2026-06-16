import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/extract_receipt.dart';
import '../../../core/errors/exceptions.dart';
import 'receipt_event.dart';
import 'receipt_state.dart';

class ReceiptBloc extends Bloc<ReceiptEvent, ReceiptState> {
  final ExtractReceipt extractReceipt;

  ReceiptBloc({required this.extractReceipt}) : super(const ReceiptInitial()) {
    on<ScanReceipt>(_onScanReceipt);
    on<ResetReceipt>(_onResetReceipt);
  }

  Future<void> _onScanReceipt(
    ScanReceipt event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(const ReceiptLoading());
    try {
      final receiptData = await extractReceipt(event.imageFile);
      emit(ReceiptSuccess(receiptData));
    } on AIExtractionException catch (e) {
      emit(ReceiptFailure(e.message));
    } catch (e) {
      emit(ReceiptFailure(
        'Could not extract receipt information. Please review manually.',
      ));
    }
  }

  void _onResetReceipt(
    ResetReceipt event,
    Emitter<ReceiptState> emit,
  ) {
    emit(const ReceiptInitial());
  }
}
