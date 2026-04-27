import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/schedule_controller.dart';
import '../../models/schedule_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../widgets/squad_button.dart';

class ScheduleFormView extends StatefulWidget {
  final ScheduleModel? schedule;

  const ScheduleFormView({super.key, this.schedule});

  @override
  State<ScheduleFormView> createState() => _ScheduleFormViewState();
}

class _ScheduleFormViewState extends State<ScheduleFormView> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedGame;
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  final List<String> _members = [];
  final _memberController = TextEditingController();

  bool get _isEditing => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final s = widget.schedule!;
      _selectedGame = s.game;
      _descController.text = s.description;
      _selectedDate = s.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(s.dateTime);
      _members.addAll(s.members);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.surface,
          ),
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.surface,
          ),
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _addMember() {
    final name = _memberController.text.trim();
    if (name.isEmpty) return;
    if (_members.contains(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name sudah ditambahkan')),
      );
      return;
    }
    setState(() {
      _members.add(name);
      _memberController.clear();
    });
  }

  void _removeMember(String member) {
    setState(() => _members.remove(member));
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGame == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih game terlebih dahulu')),
      );
      return;
    }
    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 anggota')),
      );
      return;
    }

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final controller = context.read<ScheduleController>();
    final uid = context.read<AuthController>().currentUser?.uid ?? '';

    if (_isEditing) {
      final updated = widget.schedule!.copyWith(
        game: _selectedGame,
        description: _descController.text.trim(),
        dateTime: dateTime,
        members: List<String>.from(_members),
      );
      await controller.updateSchedule(updated);
    } else {
      await controller.addSchedule(
        game: _selectedGame!,
        description: _descController.text.trim(),
        dateTime: dateTime,
        members: List<String>.from(_members),
        createdBy: uid,
      );
    }

    if (mounted) {
      final error = controller.errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
        controller.clearError();
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Jadwal berhasil diperbarui!'
                : 'Jadwal berhasil ditambahkan!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          _isEditing ? 'Edit Jadwal' : 'Buat Jadwal Mabar',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Game dropdown
              _sectionLabel('Game'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedGame,
                dropdownColor: AppColors.surfaceLight,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Pilih game',
                  prefixIcon: Icon(Icons.sports_esports_rounded, color: AppColors.primary),
                ),
                items: AppConstants.gameList.map((game) {
                  return DropdownMenuItem(
                    value: game,
                    child: Text(game, style: const TextStyle(color: AppColors.textPrimary)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedGame = val),
                validator: (val) => val == null ? 'Pilih game' : null,
              ),
              const SizedBox(height: 20),

              // Description
              _sectionLabel('Deskripsi'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Ranked push Diamond rank',
                  prefixIcon: Icon(Icons.description_rounded, color: AppColors.primary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Deskripsi tidak boleh kosong';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Date & Time
              _sectionLabel('Tanggal & Waktu'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              _selectedTime.format(context),
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Members
              _sectionLabel('Anggota Tim'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _memberController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Nama anggota',
                        prefixIcon: Icon(Icons.person_add_rounded, color: AppColors.primary),
                      ),
                      onFieldSubmitted: (_) => _addMember(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _addMember,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              if (_members.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _members.map((member) {
                    return Chip(
                      label: Text(member, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      backgroundColor: AppColors.surfaceLight,
                      side: const BorderSide(color: AppColors.primary, width: 0.5),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                      onDeleted: () => _removeMember(member),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 32),

              // Submit button
              Consumer<ScheduleController>(
                builder: (_, ctrl, __) => SquadButton(
                  label: _isEditing ? 'Simpan Perubahan' : 'Buat Jadwal',
                  onPressed: _handleSubmit,
                  isLoading: ctrl.isLoading,
                  icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
