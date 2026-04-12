import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/portfolio_entry.dart';
import '../services/portfolio_provider.dart';

class AddPortfolioEntryScreen extends StatefulWidget {
  final PortfolioEntry? entry;
  const AddPortfolioEntryScreen({super.key, this.entry});

  @override
  State<AddPortfolioEntryScreen> createState() => _AddPortfolioEntryScreenState();
}

class _AddPortfolioEntryScreenState extends State<AddPortfolioEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ownerController;
  late TextEditingController _weightController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  
  late String _selectedType;
  late DateTime _selectedDate;

  bool get isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _ownerController = TextEditingController(text: widget.entry?.ownerName ?? "Me");
    _weightController = TextEditingController(text: widget.entry?.weight.toString() ?? "");
    _priceController = TextEditingController(text: widget.entry?.buyPricePerGram.toString() ?? "");
    _notesController = TextEditingController(text: widget.entry?.notes ?? "");
    _selectedType = widget.entry?.type ?? '999';
    _selectedDate = widget.entry?.date ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Manage Asset" : "Add to My Assets"),
        centerTitle: true,
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _ownerController,
                label: "Owner Name",
                hint: "e.g. Me, Wife, Mak, Ayah",
                icon: Icons.person_outline,
                maxLength: 15,
                validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 16),
              Text("Type", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildTypeChip('999'),
                  const SizedBox(width: 12),
                  _buildTypeChip('916'),
                  const SizedBox(width: 12),
                  _buildTypeChip('Silver'),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _weightController,
                label: "Weight (grams)",
                hint: "e.g. 1.0",
                icon: Icons.monitor_weight_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                maxLength: 9,
                validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _priceController,
                label: "Buy Price (RM / gram)",
                hint: "e.g. 450",
                icon: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                maxLength: 8,
                validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 10),
              _buildDatePicker(),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _notesController,
                label: "Notes",
                hint: "Where did you buy it?",
                icon: Icons.notes,
                maxLength: 30,
                maxLines: 2, // Reduced from 3
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFfbbf24),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(isEdit ? "Update Asset" : "Save to My Assets", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              // Removed "Sell this Asset" button as requested
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    bool isSelected = _selectedType == type;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFfbbf24) : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFfbbf24) : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2))),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            prefixIcon: Icon(icon, color: const Color(0xFFfbbf24)),
            filled: true,
            fillColor: theme.cardColor,
            counterText: "",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.withOpacity(0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Purchase Date", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: isDark ? null : Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFFfbbf24), size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('d MMMM yyyy').format(_selectedDate),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Asset?"),
        content: const Text("Are you sure you want to remove this asset from your portfolio?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Provider.of<PortfolioProvider>(context, listen: false).deleteEntry(widget.entry!.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close screen
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }


  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      final entry = PortfolioEntry(
        id: isEdit ? widget.entry!.id : const Uuid().v4(),
        ownerName: _ownerController.text.trim(),
        weight: double.parse(_weightController.text),
        buyPricePerGram: double.parse(_priceController.text),
        type: _selectedType,
        date: _selectedDate,
        notes: _notesController.text,
      );

      final provider = Provider.of<PortfolioProvider>(context, listen: false);
      if (isEdit) {
        provider.updateEntry(entry);
      } else {
        provider.addEntry(entry);
      }
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
