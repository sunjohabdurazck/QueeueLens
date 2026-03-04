import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../services/presentation/providers/services_providers.dart';
import '../../../surveillance/domain/entities/surveillance_camera.dart';
import '../providers/surveillance_providers.dart';

class CameraManagementPage extends ConsumerWidget {
  const CameraManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camerasAsync = ref.watch(allCamerasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCameraDialog(context, ref),
          ),
        ],
      ),
      body: camerasAsync.when(
        data: (cameras) {
          if (cameras.isEmpty) {
            return _buildEmptyView(context, ref);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cameras.length,
            itemBuilder: (context, index) {
              final camera = cameras[index];
              return _buildCameraCard(context, ref, camera);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(allCamerasProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No Cameras Configured',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first surveillance camera to get started',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddCameraDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Camera'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraCard(
    BuildContext context,
    WidgetRef ref,
    SurveillanceCamera camera,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: camera.isActive ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.videocam,
            color: camera.isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          camera.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_getCameraTypeLabel(camera.type)),
        trailing: Switch(
          value: camera.isActive,
          onChanged: (value) async {
            try {
              await ref
                  .read(cameraActionsProvider)
                  .toggleCameraStatus(camera.id, value);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Camera activated' : 'Camera deactivated',
                    ),
                    backgroundColor: value ? Colors.green : Colors.orange,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Stream URL', _truncateUrl(camera.streamUrl)),
                const SizedBox(height: 8),
                _buildInfoRow('Service ID', camera.serviceId),
                if (camera.description != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Description', camera.description!),
                ],
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Position',
                  'X: ${camera.position.x.toStringAsFixed(1)}, '
                  'Y: ${camera.position.y.toStringAsFixed(1)}, '
                  'Z: ${camera.position.z.toStringAsFixed(1)}',
                ),
                if (camera.lastActive != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Last Active',
                    _formatDateTime(camera.lastActive!),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showEditCameraDialog(context, ref, camera),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(context, ref, camera),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  String _truncateUrl(String url) {
    if (url.length > 50) {
      return '${url.substring(0, 25)}...${url.substring(url.length - 20)}';
    }
    return url;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getCameraTypeLabel(CameraType type) {
    switch (type) {
      case CameraType.ipWebcam:
        return 'IP Webcam';
      case CameraType.rtsp:
        return 'RTSP Stream';
      case CameraType.mjpeg:
        return 'MJPEG Stream';
      case CameraType.http:
        return 'HTTP Stream';
    }
  }

  void _showAddCameraDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CameraFormDialog(
        title: 'Add New Camera',
        onSave: (camera) async {
          await ref.read(cameraActionsProvider).addCamera(camera);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditCameraDialog(
    BuildContext context,
    WidgetRef ref,
    SurveillanceCamera camera,
  ) {
    showDialog(
      context: context,
      builder: (context) => _CameraFormDialog(
        title: 'Edit Camera',
        camera: camera,
        onSave: (updatedCamera) async {
          await ref.read(cameraActionsProvider).updateCamera(updatedCamera);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SurveillanceCamera camera,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Camera'),
        content: Text('Are you sure you want to delete "${camera.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(cameraActionsProvider).deleteCamera(camera.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Camera deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CameraFormDialog extends ConsumerStatefulWidget {
  final String title;
  final SurveillanceCamera? camera;
  final Future<void> Function(SurveillanceCamera) onSave;

  const _CameraFormDialog({
    required this.title,
    required this.onSave,
    this.camera,
  });

  @override
  ConsumerState<_CameraFormDialog> createState() => _CameraFormDialogState();
}

class _CameraFormDialogState extends ConsumerState<_CameraFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _descriptionController;
  late TextEditingController _posXController;
  late TextEditingController _posYController;
  late TextEditingController _posZController;
  
  String? _selectedServiceId;
  CameraType _selectedType = CameraType.ipWebcam;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.camera?.name ?? '');
    _urlController = TextEditingController(text: widget.camera?.streamUrl ?? '');
    _descriptionController = TextEditingController(text: widget.camera?.description ?? '');
    _posXController = TextEditingController(
      text: widget.camera?.position.x.toString() ?? '0',
    );
    _posYController = TextEditingController(
      text: widget.camera?.position.y.toString() ?? '15',
    );
    _posZController = TextEditingController(
      text: widget.camera?.position.z.toString() ?? '0',
    );
    
    _selectedServiceId = widget.camera?.serviceId;
    _selectedType = widget.camera?.type ?? CameraType.ipWebcam;
    _isActive = widget.camera?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    _posXController.dispose();
    _posYController.dispose();
    _posZController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesStreamProvider);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Camera Name *',
                  hintText: 'e.g., Library Entrance',
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              servicesAsync.when(
                data: (services) => DropdownButtonFormField<String>(
                  value: _selectedServiceId,
                  decoration: const InputDecoration(labelText: 'Location *'),
                  items: services.map((service) {
                    return DropdownMenuItem(
                      value: service.id,
                      child: Text(service.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedServiceId = value),
                  validator: (value) =>
                      value == null ? 'Please select a location' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading services'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CameraType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Camera Type *'),
                items: CameraType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getCameraTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Stream URL *',
                  hintText: _getUrlHintForType(_selectedType),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Stream URL is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Additional details about this camera',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text(
                '3D Position',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _posXController,
                      decoration: const InputDecoration(labelText: 'X'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _posYController,
                      decoration: const InputDecoration(labelText: 'Y'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _posZController,
                      decoration: const InputDecoration(labelText: 'Z'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  String _getCameraTypeLabel(CameraType type) {
    switch (type) {
      case CameraType.ipWebcam:
        return 'IP Webcam';
      case CameraType.rtsp:
        return 'RTSP Stream';
      case CameraType.mjpeg:
        return 'MJPEG Stream';
      case CameraType.http:
        return 'HTTP Stream';
    }
  }

  String _getUrlHintForType(CameraType type) {
    switch (type) {
      case CameraType.ipWebcam:
        return 'http://192.168.1.100:8080/video';
      case CameraType.rtsp:
        return 'rtsp://192.168.1.100:8554/stream';
      case CameraType.mjpeg:
        return 'http://192.168.1.100:8081/stream.mjpg';
      case CameraType.http:
        return 'http://192.168.1.100/camera';
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final camera = SurveillanceCamera(
        id: widget.camera?.id ?? const Uuid().v4(),
        serviceId: _selectedServiceId!,
        name: _nameController.text,
        streamUrl: _urlController.text,
        type: _selectedType,
        isActive: _isActive,
        position: CameraPosition(
          x: double.tryParse(_posXController.text) ?? 0,
          y: double.tryParse(_posYController.text) ?? 15,
          z: double.tryParse(_posZController.text) ?? 0,
        ),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        lastActive: widget.camera?.lastActive,
      );

      await widget.onSave(camera);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
