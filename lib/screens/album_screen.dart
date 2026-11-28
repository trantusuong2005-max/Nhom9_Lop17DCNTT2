import 'package:flutter/material.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();

 final _photos = [
    {
      'title': 'Biển xanh',
      'url': 'https://picsum.photos/id/1015/500/500',
    },
    {
      'title': 'Đồi thông',
      'url': 'https://picsum.photos/id/1018/500/500',
    },
    {
      'title': 'Rừng cây',
      'url': 'https://picsum.photos/id/1019/500/500',
    },
    {
      'title': 'Hoàng hôn',
      'url': 'https://picsum.photos/id/1039/500/500',
    },
    {
      'title': 'Cảnh núi',
      'url': 'https://picsum.photos/id/1043/500/500',
    },
    {
      'title': 'Chuyến đi xa',
      'url': 'https://picsum.photos/id/1051/500/500',
    },
  ];

  final _quickSamples = const [
    {
      'title': 'Bình minh miền biển',
      'url': 'https://picsum.photos/id/1016/500/500',
    },
    {
      'title': 'Thác nước xanh mát',
      'url': 'https://picsum.photos/id/1040/500/500',
    },
    {
      'title': 'Con đường dã ngoại',
      'url': 'https://picsum.photos/id/1056/500/500',
    },
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _openAddPhotoDialog() {
    _titleCtrl.clear();
    _urlCtrl.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm ảnh vào Album'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên / Chú thích ảnh',
                  hintText: 'VD: Check-in điện gió',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Đường dẫn (URL) ảnh',
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hoặc chọn nhanh ảnh mẫu:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickSamples.map((sample) {
                  return ActionChip(
                    label: Text(
                      sample['title']!,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      _titleCtrl.text = sample['title']!;
                      _urlCtrl.text = sample['url']!;
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final url = _urlCtrl.text.trim();
              final title = _titleCtrl.text.trim().isEmpty
                  ? 'Ảnh chuyến đi mới'
                  : _titleCtrl.text.trim();

              if (url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập URL ảnh hoặc chọn ảnh mẫu.'),
                  ),
                );
                return;
              }

              setState(() {
                _photos.insert(0, {'title': title, 'url': url});
              });
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.upload),
            label: const Text('Đẩy ảnh lên'),
          ),
        ],
      ),
    );
  }

  void _openPhotoDetail(int index) {
    final item = _photos[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item['title'] ?? 'Chi tiết ảnh'),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            item['url']!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Padding(
              padding: EdgeInsets.all(24),
              child: Icon(Icons.broken_image, size: 48),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _photos.removeAt(index));
              Navigator.pop(ctx);
            },
            child: const Text('Xóa ảnh', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Album Ảnh Du lịch'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPhotoDialog,
        tooltip: 'Thêm ảnh mới',
        child: const Icon(Icons.add),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          // Xoay đứng: 2 cột, xoay ngang: 3 cột[cite: 1, 2]
          final int crossAxisCount =
              orientation == Orientation.portrait ? 2 : 3;

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              final item = _photos[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openPhotoDetail(index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Image.network(
                          item['url']!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(Icons.broken_image, size: 36),
                          ),
                        ),
                      ),
                      Container(
                        color: const Color(0xFFF6FBF9),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF184E42),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}