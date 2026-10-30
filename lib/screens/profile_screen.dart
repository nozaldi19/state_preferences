import 'package:flutter/material.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _favController = TextEditingController();
  bool _initialized = false;

  // Catatan: dependOnInheritedWidgetOfExactType TIDAK boleh dipanggil di
  // initState(), karena itu pakai didChangeDependencies().
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = context.read<UserProvider>();
      _nameController.text = provider.user.name;
      _emailController.text = provider.user.email;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favController.dispose();
    super.dispose();
  }

  // Latihan 5: menampilkan error validasi keamanan lewat SnackBar
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<UserProvider>();
    final updatedUser = provider.user.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      isLoggedIn: true,
    );

    final error = await provider.updateUser(updatedUser);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Profil berhasil disimpan'),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      context.read<UserProvider>().logout();
      Navigator.pop(context);
    }
  }

  // Latihan 3
  void _addFavorite() {
    final text = _favController.text.trim();
    if (text.isEmpty) return;
    final provider = context.read<UserProvider>();
    if (provider.favorites.contains(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item sudah ada di daftar favorit')));
      return;
    }
    provider.addFavorite(text);
    _favController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (provider.user.isLoggedIn)
            IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
                tooltip: 'Logout'),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nama tidak boleh kosong'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(v.trim())) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan Profil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ===== Latihan 3: Daftar Favorit =====
                  Text('Daftar Favorit (Hobi)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _favController,
                          decoration: const InputDecoration(
                            labelText: 'Tambah item favorit',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addFavorite(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                          onPressed: _addFavorite, icon: const Icon(Icons.add)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (provider.favorites.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Belum ada favorit',
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ...provider.favorites.map(
                      (item) => ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.red),
                        title: Text(item),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => provider.removeFavorite(item),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Catatan Keamanan: data disimpan di SharedPreferences '
                        '(plaintext). Jangan simpan password atau data sensitif '
                        'di sini. Gunakan secure storage untuk data sensitif.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}