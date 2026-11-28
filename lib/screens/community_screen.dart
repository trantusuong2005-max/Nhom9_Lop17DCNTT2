import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  final bool firebaseReady;

  const CommunityScreen({super.key, required this.firebaseReady});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;

  static final _localAccounts = {
    'sinhvien@blu.edu.vn': {
      'password': '123456',
      'name': 'Sinh viên ĐH Bạc Liêu',
      'hometown': 'Bạc Liêu',
      'phone': '0900 000 000',
      'bio': 'Thích đi phượt miền Tây và lưu giữ ảnh đẹp.',
    },
  };
  static String? _currentLocalEmail;

  static final _localProfilesByUid = {};

  static final _localPosts = [
    {
      'id': '1',
      'author': 'Sinh viên ĐH Bạc Liêu',
      'place': 'Nhà Công tử Bạc Liêu & Cánh đồng điện gió',
      'content': 'Buổi chiều ra điện gió chụp hình cực đẹp, gió mát rượi!',
      'comments': [
        'Minh Anh: Nên đi tầm 4h chiều nắng đẹp nhất nè.',
      ],
    },
  ];

  static final _localStreamCtrl = StreamController.broadcast();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _placeCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFirebaseProfile(String uid) async {
    if (!widget.firebaseReady) return;
    try {
      final snap = await FirebaseDatabase.instance.ref('users/$uid').get();
      if (snap.exists && snap.value is Map && mounted) {
        final raw = Map.from(snap.value as Map);
        _localProfilesByUid[uid] = {
          'name': (raw['name'] ?? '').toString(),
          'hometown': (raw['hometown'] ?? '').toString(),
          'phone': (raw['phone'] ?? '').toString(),
          'bio': (raw['bio'] ?? '').toString(),
        };
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _submitAuth() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passCtrl.text.trim();
    final displayName = _nameCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showMsg('Vui lòng nhập email hợp lệ.');
      return;
    }
    if (password.length < 6) {
      _showMsg('Mật khẩu phải có ít nhất 6 ký tự.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.firebaseReady) {
        if (_isRegisterMode) {
          final cred = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);
          final finalName =
              displayName.isEmpty ? email.split('@').first : displayName;
          if (cred.user != null) {
            await cred.user!.updateDisplayName(finalName);
            await FirebaseDatabase.instance.ref('users/${cred.user!.uid}').set({
              'name': finalName,
              'email': email,
              'hometown': '',
              'phone': '',
              'bio': '',
            });
          }
        } else {
          final cred = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);
          if (cred.user != null) {
            await _loadFirebaseProfile(cred.user!.uid);
          }
        }
      } else {
        if (_isRegisterMode) {
          if (_localAccounts.containsKey(email)) {
            _showMsg('Email này đã được đăng ký, hãy chuyển sang Đăng nhập.');
          } else {
            _localAccounts[email] = {
              'password': password,
              'name': displayName.isEmpty ? email.split('@').first : displayName,
              'hometown': '',
              'phone': '',
              'bio': '',
            };
            _currentLocalEmail = email;
            _showMsg('Đăng ký tài khoản thành công!');
          }
        } else {
          final acc = _localAccounts[email];
          if (acc == null || acc['password'] != password) {
            _showMsg('Sai email hoặc mật khẩu (hoặc bấm Đăng ký tài khoản mới).');
          } else {
            _currentLocalEmail = email;
            _showMsg('Đăng nhập thành công!');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      _showMsg(e.message ?? 'Lỗi xác thực Firebase.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    if (widget.firebaseReady) {
      await FirebaseAuth.instance.signOut();
    } else {
      setState(() {
        _currentLocalEmail = null;
      });
    }
  }

  Future<void> _editProfile({
    required Map<String, String> currentProfile,
    String? firebaseUid,
  }) async {
    final nameCtrl = TextEditingController(text: currentProfile['name'] ?? '');
    final hometownCtrl =
        TextEditingController(text: currentProfile['hometown'] ?? '');
    final phoneCtrl = TextEditingController(text: currentProfile['phone'] ?? '');
    final bioCtrl = TextEditingController(text: currentProfile['bio'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8FA),
        title: const Text(
          'Quản lý thông tin cá nhân',
          style: TextStyle(color: Color(0xFF5A2338), fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: hometownCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quê quán / Nơi ở',
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bioCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Giới thiệu / Châm ngôn du lịch',
                  prefixIcon: Icon(Icons.format_quote),
                ),
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
            onPressed: () async {
              final newName = nameCtrl.text.trim().isEmpty
                  ? (currentProfile['name'] ?? 'Du khách')
                  : nameCtrl.text.trim();
              final newHometown = hometownCtrl.text.trim();
              final newPhone = phoneCtrl.text.trim();
              final newBio = bioCtrl.text.trim();

              if (widget.firebaseReady && firebaseUid != null) {
                await FirebaseAuth.instance.currentUser
                    ?.updateDisplayName(newName);
                await FirebaseDatabase.instance
                    .ref('users/$firebaseUid')
                    .update({
                  'name': newName,
                  'hometown': newHometown,
                  'phone': newPhone,
                  'bio': newBio,
                });
                _localProfilesByUid[firebaseUid] = {
                  'name': newName,
                  'hometown': newHometown,
                  'phone': newPhone,
                  'bio': newBio,
                };
              } else if (_currentLocalEmail != null) {
                final acc = _localAccounts[_currentLocalEmail!];
                if (acc != null) {
                  acc['name'] = newName;
                  acc['hometown'] = newHometown;
                  acc['phone'] = newPhone;
                  acc['bio'] = newBio;
                }
              }

              if (mounted) setState(() {});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.save),
            label: const Text('Lưu hồ sơ'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPost(String authorName) async {
    final place = _placeCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (place.isEmpty || content.isEmpty) {
      _showMsg('Vui lòng nhập tên địa điểm và cảm nhận.');
      return;
    }

    if (widget.firebaseReady) {
      await FirebaseDatabase.instance.ref('memories').push().set({
        'author': authorName,
        'place': place,
        'content': content,
        'comments': [],
      });
    } else {
      _localPosts.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'author': authorName,
        'place': place,
        'content': content,
        'comments': [],
      });
      _localStreamCtrl.add(List.from(_localPosts));
    }

    _placeCtrl.clear();
    _contentCtrl.clear();
  }

  Future<void> _addComment({
    required String postId,
    required String authorName,
    required List existingComments,
  }) async {
    final cmtCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm bình luận'),
        content: TextField(
          controller: cmtCtrl,
          decoration: const InputDecoration(
            hintText: 'Nhập bình luận của bạn...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = cmtCtrl.text.trim();
              if (text.isNotEmpty) {
                final updatedComments = [
                  ...existingComments,
                  '$authorName: $text',
                ];
                if (widget.firebaseReady) {
                  await FirebaseDatabase.instance
                      .ref('memories/$postId/comments')
                      .set(updatedComments);
                } else {
                  final idx =
                      _localPosts.indexWhere((element) => element['id'] == postId);
                  if (idx != -1) {
                    _localPosts[idx]['comments'] = updatedComments;
                    _localStreamCtrl.add(List.from(_localPosts));
                  }
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.firebaseReady) {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) return _buildAuthForm();

          final cached = _localProfilesByUid[user.uid] as Map?;
          final fallbackName =
              (user.displayName != null && user.displayName!.isNotEmpty)
                  ? user.displayName!
                  : (user.email ?? 'Du khách');

          final profile = {
            'name': (cached?['name'] ?? fallbackName).toString(),
            'hometown': (cached?['hometown'] ?? '').toString(),
            'phone': (cached?['phone'] ?? '').toString(),
            'bio': (cached?['bio'] ?? '').toString(),
          };

          return _buildCommunityBody(
            userEmail: user.email ?? '',
            profile: profile,
            firebaseUid: user.uid,
          );
        },
      );
    }

    if (_currentLocalEmail == null) {
      return _buildAuthForm();
    }

    final rawAcc = _localAccounts[_currentLocalEmail!]!;
    final profile = {
      'name': (rawAcc['name'] ?? 'Du khách').toString(),
      'hometown': (rawAcc['hometown'] ?? '').toString(),
      'phone': (rawAcc['phone'] ?? '').toString(),
      'bio': (rawAcc['bio'] ?? '').toString(),
    };

    return _buildCommunityBody(
      userEmail: _currentLocalEmail!,
      profile: profile,
    );
  }

  Widget _buildAuthForm() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(_isRegisterMode ? 'Đăng ký Tài khoản' : 'Đăng nhập Tài khoản'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isRegisterMode
                          ? 'Tạo tài khoản Du khách mới'
                          : 'Đăng nhập vào Cộng đồng Du lịch',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A2338),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    if (_isRegisterMode) ...[
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên hiển thị',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'VD: sinhvien@blu.edu.vn',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu (>= 6 ký tự)',
                        hintText: 'VD: 123456',
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitAuth,
                      child: Text(_isRegisterMode ? 'Đăng ký ngay' : 'Đăng nhập'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isRegisterMode = !_isRegisterMode;
                        });
                      },
                      child: Text(
                        _isRegisterMode
                            ? 'Đã có tài khoản? Chuyển sang Đăng nhập'
                            : 'Chưa có tài khoản? Đăng ký ngay',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityBody({
    required String userEmail,
    required Map<String, String> profile,
    String? firebaseUid,
  }) {
    final displayName = profile['name'] ?? 'Du khách';
    final hometown = profile['hometown'] ?? '';
    final phone = profile['phone'] ?? '';
    final bio = profile['bio'] ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Cộng đồng & Hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            color: const Color(0xFFFFEDF3),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFC8EFE2),
                        foregroundColor: Color(0xFF1A5649),
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF5A2338),
                              ),
                            ),
                            Text(
                              userEmail,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7A4458),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _editProfile(
                          currentProfile: profile,
                          firebaseUid: firebaseUid,
                        ),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Sửa hồ sơ'),
                      ),
                    ],
                  ),
                  if (hometown.isNotEmpty || phone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (hometown.isNotEmpty) 'Quê quán: $hometown',
                        if (phone.isNotEmpty) 'SĐT: $phone',
                      ].join('  •  '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF235C4F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '“$bio”',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF5A2338),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          ExpansionTile(
            initiallyExpanded: false,
            title: const Text(
              'Chia sẻ địa điểm kỷ niệm mới',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _placeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Địa điểm du lịch',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cảm nhận / Kinh nghiệm chuyến đi',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _createPost(displayName),
                      icon: const Icon(Icons.send),
                      label: const Text('Đăng lên cộng đồng'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: widget.firebaseReady
                ? _buildFirebasePostsList(displayName)
                : _buildLocalPostsList(displayName),
          ),
        ],
      ),
    );
  }

  Widget _buildFirebasePostsList(String currentUserName) {
    final ref = FirebaseDatabase.instance.ref('memories');
    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;
        if (!snapshot.hasData || raw == null || raw is! Map) {
          return const Center(child: Text('Chưa có bài chia sẻ nào.'));
        }

        final items = raw.entries.toList();
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final postId = items[index].key.toString();
            final data = Map.from(items[index].value as Map);
            final rawComments = data['comments'];
            final comments = rawComments is List
                ? rawComments.map((e) => e.toString()).toList()
                : [];

            return _buildPostCard(
              postId: postId,
              author: (data['author'] ?? '').toString(),
              place: (data['place'] ?? '').toString(),
              content: (data['content'] ?? '').toString(),
              comments: comments,
              currentUserName: currentUserName,
            );
          },
        );
      },
    );
  }

  Widget _buildLocalPostsList(String currentUserName) {
    return StreamBuilder(
      stream: _localStreamCtrl.stream,
      initialData: _localPosts,
      builder: (context, snapshot) {
        final rawData = snapshot.data;
        final posts = rawData is List ? rawData : _localPosts;
        if (posts.isEmpty) {
          return const Center(child: Text('Chưa có bài chia sẻ nào.'));
        }
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final p = posts[index] as Map;
            final rawComments = p['comments'];
            final comments = rawComments is List
                ? rawComments.map((e) => e.toString()).toList()
                : [];
            return _buildPostCard(
              postId: p['id'].toString(),
              author: p['author'].toString(),
              place: p['place'].toString(),
              content: p['content'].toString(),
              comments: comments,
              currentUserName: currentUserName,
            );
          },
        );
      },
    );
  }

  Widget _buildPostCard({
    required String postId,
    required String author,
    required String place,
    required String content,
    required List comments,
    required String currentUserName,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place, color: Color(0xFF48A999)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    place,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D564A),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Đăng bởi: $author',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(content),
            const Divider(),
            ...comments.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('💬 $c', style: const TextStyle(fontSize: 13)),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _addComment(
                  postId: postId,
                  authorName: currentUserName,
                  existingComments: comments,
                ),
                icon: const Icon(Icons.comment, size: 18),
                label: const Text('Bình luận'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}