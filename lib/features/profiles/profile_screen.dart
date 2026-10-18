import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/widgets/game_review_dialog.dart';

import '../../app/game_assets.dart';
import '../../app/game_theme.dart';
import '../../domain/local_profile.dart';
import '../../data/game_repository.dart';
import '../../shared/widgets/game_brand.dart';
import '../../shared/widgets/game_button.dart';
import '../district/district_screen.dart';
import 'profile_view_model.dart';
import '../../data/app_update_platform.dart';
import 'app_update_view_model.dart';
import 'app_update_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.viewModel,
    required this.games,
    this.updates,
  });
  final ProfileViewModel viewModel;
  final GameRepository games;
  final AppUpdateViewModel? updates;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  late final AppUpdateViewModel _updates;
  Timer? _versionTimer;
  @override
  void initState() {
    super.initState();
    _updates = widget.updates ?? AppUpdateViewModel(createAppUpdateGateway());
    WidgetsBinding.instance.addObserver(this);
    unawaited(_updates.check());
    _versionTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkVersion(),
    );
    unawaited(widget.viewModel.load());
  }

  void _checkVersion() {
    if (mounted &&
        (ModalRoute.of(context)?.isCurrent ?? false) &&
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      unawaited(_updates.check());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkVersion();
  }

  @override
  void dispose() {
    _versionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.updates == null) _updates.dispose();
    super.dispose();
  }

  Future<void> _create(int slot) async {
    if (_updates.syncing) return;
    final profile = await showDialog<LocalProfile>(
      context: context,
      builder: (_) =>
          _CreateDistrictDialog(slot: slot, viewModel: widget.viewModel),
    );
    if (profile != null && mounted) _open(profile);
  }

  Future<void> _open(LocalProfile profile) async {
    if (_updates.syncing) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            DistrictScreen(profile: profile, repository: widget.games),
      ),
    );
    if (mounted) {
      unawaited(_updates.check());
      await widget.viewModel.load();
    }
  }

  Future<void> _delete(LocalProfile profile) async {
    if (_updates.syncing) return;
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _DeleteDistrictDialog(profile: profile, viewModel: widget.viewModel),
    );
    if (deleted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${profile.areaName} deleted. Slot ${profile.slot.toString().padLeft(2, '0')} is available.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          if (_updates.supported) AppUpdateBar(model: _updates),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([widget.viewModel, _updates]),
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
        ],
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
    child: LayoutBuilder(
      builder: (context, constraints) {
        final details = Row(
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
                    style: const TextStyle(
                      fontSize: 15,
                      color: GameColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        final actions = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameButton(
              label: profile == null ? 'New' : 'Load',
              secondary: profile == null,
              onPressed:
                  widget.viewModel.busy ||
                      !widget.viewModel.loaded ||
                      _updates.syncing
                  ? null
                  : () => profile == null ? _create(slot) : _open(profile),
            ),
            if (profile != null)
              TextButton.icon(
                key: ValueKey('delete-profile-$slot'),
                style: TextButton.styleFrom(foregroundColor: GameColors.danger),
                onPressed:
                    widget.viewModel.busy ||
                        !widget.viewModel.loaded ||
                        _updates.syncing
                    ? null
                    : () => _delete(profile),
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Delete'),
              ),
          ],
        );
        return constraints.maxWidth < 280
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [details, const SizedBox(height: 12), actions],
              )
            : Row(
                children: [
                  Expanded(child: details),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
      },
    ),
  );
}

class _DeleteDistrictDialog extends StatefulWidget {
  const _DeleteDistrictDialog({required this.profile, required this.viewModel});
  final LocalProfile profile;
  final ProfileViewModel viewModel;
  @override
  State<_DeleteDistrictDialog> createState() => _DeleteDistrictDialogState();
}

class _DeleteDistrictDialogState extends State<_DeleteDistrictDialog> {
  bool _deleting = false;
  String? _error;
  Future<void> _confirm() async {
    if (_deleting) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.viewModel.delete(widget.profile);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = 'Could not delete this district. Your last saved data is kept. Cancel and refresh the profile list, or try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_deleting,
    child: GameReviewDialog(
      title: 'Delete saved district?',
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.profile.areaName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Slot ${widget.profile.slot.toString().padLeft(2, '0')} · Saved on this device',
            ),
            const SizedBox(height: 16),
            const Text(
              'All buildings, money, tenants and progress in this district will be permanently deleted. This cannot be undone.',
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: GameColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: GameColors.danger),
          onPressed: _deleting ? null : _confirm,
          icon: _deleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.delete_outline),
          label: Text(_deleting ? 'Deleting…' : 'Delete permanently'),
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
    child: GameReviewDialog(
      title: 'New district',
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
