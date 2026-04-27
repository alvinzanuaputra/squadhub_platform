import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/note_controller.dart';
import '../../models/note_model.dart';
import '../../models/note_tag_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../widgets/squad_button.dart';

class NoteFormView extends StatefulWidget {
  final NoteModel? note;

  const NoteFormView({super.key, this.note});

  @override
  State<NoteFormView> createState() => _NoteFormViewState();
}

class _NoteFormViewState extends State<NoteFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _heroCtrl = TextEditingController();

  String _selectedCategory = 'Hero Counter';
  String _selectedRole = 'Marksman';
  String _selectedGame = 'Mobile Legends: Bang Bang';

  List<NoteTagModel> _currentTags = [];
  bool _showRoleDropdown = false;

  bool get _isEditing => widget.note != null;

  static const Map<String, List<String>> _gameRoles = {
    'League of Legends': ['Top', 'Jungle', 'Mid', 'ADC', 'Support'],
    'Dota 2': ['Carry', 'Midlaner', 'Offlaner', 'Soft Support', 'Hard Support'],
    'Smite': ['Jungle', 'Carry', 'Mid', 'Solo', 'Support'],
    'Honor of Kings': ['Clash Lane', 'Jungle', 'Mid', 'Marksman', 'Roam'],
    'Heroes of the Storm': [
      'Tank', 'Bruiser', 'Healer',
      'Melee Assassin', 'Ranged Assassin', 'Support',
    ],
    'Mobile Legends: Bang Bang': [
      'Tank', 'Fighter', 'Assassin', 'Mage', 'Marksman', 'Support',
    ],
  };

  List<String> get _currentRoles =>
      _gameRoles[_selectedGame] ??
      ['Tank', 'Fighter', 'Assassin', 'Mage', 'Marksman', 'Support'];

  List<String> get _categories =>
      AppConstants.categoryList.where((c) => c != 'Semua').toList();

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Hero Counter': return AppColors.danger;
      case 'Strategi':    return AppColors.primary;
      case 'Draft':       return AppColors.accent;
      case 'Umum':        return AppColors.success;
      default:            return AppColors.textThird;
    }
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.note != null && widget.note!.id > 0) {
      _titleController.text   = widget.note!.title;
      _contentController.text = widget.note!.content;
      _selectedCategory       = widget.note!.category;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context
            .read<NoteController>()
            .loadTagsForNote(widget.note!.id)
            .then((_) {
          if (mounted) {
            setState(() {
              _currentTags = context
                  .read<NoteController>()
                  .getTagsForNote(widget.note!.id);
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _heroCtrl.dispose();
    super.dispose();
  }

  void _onGameChanged(String? value) {
    if (value == null) return;
    final roles = _gameRoles[value] ?? [];
    setState(() {
      _selectedGame = value;
      if (!roles.contains(_selectedRole)) {
        _selectedRole = roles.isNotEmpty ? roles.first : '';
      }
    });
  }

  Future<void> _addTag() async {
    if (_heroCtrl.text.trim().isEmpty) return;
    if (!_isEditing || widget.note == null || widget.note!.id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simpan catatan dulu sebelum tambah hero'),
        ),
      );
      return;
    }
    final ctrl = context.read<NoteController>();
    await ctrl.addTag(
      noteId:   widget.note!.id,
      heroName: _heroCtrl.text.trim(),
      role:     _selectedRole,
      game:     _selectedGame,
    );
    if (mounted) {
      setState(() {
        _currentTags      = ctrl.getTagsForNote(widget.note!.id);
        _showRoleDropdown = false;
        _heroCtrl.clear();
      });
    }
  }

  Future<void> _deleteTag(NoteTagModel tag) async {
    if (!_isEditing || widget.note == null || widget.note!.id == 0) return;
    final ctrl = context.read<NoteController>();
    await ctrl.deleteTag(tag.id, widget.note!.id);
    if (mounted) {
      setState(() {
        _currentTags = ctrl.getTagsForNote(widget.note!.id);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<NoteController>();

    if (_isEditing) {
      if (widget.note == null || widget.note!.id == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: ID catatan tidak valid')),
        );
        return;
      }

      // ══════════════════════════════════════════════════════════
      // ROOT CAUSE FIX — "data tidak tersimpan saat edit":
      //
      // SEBELUMNYA (buggy):
      //   final updated = widget.note!
      //     ..title = _titleController.text.trim()   ← cascade mutation
      //     ..content = _contentController.text.trim()
      //     ..category = _selectedCategory;
      //
      // MASALAH:
      //   Operator cascade (..) memodifikasi objek widget.note! secara
      //   langsung (in-place). Isar menyimpan referensi objek di
      //   internal cache-nya. Ketika objek yang SAMA di-put() ulang,
      //   Isar bisa mendeteksinya sebagai "tidak ada perubahan" karena
      //   referensi identik, sehingga write transaction diabaikan.
      //   Ini menyebabkan data lama tetap tersimpan di database.
      //
      // FIX:
      //   Buat instance NoteModel BARU dengan id yang sama.
      //   Isar menggunakan id untuk upsert: jika id sudah ada di
      //   koleksi, record lama akan di-overwrite sepenuhnya dengan
      //   data dari objek baru. Karena referensi berbeda, Isar
      //   selalu memproses write transaction ini.
      // ══════════════════════════════════════════════════════════
      final updated = NoteModel()
        ..id        = widget.note!.id          // id sama → update (bukan insert baru)
        ..title     = _titleController.text.trim()
        ..content   = _contentController.text.trim()
        ..category  = _selectedCategory
        ..createdAt = widget.note!.createdAt;  // pertahankan tanggal asli

      await controller.updateNote(updated);

      if (controller.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!)),
        );
        return;
      }
    } else {
      await controller.addNote(
        title:    _titleController.text.trim(),
        content:  _contentController.text.trim(),
        category: _selectedCategory,
      );
      if (controller.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!)),
        );
        return;
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            _isEditing ? 'Edit Catatan' : 'Catatan Baru',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Judul ──
                SizedBox(
                  width: double.infinity,
                  child: TextFormField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Judul catatan...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecond,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Judul tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: AppColors.borderColor),
                const SizedBox(height: 16),

                // ── Kategori ──
                const Text(
                  'Kategori',
                  style: TextStyle(
                    color: AppColors.textThird,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      final catColor = _getCategoryColor(cat);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? catColor.withValues(alpha: 0.15)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? catColor
                                    : AppColors.borderColor,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected
                                    ? catColor
                                    : AppColors.textThird,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // ── Isi Catatan ──
                const Text(
                  'Isi Catatan',
                  style: TextStyle(
                    color: AppColors.textThird,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextFormField(
                    controller: _contentController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                    maxLines: null,
                    minLines: 8,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText:
                          'Tuliskan strategi, tips, atau catatan Anda di sini...',
                      hintStyle: TextStyle(
                          color: AppColors.textSecond, fontSize: 14),
                      alignLabelWithHint: true,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Isi catatan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── Hero Terkait ──
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hero Terkait',
                      style: TextStyle(
                        color: AppColors.textSecond,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '(opsional)',
                      style: TextStyle(
                        color: AppColors.textSecond,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── [1] Input nama hero + tombol + ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _heroCtrl,
                        onChanged: (value) {
                          final isNotEmpty = value.trim().isNotEmpty;
                          if (isNotEmpty != _showRoleDropdown) {
                            setState(() {
                              _showRoleDropdown = isNotEmpty;
                              if (!isNotEmpty) {
                                _selectedRole =
                                    _currentRoles.isNotEmpty
                                        ? _currentRoles.first
                                        : '';
                              }
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: 'Nama hero...',
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        style: const TextStyle(
                            color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: ElevatedButton(
                        onPressed: _addTag,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.add, size: 20),
                      ),
                    ),
                  ],
                ),

                // ── [2] Dropdown role (muncul setelah hero diisi) ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: FadeTransition(
                        opacity: animation, child: child),
                  ),
                  child: _showRoleDropdown
                      ? Padding(
                          key: const ValueKey('role_section'),
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pilih Role',
                                style: TextStyle(
                                  color: AppColors.textThird,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _currentRoles
                                            .contains(_selectedRole)
                                        ? _selectedRole
                                        : _currentRoles.first,
                                    dropdownColor: AppColors.surface,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                    icon: const Icon(
                                      Icons
                                          .keyboard_arrow_down_rounded,
                                      color: AppColors.primary,
                                    ),
                                    isExpanded: true,
                                    items: _currentRoles.map((role) {
                                      return DropdownMenuItem(
                                        value: role,
                                        child: Text(role),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() =>
                                            _selectedRole = value);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('role_hidden')),
                ),

                // ── [3] Dropdown pilih game ──
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: AppConstants.gameList
                              .contains(_selectedGame)
                          ? _selectedGame
                          : AppConstants.gameList.first,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecond,
                      ),
                      isExpanded: true,
                      items: AppConstants.gameList.map((game) {
                        return DropdownMenuItem(
                          value: game,
                          child: Text(
                            game,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _onGameChanged,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Tags yang sudah ditambahkan ──
                if (_currentTags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _currentTags.map((tag) {
                      return InkWell(
                        onTap: () => _deleteTag(tag),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Wrap(
                            spacing: 6,
                            crossAxisAlignment:
                                WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${tag.heroName} • ${tag.role}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Icon(
                                Icons.close,
                                size: 14,
                                color: AppColors.danger,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 32),

                // ── Tombol simpan ──
                Consumer<NoteController>(
                  builder: (_, ctrl, __) => SquadButton(
                    label: _isEditing
                        ? 'Simpan Perubahan'
                        : 'Simpan Catatan',
                    onPressed: _handleSubmit,
                    isLoading: ctrl.isLoading,
                    icon: Icons.save_rounded,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}