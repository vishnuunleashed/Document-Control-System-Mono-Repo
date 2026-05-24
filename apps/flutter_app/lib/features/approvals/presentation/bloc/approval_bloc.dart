import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/approval_repository.dart';
import '../../data/models/audit_log_model.dart';

// --- Events ---
abstract class ApprovalEvent {}

class FetchAuditLogs extends ApprovalEvent {
  final String documentId;
  FetchAuditLogs(this.documentId);
}

class SubmitDocumentWorkflow extends ApprovalEvent {
  final String documentId;
  final String? comments;
  SubmitDocumentWorkflow(this.documentId, {this.comments});
}

class ReviewDocumentWorkflow extends ApprovalEvent {
  final String documentId;
  final String? comments;
  ReviewDocumentWorkflow(this.documentId, {this.comments});
}

class ActionDocumentWorkflow extends ApprovalEvent {
  final String documentId;
  final String action; // Approved, Rejected
  final String comments;
  ActionDocumentWorkflow({
    required this.documentId,
    required this.action,
    required this.comments,
  });
}

// --- States ---
abstract class ApprovalState {}

class ApprovalInitial extends ApprovalState {}

class ApprovalLoading extends ApprovalState {}

class AuditLogsLoaded extends ApprovalState {
  final List<AuditLogModel> logs;
  AuditLogsLoaded(this.logs);
}

class ApprovalActionSuccess extends ApprovalState {
  final String message;
  ApprovalActionSuccess(this.message);
}

class ApprovalFailure extends ApprovalState {
  final String error;
  ApprovalFailure(this.error);
}

// --- Bloc ---
class ApprovalBloc extends Bloc<ApprovalEvent, ApprovalState> {
  final ApprovalRepository _approvalRepository;

  ApprovalBloc(this._approvalRepository) : super(ApprovalInitial()) {
    on<FetchAuditLogs>(_onFetchAuditLogs);
    on<SubmitDocumentWorkflow>(_onSubmitDocumentWorkflow);
    on<ReviewDocumentWorkflow>(_onReviewDocumentWorkflow);
    on<ActionDocumentWorkflow>(_onActionDocumentWorkflow);
  }

  Future<void> _onFetchAuditLogs(FetchAuditLogs event, Emitter<ApprovalState> emit) async {
    emit(ApprovalLoading());
    try {
      final logs = await _approvalRepository.getAuditLogs(event.documentId);
      emit(AuditLogsLoaded(logs));
    } catch (e) {
      emit(ApprovalFailure(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onSubmitDocumentWorkflow(
    SubmitDocumentWorkflow event,
    Emitter<ApprovalState> emit,
  ) async {
    emit(ApprovalLoading());
    try {
      await _approvalRepository.submitDocument(event.documentId, comments: event.comments);
      emit(ApprovalActionSuccess("Document submitted successfully"));
    } catch (e) {
      emit(ApprovalFailure(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onReviewDocumentWorkflow(
    ReviewDocumentWorkflow event,
    Emitter<ApprovalState> emit,
  ) async {
    emit(ApprovalLoading());
    try {
      await _approvalRepository.reviewDocument(event.documentId, comments: event.comments);
      emit(ApprovalActionSuccess("Document is now under review"));
    } catch (e) {
      emit(ApprovalFailure(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onActionDocumentWorkflow(
    ActionDocumentWorkflow event,
    Emitter<ApprovalState> emit,
  ) async {
    emit(ApprovalLoading());
    try {
      await _approvalRepository.actionDocument(
        event.documentId,
        event.action,
        event.comments,
      );
      emit(ApprovalActionSuccess("Document status updated to ${event.action}"));
    } catch (e) {
      emit(ApprovalFailure(e.toString().replaceAll("Exception: ", "")));
    }
  }
}
