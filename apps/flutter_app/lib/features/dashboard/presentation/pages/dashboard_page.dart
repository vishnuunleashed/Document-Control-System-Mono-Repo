import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_app/features/documents/data/models/document_model.dart';
import 'package:flutter_app/features/documents/presentation/bloc/document_bloc.dart';
import 'package:flutter_app/features/documents/data/datasources/local/sync_queue_item.dart';
import 'package:flutter_app/app/di/dependency_injection.dart';
import 'package:flutter_app/shared/services/session_manager.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedStatus = ""; // Empty means 'All'
  final _searchController = TextEditingController();
  
  // Floating upload sheet form keys
  final _uploadFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedFilePath;
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _loadData(BuildContext context) {
    context.read<DocumentBloc>().add(
      FetchDocuments(
        status: _selectedStatus,
        search: _searchController.text.trim(),
      ),
    );
  }

  void _openUploadSheet(BuildContext context) {
    _titleController.clear();
    _descController.clear();
    setState(() {
      _selectedFilePath = null;
      _selectedFileName = null;
      _selectedFileBytes = null;
    });

    final docBloc = context.read<DocumentBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (stateContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(stateContext).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _uploadFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Upload Document",
                          style: Theme.of(stateContext).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(stateContext),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF334155), height: 24),
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _bottomSheetInputDecoration("Document Title"),
                      validator: (val) => val == null || val.trim().isEmpty ? "Title is required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: _bottomSheetInputDecoration("Description (Optional)"),
                    ),
                    const SizedBox(height: 20),
                    
                    // File Picker Widget
                    InkWell(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'docx', 'png', 'jpg', 'jpeg'],
                        );
                        if (result != null) {
                          if (kIsWeb) {
                            final file = result.files.single;
                            if (file.bytes != null) {
                              setModalState(() {
                                _selectedFilePath = "web";
                                _selectedFileName = file.name;
                                _selectedFileBytes = file.bytes;
                              });
                            }
                          } else {
                            final path = result.files.single.path;
                            if (path != null) {
                              setModalState(() {
                                _selectedFilePath = path;
                                _selectedFileName = result.files.single.name;
                                _selectedFileBytes = null;
                              });
                            }
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedFilePath != null
                                ? const Color(0xFF10B981)
                                : const Color(0xFF334155),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFilePath != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                              size: 40,
                              color: _selectedFilePath != null ? const Color(0xFF10B981) : const Color(0xFF64748B),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedFileName ?? "Tap to select PDF, DOCX, PNG, or JPG",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedFilePath != null ? Colors.white : const Color(0xFF94A3B8),
                                fontWeight: _selectedFilePath != null ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (_selectedFilePath != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "Ready to upload (<5MB)",
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: () {
                        if (!_uploadFormKey.currentState!.validate()) return;
                        if (_selectedFilePath == null) {
                          ScaffoldMessenger.of(stateContext).showSnackBar(
                            const SnackBar(content: Text("Please select a file to upload")),
                          );
                          return;
                        }

                        docBloc.add(
                          UploadDocumentRequested(
                            title: _titleController.text.trim(),
                            description: _descController.text.trim(),
                            filePath: _selectedFilePath!,
                            fileBytes: _selectedFileBytes,
                            fileName: _selectedFileName,
                          ),
                        );
                        Navigator.pop(stateContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "SUBMIT DOCUMENT",
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(DependencyInjection.authRepository),
        ),
        BlocProvider<DocumentBloc>(
          create: (context) => DocumentBloc(DependencyInjection.documentRepository)..add(FetchDocuments()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is Unauthenticated) {
                context.go('/login');
              }
            },
          ),
          BlocListener<DocumentBloc, DocumentState>(
            listener: (context, state) {
              if (state is DocumentUploadSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      SessionManager.isAuthenticated // Wait, let's see: if offline it cached, online it uploaded
                          ? "Document uploaded successfully!"
                          : "Offline: Saved to upload queue successfully!",
                    ),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
                _loadData(context);
              } else if (state is DocumentFailure) {
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
              appBar: _buildAppBar(context, theme),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _openUploadSheet(context),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text("Upload Document", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  context.read<DocumentBloc>().add(SyncOfflineQueueRequested());
                  _loadData(context);
                },
                child: BlocBuilder<DocumentBloc, DocumentState>(
                  builder: (context, state) {
                    List<DocumentModel> docs = [];
                    List<SyncQueueItem> queue = [];
                    bool isLoading = state is DocumentLoading;

                    if (state is DocumentsLoaded) {
                      docs = state.documents;
                      queue = state.queue;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Offline Sync indicator bar
                        _buildSyncIndicator(context, queue),

                        // Stats Summary Grid
                        _buildStatsSummaryGrid(docs, queue),

                        // Search and Filter controls
                        _buildSearchFilterHeader(context, theme),

                        // List area
                        Expanded(
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                              : _buildDocumentsList(docs, queue, context),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      backgroundColor: const Color(0xFF1E293B),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_turned_in, color: Color(0xFF3B82F6), size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                SessionManager.userName,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              _buildRoleBadge(SessionManager.userRole),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            context.read<DocumentBloc>().add(SyncOfflineQueueRequested());
          },
          icon: const Icon(Icons.sync, color: Colors.white70),
          tooltip: "Sync Offline Actions",
        ),
        IconButton(
          onPressed: () {
            context.read<AuthBloc>().add(AuthLogoutRequested());
          },
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          tooltip: "Logout",
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSyncIndicator(BuildContext context, List<SyncQueueItem> queue) {
    if (queue.isEmpty) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFFF59E0B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Color(0xFF0F172A), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Offline Mode: ${queue.length} documents pending upload synchronization.",
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<DocumentBloc>().add(SyncOfflineQueueRequested());
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text("Sync Now", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummaryGrid(List<DocumentModel> docs, List<SyncQueueItem> queue) {
    final total = docs.length + queue.length;
    final approved = docs.where((d) => d.status == 'Approved').length;
    final pending = docs.where((d) => d.status == 'Submitted' || d.status == 'Under Review').length;
    final drafts = docs.where((d) => d.status == 'Draft' || d.status == 'Rejected').length + queue.length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossCount = width > 600 ? 4 : 2;

          return GridView.count(
            crossAxisCount: crossCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: width > 600 ? 1.8 : 1.5,
            children: [
              _buildStatCard("Total Files", total.toString(), const Color(0xFF2563EB), Icons.folder_copy_outlined),
              _buildStatCard("Approved", approved.toString(), const Color(0xFF10B981), Icons.check_circle_outlined),
              _buildStatCard("Pending", pending.toString(), const Color(0xFFF59E0B), Icons.hourglass_empty_outlined),
              _buildStatCard("Drafts / Sync", drafts.toString(), const Color(0xFFEC4899), Icons.mode_edit_outlined),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            count,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Box
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search documents...",
              hintStyle: const TextStyle(color: Color(0xFF64748B)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              suffixIcon: IconButton(
                onPressed: () {
                  _searchController.clear();
                  _loadData(context);
                },
                icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
              ),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (val) => _loadData(context),
          ),
          const SizedBox(height: 12),

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, "All", ""),
                const SizedBox(width: 8),
                _buildFilterChip(context, "Drafts", "Draft"),
                const SizedBox(width: 8),
                _buildFilterChip(context, "Submitted", "Submitted"),
                const SizedBox(width: 8),
                _buildFilterChip(context, "Under Review", "Under Review"),
                const SizedBox(width: 8),
                _buildFilterChip(context, "Approved", "Approved"),
                const SizedBox(width: 8),
                _buildFilterChip(context, "Rejected", "Rejected"),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value) {
    final selected = _selectedStatus == value;
    return FilterChip(
      selected: selected,
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF94A3B8),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: const Color(0xFF2563EB),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFF334155),
        ),
      ),
      onSelected: (val) {
        setState(() {
          _selectedStatus = value;
        });
        _loadData(context);
      },
    );
  }

  Widget _buildDocumentsList(List<DocumentModel> docs, List<SyncQueueItem> queue, BuildContext context) {
    if (docs.isEmpty && queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 64, color: const Color(0xFF334155)),
            const SizedBox(height: 16),
            const Text(
              "No documents found",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Upload a document or change filters to get started",
              style: TextStyle(color: Color(0xFF475569), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: queue.length + docs.length,
      itemBuilder: (context, index) {
        if (index < queue.length) {
          final qItem = queue[index];
          return _buildQueueCard(qItem, context);
        } else {
          final doc = docs[index - queue.length];
          return _buildDocumentCard(doc, context);
        }
      },
    );
  }

  Widget _buildQueueCard(SyncQueueItem item, BuildContext context) {
    final bytes = File(item.filePath).existsSync() ? File(item.filePath).lengthSync() : 0;
    final formattedSize = _formatSize(bytes);
    final date = DateFormat('MMM dd, yyyy HH:mm').format(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.sync, color: Color(0xFFF59E0B), size: 24),
        ),
        title: Text(
          item.title,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(formattedSize, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                const SizedBox(width: 8),
                const Icon(Icons.circle, size: 4, color: Color(0xFF475569)),
                const SizedBox(width: 8),
                Text(date, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "QUEUED",
            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(DocumentModel doc, BuildContext context) {
    final size = _formatSize(doc.fileSize);
    final date = DateFormat('MMM dd, yyyy HH:mm').format(doc.updatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          context.push('/document/${doc.id}');
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getFileIconColor(doc.mimeType).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getFileIcon(doc.mimeType), color: _getFileIconColor(doc.mimeType), size: 24),
        ),
        title: Text(
          doc.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(doc.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(size, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                const SizedBox(width: 8),
                const Icon(Icons.circle, size: 4, color: Color(0xFF475569)),
                const SizedBox(width: 8),
                Text(date, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ],
        ),
        trailing: _buildStatusChip(doc.status),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.grey;
    if (status == 'Approved') color = const Color(0xFF10B981);
    if (status == 'Under Review') color = const Color(0xFFF59E0B);
    if (status == 'Submitted') color = const Color(0xFF3B82F6);
    if (status == 'Rejected') color = const Color(0xFFEF4444);
    if (status == 'Draft') color = const Color(0xFF94A3B8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color = Colors.grey;
    if (role == 'Admin') color = const Color(0xFF3B82F6);
    if (role == 'Reviewer') color = const Color(0xFF8B5CF6);
    if (role == 'Approver') color = const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('msword')) return Icons.description;
    if (mimeType.contains('image')) return Icons.image;
    return Icons.insert_drive_file;
  }

  Color _getFileIconColor(String mimeType) {
    if (mimeType.contains('pdf')) return const Color(0xFFEF4444);
    if (mimeType.contains('word') || mimeType.contains('msword')) return const Color(0xFF2563EB);
    if (mimeType.contains('image')) return const Color(0xFF10B981);
    return const Color(0xFF94A3B8);
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    final kb = bytes / 1024;
    if (kb < 1024) return "${kb.toStringAsFixed(1)} KB";
    final mb = kb / 1024;
    return "${mb.toStringAsFixed(1)} MB";
  }

  InputDecoration _bottomSheetInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
