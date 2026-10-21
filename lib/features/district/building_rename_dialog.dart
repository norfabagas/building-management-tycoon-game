import 'package:flutter/material.dart';

import '../../app/game_theme.dart';
import '../../domain/district_game.dart';
import '../../shared/widgets/game_button.dart';
import '../../shared/widgets/game_review_dialog.dart';
import 'district_view_model.dart';

class BuildingRenameDialog extends StatefulWidget {
  const BuildingRenameDialog({
    super.key,
    required this.model,
    required this.building,
  });
  final DistrictViewModel model;
  final ApartmentBuilding building;
  @override
  State<BuildingRenameDialog> createState() => _BuildingRenameDialogState();
}

class _BuildingRenameDialogState extends State<BuildingRenameDialog> {
  late final _name = TextEditingController(text: widget.building.name);
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || widget.model.busy || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.model.renameBuilding(
      widget.building.id,
      _name.text,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _error =
          widget.model.error ?? 'The name could not be saved. Please retry.';
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.model,
    builder: (context, _) => PopScope(
      canPop: !_saving,
      child: GameReviewDialog(
        title: 'Rename building',
        content: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.building.type.label} · ID ${widget.building.id}',
                style: const TextStyle(color: GameColors.muted),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('building-name'),
                controller: _name,
                autofocus: true,
                readOnly: _saving,
                maxLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Building name',
                  helperText: 'Up to 40 characters',
                ),
                validator: (value) => ApartmentBuilding.nameError(value ?? ''),
                onFieldSubmitted: (_) => _save(),
              ),
              if (_error case final error?)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: const TextStyle(color: GameColors.danger),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          GameButton(
            label: _saving ? 'Saving…' : 'Save name',
            onPressed: _saving || widget.model.busy ? null : _save,
          ),
        ],
      ),
    ),
  );
}
