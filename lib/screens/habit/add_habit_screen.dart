import 'package:flutter/material.dart';
import '../../services/habit_service.dart';
import '../../models/habit.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habit; // null = création, non-null = édition
  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _service = HabitService();
  final _formKey = GlobalKey<FormState>();

  static const _categories = [
    "Santé", "Sport", "Apprentissage", "Bien-être", "Productivité", "Autre"
  ];
  static const _frequencies = [
    "Quotidienne", "Hebdomadaire", "Personnalisée"
  ];

  String _selectedCategory = "Santé";
  String _selectedFrequency = "Quotidienne";
  bool _loading = false;
  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameCtrl.text = widget.habit!.name;
      _descCtrl.text = widget.habit!.description;
      _selectedCategory = widget.habit!.category;
      _selectedFrequency = widget.habit!.frequency;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    if (_isEditing) {
      await _service.updateHabit(
        widget.habit!.copyWith(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _selectedCategory,
          frequency: _selectedFrequency,
        ),
      );
    } else {
      await _service.addHabit(
        Habit(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _selectedCategory,
          frequency: _selectedFrequency,
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1923) : const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? "Modifier l'habitude" : "Nouvelle habitude",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── Icône centrale ─────────────────────────────────────
                Center(
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B4332), Color(0xFF52B788)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF52B788).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit_rounded : Icons.add_task_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Nom ────────────────────────────────────────────────
                _SectionLabel("Nom de l'habitude"),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2A38) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: "ex: Méditer 10 minutes",
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                      prefixIcon: const Icon(Icons.edit_outlined),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? "Ce champ est requis" : null,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Description ────────────────────────────────────────
                _SectionLabel("Description (optionnelle)"),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2A38) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "ex: Chaque matin après le réveil",
                      hintStyle: TextStyle(color: cs.onSurfaceVariant),
                      prefixIcon: const Icon(Icons.notes_outlined),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Catégorie ──────────────────────────────────────────
                _SectionLabel("Catégorie"),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: _categories.map((cat) {
                    final sel = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: sel
                              ? const LinearGradient(colors: [
                                  Color(0xFF1B4332),
                                  Color(0xFF52B788),
                                ])
                              : null,
                          color: sel
                              ? null
                              : (isDark
                                  ? const Color(0xFF1E2A38)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: sel
                                  ? const Color(0xFF52B788).withOpacity(0.3)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (sel) ...[
                              const Icon(Icons.check_circle,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                            ],
                            Text(cat,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: sel
                                        ? Colors.white
                                        : cs.onSurface)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ── Fréquence ──────────────────────────────────────────
                _SectionLabel("Fréquence"),
                const SizedBox(height: 12),
                Row(
                  children: _frequencies.map((freq) {
                    final sel = freq == _selectedFrequency;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFrequency = freq),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient: sel
                                  ? const LinearGradient(colors: [
                                      Color(0xFF1D6A96),
                                      Color(0xFF2196F3),
                                    ])
                                  : null,
                              color: sel
                                  ? null
                                  : (isDark
                                      ? const Color(0xFF1E2A38)
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: sel
                                      ? Colors.blue.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(freq,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: sel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: sel
                                        ? Colors.white
                                        : cs.onSurface)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),

                // ── Bouton Save ────────────────────────────────────────
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4332), Color(0xFF52B788)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF52B788).withOpacity(0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _loading ? null : _save,
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                height: 24, width: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isEditing
                                        ? Icons.save_rounded
                                        : Icons.add_circle_outline,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isEditing
                                        ? "Enregistrer les modifications"
                                        : "Créer l'habitude",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper widget ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.2));
  }
}