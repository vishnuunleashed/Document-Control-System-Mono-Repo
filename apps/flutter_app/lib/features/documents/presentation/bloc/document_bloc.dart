import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/document_repository.dart';
import '../../data/models/document_model.dart';
import '../../data/datasources/local/sync_queue_item.dart';

// --- Events ---
abstract class DocumentEvent {}

class FetchDocuments extends DocumentEvent {
  final String? status;
  final String? search;
  FetchDocuments({this.status, this.search});
}

class UploadDocumentRequested extends DocumentEvent {
  final String title;
  final String description;
  final String filePath;
  final Uint8List? fileBytes;
  final String? fileName;
  UploadDocumentRequested({
    required this.title,
    required this.description,
    required this.filePath,
    this.fileBytes,
    this.fileName,
  });
}

class DeleteDocumentRequested extends DocumentEvent {
  final String id;
  DeleteDocumentRequested(this.id);
}

class SyncOfflineQueueRequested extends DocumentEvent {}

// --- States ---
abstract class DocumentState {}

class DocumentInitial extends DocumentState {}

class DocumentLoading extends DocumentState {}

class DocumentsLoaded extends DocumentState {
  final List<DocumentModel> documents;
  final List<SyncQueueItem> queue;
  DocumentsLoaded(this.documents, this.queue);
}

class DocumentUploadSuccess extends DocumentState {
  final DocumentModel document;
  DocumentUploadSuccess(this.document);
}

class DocumentFailure extends DocumentState {
  final String error;
  DocumentFailure(this.error);
}

// --- Bloc ---
class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final DocumentRepository _documentRepository;

  DocumentBloc(this._documentRepository) : super(DocumentInitial()) {
    on<FetchDocuments>(_onFetchDocuments);
    on<UploadDocumentRequested>(_onUploadDocumentRequested);
    on<DeleteDocumentRequested>(_onDeleteDocumentRequested);
    on<SyncOfflineQueueRequested>(_onSyncOfflineQueueRequested);
  }

  Future<void> _onFetchDocuments(FetchDocuments event, Emitter<DocumentState> emit) async {
    emit(DocumentLoading());
    try {
      final docs = await _documentRepository.getDocuments(
        status: event.status,
        search: event.search,
      );
      final queue = await _documentRepository.getOfflineQueue();
      emit(DocumentsLoaded(docs, queue));
    } catch (e) {
      emit(DocumentFailure(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onUploadDocumentRequested(
    UploadDocumentRequested event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentLoading());
    try {
      final doc = await _documentRepository.uploadDocument(
        event.title,
        event.description,
        event.filePath,
        fileBytes: event.fileBytes,
        fileName: event.fileName,
      );
      emit(DocumentUploadSuccess(doc));
    } catch (e) {
      emit(DocumentFailure(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onDeleteDocumentRequested(
    DeleteDocumentRequested event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentLoading());
    try {
      await _documentRepository.deleteDocument(event.id);
      add(FetchDocuments());
    } catch (e) {
      emit(DocumentFailure(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onSyncOfflineQueueRequested(
    SyncOfflineQueueRequested event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await _documentRepository.syncOfflineQueue();
      add(FetchDocuments());
    } catch (e) {
      // Sync engine failure shouldn't crash the main load flow
    }
  }
}
