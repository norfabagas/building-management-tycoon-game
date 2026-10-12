import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/game_assets.dart';
import '../../app/game_theme.dart';
import '../../domain/local_profile.dart';
import '../../shared/widgets/game_brand.dart';
import '../../shared/widgets/game_button.dart';
import '../district/district_screen.dart';
import 'profile_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.viewModel});
  final ProfileViewModel viewModel;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.viewModel.load());
  }

  Future<void> _create(int slot) async {
    final profile = await showDialog<LocalProfile>(
      context: context,
      builder: (_) =>
          _CreateDistrictDialog(slot: slot, viewModel: widget.viewModel),
    );
    if (profile != null && mounted) _open(profile);
  }

  void _open(LocalProfile profile) => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => DistrictScreen(profile: profile)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: AnimatedBuilder(
        animation: widget.viewModel,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final introduction = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GameBrand(size: wide ? 72 : 48, fontSize: wide ? 36 : 28),
                const SizedBox(height: 24),
                const Text(
                  'Build and manage your district.',
                  style: TextStyle(fontSize: 22, color: GameColors.muted),
                ),
                const SizedBox(height: 24),
                Image.asset(
                  GameAssets.district,
                  fit: BoxFit.contain,
                  semanticLabel: 'Illustrated district with apartments, a hotel, offices and a food court',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Progress saves on this device.',
                  style: TextStyle(fontSize: 18, color: GameColors.muted),
                ),
              ],
            );
            final slots = _slots();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: introduction),
                            const SizedBox(width: 48),
                            Expanded(child: slots),
                          ],
                        )
                      : Column(
                          children: [
                            introduction,
                            const SizedBox(height: 32),
                            slots,
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _slots() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: GameColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: GameColors.border, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a district',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        const Divider(color: GameColors.border),
        if (widget.viewModel.busy) const LinearProgressIndicator(),
        if (widget.viewModel.error case final error?) ...[
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(color: GameColors.danger, fontSize: 18),
          ),
          const SizedBox(height: 16),
          GameButton(
            label: 'Retry',
            onPressed: widget.viewModel.busy ? null : widget.viewModel.load,
          ),
        ] else ...[
          for (
            var index = 0;
            index < widget.viewModel.profiles.length;
            index++
          ) ...[
            const SizedBox(height: 12),
            _slot(index + 1, widget.viewModel.profiles[index]),
          ],
        ],
      ],
    ),
  );

  Widget _slot(int slot, LocalProfile? profile) => Container(
    key: ValueKey('profile-slot-$slot'),
    padding: const EdgeInsets.all(12),
    constraints: const BoxConstraints(minHeight: 88),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: GameColors.border, width: 2),
    ),
    child: Row(
      children: [
        Text(
          slot.toString().padLeft(2, '0'),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.areaName ?? 'Empty slot',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile == null
                    ? 'Start a new district'
                    : 'Saved on this device',
                style: const TextStyle(fontSize: 15, color: GameColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GameButton(
          label: profile == null ? 'New' : 'Load',
          secondary: profile == null,
          onPressed: widget.viewModel.busy || !widget.viewModel.loaded
              ? null
              : () => profile == null ? _create(slot) : _open(profile),
        ),
      ],
    ),
  );
}

class _CreateDistrictDialog extends StatefulWidget {
  const _CreateDistrictDialog({required this.slot, required this.viewModel});
  final int slot;
  final ProfileViewModel viewModel;

  @override
  State<_CreateDistrictDialog> createState() => _CreateDistrictDialogState();
}

class _CreateDistrictDialogState extends State<_CreateDistrictDialog> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = await widget.viewModel.create(
        slot: widget.slot,
        areaName: _name.text,
      );
      if (mounted) Navigator.of(context).pop(profile);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'This district could not be saved. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      backgroundColor: GameColors.surface,
      title: const Text('New district'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Slot ${widget.slot.toString().padLeft(2, '0')}',
                style: const TextStyle(color: GameColors.muted),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('district-name'),
                controller: _name,
                autofocus: true,
                readOnly: _saving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'District name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a district name.'
                    : null,
                onFieldSubmitted: (_) => _save(),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 16),
                Text(error, style: const TextStyle(color: GameColors.danger)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        GameButton(
          label: _saving ? 'Saving…' : 'Create district',
          onPressed: _saving ? null : _save,
        ),
      ],
    ),
  );
}
