import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

/// 图片选择卡片组件
///
/// 支持：拍照/相册选择、图片预览缩略图、拖拽旋转
class ImagePickerCard extends StatefulWidget {
  /// 当前选中的图片字节
  final Uint8List? imageBytes;

  /// 选择图片回调
  final ValueChanged<Uint8List> onImagePicked;

  /// 清除图片回调
  final VoidCallback? onImageCleared;

  /// 旋转角度回调
  final ValueChanged<double>? onRotationChanged;

  /// 卡片标题
  final String title;

  /// 是否允许拖拽旋转
  final bool allowRotation;

  const ImagePickerCard({
    super.key,
    this.imageBytes,
    required this.onImagePicked,
    this.onImageCleared,
    this.onRotationChanged,
    this.title = '选择图片',
    this.allowRotation = true,
  });

  @override
  State<ImagePickerCard> createState() => _ImagePickerCardState();
}

class _ImagePickerCardState extends State<ImagePickerCard> {
  double _rotationAngle = 0.0;

  /// 从相册选择图片
  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
    );
    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      widget.onImagePicked(bytes);
    }
  }

  /// 拍照
  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    // 检查相机权限
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        widget.onImagePicked(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法访问相机，请检查权限')),
        );
      }
    }
  }

  /// 旋转图片
  void _rotateImage() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
    widget.onRotationChanged?.call(_rotationAngle);
  }

  /// 显示选择来源弹窗
  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '选择图片来源',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFC04040)),
                  title: const Text('从相册选择'),
                  subtitle: const Text('从手机相册中选择图片'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFC04040)),
                  title: const Text('拍照'),
                  subtitle: const Text('使用相机拍摄照片'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                const Icon(Icons.image_outlined, size: 20, color: Color(0xFFC04040)),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (widget.imageBytes != null) ...[
                  if (widget.allowRotation)
                    IconButton(
                      icon: const Icon(Icons.rotate_right, size: 20),
                      onPressed: _rotateImage,
                      tooltip: '旋转图片',
                    ),
                  if (widget.onImageCleared != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.red),
                      onPressed: widget.onImageCleared,
                      tooltip: '清除图片',
                    ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // 图片预览区域
            SizedBox(
              height: 200,
              width: double.infinity,
              child: widget.imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GestureDetector(
                        onTap: _showPickerOptions,
                        child: Transform.rotate(
                          angle: _rotationAngle * (3.1415927 / 180),
                          child: Image.memory(
                            widget.imageBytes!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Text('图片加载失败'),
                            ),
                          ),
                        ),
                      ),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(height: 8),

            // 底部操作按钮
            if (widget.imageBytes == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.photo_library_outlined,
                    label: '从相册选择',
                    onTap: _pickFromGallery,
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.camera_alt_outlined,
                    label: '拍照',
                    onTap: _takePhoto,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// 占位区域
  Widget _buildPlaceholder() {
    return InkWell(
      onTap: _showPickerOptions,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 48, color: Color(0xFFC0C0C0)),
              SizedBox(height: 8),
              Text('点击选择图片', style: TextStyle(color: Color(0xFF999999))),
            ],
          ),
        ),
      ),
    );
  }

  /// 操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFFC04040)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
