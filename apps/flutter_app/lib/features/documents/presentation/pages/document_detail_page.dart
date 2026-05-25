import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_app/features/documents/data/models/document_model.dart';
import 'package:flutter_app/features/documents/presentation/bloc/document_bloc.dart';
import 'package:flutter_app/features/approvals/data/models/audit_log_model.dart';
import 'package:flutter_app/features/approvals/presentation/bloc/approval_bloc.dart';
import 'package:flutter_app/app/di/dependency_injection.dart';
import 'package:flutter_app/shared/services/session_manager.dart';

class DocumentDetailPage extends StatefulWidget {
  final String documentId;
  const DocumentDetailPage({super.key, required this.documentId});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  final _commentController = TextEditingController();
  final _editFormKey = GlobalKey<FormState>();
  final _editTitleController = TextEditingController();
  final _editDescController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    _editTitleController.dispose();
    _editDescController.dispose();
    super.dispose();
  }

  void _loadDocumentData(BuildContext context) {
    context.read<DocumentBloc>().add(FetchDocuments());
    context.read<ApprovalBloc>().add(FetchAuditLogs(widget.documentId));
  }

  void _showActionDialog({
    required BuildContext context,
    required String title,
    required String confirmText,
    required Color buttonColor,
    required Function(String comments) onConfirm,
    bool commentRequired = false,
  }) {
    _commentController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _commentController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: commentRequired ? "Enter mandatory comments..." : "Enter comments (optional)...",
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("CANCEL", style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () {
                final comments = _commentController.text.trim();
                if (commentRequired && comments.length < 3) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text("Comments must be at least 3 characters long")),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                onConfirm(comments);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, DocumentModel doc, DocumentBloc docBloc) {
    _editTitleController.text = doc.title;
    _editDescController.text = doc.description;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Edit Metadata", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Form(
            key: _editFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _editTitleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Document Title", labelStyle: TextStyle(color: Colors.white70)),
                  validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _editDescController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Description", labelStyle: TextStyle(color: Colors.white70)),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("CANCEL", style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () {
                if (!_editFormKey.currentState!.validate()) return;
                Navigator.pop(dialogContext);
                DependencyInjection.documentRepository
                    .updateDocument(doc.id, _editTitleController.text.trim(), _editDescController.text.trim())
                    .then((_) {
                  _loadDocumentData(context);
                }).catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<DocumentBloc>(
          create: (context) => DocumentBloc(DependencyInjection.documentRepository)..add(FetchDocuments()),
        ),
        BlocProvider<ApprovalBloc>(
          create: (context) => ApprovalBloc(DependencyInjection.approvalRepository)..add(FetchAuditLogs(widget.documentId)),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<ApprovalBloc, ApprovalState>(
            listener: (context, state) {
              if (state is ApprovalActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: const Color(0xFF10B981)),
                );
                _loadDocumentData(context);
              } else if (state is ApprovalFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error), backgroundColor: theme.colorScheme.error),
                );
              }
            },
          ),
        ],
        child: Builder(
          builder: (context) {
            return Scaffold(
              backgroundColor: const Color(0xFF0F172A),
              appBar: AppBar(
                backgroundColor: const Color(0xFF1E293B),
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Text("Document Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              body: BlocBuilder<DocumentBloc, DocumentState>(
                builder: (context, state) {
                  if (state is DocumentLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
                  }

                  // Find our document
                  DocumentModel? document;
                  if (state is DocumentsLoaded) {
                    try {
                      document = state.documents.firstWhere((d) => d.id == widget.documentId);
                    } catch (_) {}
                  }

                  if (document == null) {
                    return const Center(
                      child: Text("Document not found in local cache", style: TextStyle(color: Colors.white)),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Workflow progress stepper visual
                        _buildWorkflowStepper(document.status),
                        const SizedBox(height: 20),

                        // Document details card
                        _buildDetailsCard(document, context),
                        const SizedBox(height: 20),

                        // Actions Panel
                        _buildActionsPanel(context, document),
                        const SizedBox(height: 24),

                        // Audit Log History Timeline
                        _buildAuditTimelineHeader(),
                        const SizedBox(height: 12),
                        _buildAuditTimeline(context),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWorkflowStepper(String currentStatus) {
    final stages = ["Draft", "Submitted", "Under Review", "Approved"];
    final isRejected = currentStatus == "Rejected";
    
    int activeIndex = stages.indexOf(currentStatus);
    if (isRejected) activeIndex = 2; // Position around Under Review

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "WORKFLOW PROCESS",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(stages.length, (index) {
              final stage = stages[index];
              bool isPassed = activeIndex >= index;
              bool isActive = stage == currentStatus;
              
              Color dotColor = const Color(0xFF334155);
              if (isActive) {
                dotColor = isRejected ? const Color(0xFFEF4444) : const Color(0xFF2563EB);
              } else if (isPassed) {
                dotColor = const Color(0xFF10B981);
              }

              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: dotColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: dotColor, width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              isRejected && isActive
                                  ? Icons.close
                                  : isPassed && !isActive
                                      ? Icons.check
                                      : Icons.circle,
                              size: 14,
                              color: dotColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isRejected && isActive ? "Rejected" : stage,
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : isPassed
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (index < stages.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: activeIndex > index ? const Color(0xFF10B981) : const Color(0xFF334155),
                          margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(DocumentModel doc, BuildContext context) {
    final bytes = doc.fileSize;
    final formattedSize = _formatSize(bytes);
    final date = DateFormat('MMM dd, yyyy HH:mm').format(doc.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  doc.title,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () async {
                  if (doc.fileUrl.isEmpty || doc.fileUrl == "web-file") {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("File URL is not available")),
                    );
                    return;
                  }
                  final url = Uri.parse(doc.fileUrl);
                  try {
                    final success = await launchUrl(url);
                    if (!success) {
                      throw Exception("Launch failed");
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Could not open file URL: ${doc.fileUrl}"),
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.file_download, color: Color(0xFF3B82F6)),
                tooltip: "Open / Download File",
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            doc.description.isEmpty ? "No description provided." : doc.description,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
          const SizedBox(height: 16),
          // View Document Button
          InkWell(
            onTap: () async {
              if (doc.fileUrl.isEmpty || doc.fileUrl == "web-file") {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("File URL is not available")),
                );
                return;
              }
              final url = Uri.parse(doc.fileUrl);
              try {
                final success = await launchUrl(url);
                if (!success) {
                  throw Exception("Launch failed");
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Could not open file URL: ${doc.fileUrl}"),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3B82F6), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new, color: Color(0xFF3B82F6), size: 18),
                  SizedBox(width: 8),
                  Text(
                    "View / Open Uploaded File",
                    style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 32),
          _buildDetailRow("File Name", doc.fileName),
          _buildDetailRow("File Size", formattedSize),
          _buildDetailRow("MIME Type", doc.mimeType),
          _buildDetailRow("Version", "v${doc.version}.0"),
          _buildDetailRow("Author", "${doc.uploadedByUserName} (${doc.uploadedByUserRole})"),
          _buildDetailRow("Uploaded On", date),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsPanel(BuildContext context, DocumentModel doc) {
    final role = SessionManager.userRole;
    final isOwner = doc.uploadedByUserId == SessionManager.userId;
    final status = doc.status;
    final approvalBloc = context.read<ApprovalBloc>();
    final docBloc = context.read<DocumentBloc>();

    List<Widget> actionButtons = [];

    if (isOwner || role == 'Admin') {
      if (status == 'Draft' || status == 'Rejected') {
        actionButtons.add(
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _showActionDialog(
                  context: context,
                  title: "Submit for Review",
                  confirmText: "SUBMIT",
                  buttonColor: const Color(0xFF2563EB),
                  onConfirm: (comments) {
                    approvalBloc.add(SubmitDocumentWorkflow(doc.id, comments: comments));
                  },
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              icon: const Icon(Icons.send_outlined),
              label: const Text("Submit"),
            ),
          ),
        );
        actionButtons.add(const SizedBox(width: 12));
        actionButtons.add(
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showEditDialog(context, doc, docBloc),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF94A3B8),
                side: const BorderSide(color: Color(0xFF334155)),
              ),
              icon: const Icon(Icons.mode_edit_outlined),
              label: const Text("Edit"),
            ),
          ),
        );
      }
    }

    if ((role == 'Reviewer' || role == 'Admin') && status == 'Submitted') {
      actionButtons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showActionDialog(
                context: context,
                title: "Mark as Under Review",
                confirmText: "START REVIEW",
                buttonColor: const Color(0xFF8B5CF6),
                onConfirm: (comments) {
                  approvalBloc.add(ReviewDocumentWorkflow(doc.id, comments: comments));
                },
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
            icon: const Icon(Icons.play_arrow_outlined),
            label: const Text("Start Review"),
          ),
        ),
      );
    }

    if ((role == 'Approver' || role == 'Admin') && status == 'Under Review') {
      actionButtons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showActionDialog(
                context: context,
                title: "Approve Document",
                confirmText: "APPROVE",
                buttonColor: const Color(0xFF10B981),
                commentRequired: true,
                onConfirm: (comments) {
                  approvalBloc.add(ActionDocumentWorkflow(documentId: doc.id, action: "Approved", comments: comments));
                },
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            icon: const Icon(Icons.check),
            label: const Text("Approve"),
          ),
        ),
      );
      actionButtons.add(const SizedBox(width: 12));
      actionButtons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showActionDialog(
                context: context,
                title: "Reject Document",
                confirmText: "REJECT",
                buttonColor: const Color(0xFFEF4444),
                commentRequired: true,
                onConfirm: (comments) {
                  approvalBloc.add(ActionDocumentWorkflow(documentId: doc.id, action: "Rejected", comments: comments));
                },
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            icon: const Icon(Icons.close),
            label: const Text("Reject"),
          ),
        ),
      );
    }

    if (actionButtons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: Color(0xFF64748B), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getWorkflowStatusMessage(status),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Row(children: actionButtons);
  }

  String _getWorkflowStatusMessage(String status) {
    if (status == 'Approved') return "This document has been fully approved and is locked.";
    if (status == 'Submitted') return "Awaiting review. Only designated Reviewers or Administrators can start review.";
    if (status == 'Under Review') return "Under review. Only designated Approvers or Administrators can sign off.";
    return "Locked in current state.";
  }

  Widget _buildAuditTimelineHeader() {
    return const Text(
      "DOCUMENT WORKFLOW LOGS",
      style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
    );
  }

  Widget _buildAuditTimeline(BuildContext context) {
    return BlocBuilder<ApprovalBloc, ApprovalState>(
      builder: (context, state) {
        if (state is ApprovalLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
        }

        List<AuditLogModel> logs = [];
        if (state is AuditLogsLoaded) {
          logs = state.logs;
        }

        if (logs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text("No workflow logs available.", style: TextStyle(color: Color(0xFF475569))),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final time = DateFormat('MMM dd, yyyy HH:mm').format(log.timestamp);
            
            Color iconColor = Colors.grey;
            IconData icon = Icons.circle;
            if (log.action == 'Create') { iconColor = const Color(0xFF2563EB); icon = Icons.cloud_upload_outlined; }
            else if (log.action == 'Update') { iconColor = const Color(0xFF94A3B8); icon = Icons.edit_note_outlined; }
            else if (log.action == 'Submit') { iconColor = const Color(0xFF3B82F6); icon = Icons.send_outlined; }
            else if (log.action == 'Review') { iconColor = const Color(0xFF8B5CF6); icon = Icons.play_arrow_outlined; }
            else if (log.action == 'Approve') { iconColor = const Color(0xFF10B981); icon = Icons.check_circle_outline; }
            else if (log.action == 'Reject') { iconColor = const Color(0xFFEF4444); icon = Icons.close_outlined; }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: iconColor, width: 2),
                        ),
                        child: Center(child: Icon(icon, color: iconColor, size: 16)),
                      ),
                      if (index < logs.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: const Color(0xFF334155),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log.action.toUpperCase(),
                              style: TextStyle(color: iconColor, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(time, style: const TextStyle(color: Color(0xFF475569), fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            children: [
                              const TextSpan(text: "By "),
                              TextSpan(
                                text: log.performedByUserName,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              TextSpan(text: " (${log.performedByUserRole})"),
                            ],
                          ),
                        ),
                        if (log.comments.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              log.comments,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    final kb = bytes / 1024;
    if (kb < 1024) return "${kb.toStringAsFixed(1)} KB";
    final mb = kb / 1024;
    return "${mb.toStringAsFixed(1)} MB";
  }
}
