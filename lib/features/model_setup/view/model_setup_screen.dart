import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_router.dart';
import '../../../app/app_theme.dart';
import '../../../core/constants/model_config.dart';
import '../viewmodel/model_setup_state.dart';
import '../viewmodel/model_setup_viewmodel.dart';

/// One-time model install (PRD §21): explains the download, warns before
/// spending mobile data, shows progress, and recovers from failure — rather
/// than crashing or silently downloading during a translation.
class ModelSetupScreen extends ConsumerStatefulWidget {
  const ModelSetupScreen({super.key});

  @override
  ConsumerState<ModelSetupScreen> createState() => _ModelSetupScreenState();
}

class _ModelSetupScreenState extends ConsumerState<ModelSetupScreen> {
  /// Guards against pushing home twice — `build` can observe `ready` more than
  /// once before the navigation actually takes effect.
  bool _navigated = false;

  /// Navigating from `build` isn't allowed, so defer to after the frame.
  void _goHomeWhenReady(ModelSetupState state) {
    if (!state.isReady || _navigated) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(modelSetupViewModelProvider);
    final viewModel = ref.read(modelSetupViewModelProvider.notifier);

    // Checked on every build rather than via `ref.listen`: when the model is
    // already installed the load can finish before this screen's first frame,
    // and a listener only reports *changes*, so it would miss it entirely and
    // strand the user here.
    _goHomeWhenReady(state);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.primaryPurple),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.download_for_offline_outlined,
                size: 64,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(height: 24),
              Text(
                _titleFor(state.status),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _bodyFor(state),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _Body(state: state, viewModel: viewModel),
            ],
          ),
        ),
      ),
    );
  }

  String _titleFor(ModelSetupStatus status) => switch (status) {
    ModelSetupStatus.checking => 'Checking…',
    ModelSetupStatus.needsDownload => 'Set up offline translation',
    ModelSetupStatus.downloading => 'Downloading…',
    ModelSetupStatus.loading => 'Preparing the model…',
    ModelSetupStatus.ready => 'Ready',
    ModelSetupStatus.error => 'Something went wrong',
    ModelSetupStatus.unsupportedDevice => 'This device isn\'t supported',
  };

  String _bodyFor(ModelSetupState state) => switch (state.status) {
    ModelSetupStatus.checking =>
      'Looking for the translation model on this device.',
    ModelSetupStatus.needsDownload =>
      'Linguago needs a one-time ${ModelConfig.downloadSizeGb} GB download. '
          'After that, every translation happens on your device  no internet, '
          'and nothing you say ever leaves your phone.\n\n'
          'This download cannot be resumed. If it is interrupted it starts over, '
          'so use a Wi-Fi connection you can stay on.',
    ModelSetupStatus.downloading =>
      'This only happens once. The download cannot resume if interrupted, '
          'so keep the app open.',
    ModelSetupStatus.loading => 'Loading the model into memory.',
    ModelSetupStatus.ready => 'You can start translating.',
    ModelSetupStatus.error => state.errorMessage ?? 'Unknown error.',
    ModelSetupStatus.unsupportedDevice =>
      '${state.errorMessage ?? 'This device does not have enough memory.'}\n\n'
          'Linguago runs its translation model entirely on your phone, which '
          'needs more memory than this device has.',
  };
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.viewModel});

  final ModelSetupState state;
  final ModelSetupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ModelSetupStatus.checking:
      case ModelSetupStatus.loading:
      case ModelSetupStatus.ready:
        return const Center(child: CircularProgressIndicator());

      // Deliberately offers no action: there is nothing the user can do, and a
      // retry button would only invite them to burn 2.6 GB reaching a crash.
      case ModelSetupStatus.unsupportedDevice:
        return const _Notice(
          icon: Icons.memory_rounded,
          color: AppColors.error,
          message: 'Try Linguago on a device with more memory.',
        );

      case ModelSetupStatus.needsDownload:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.connection == ConnectionKind.none)
              const _Notice(
                icon: Icons.wifi_off_rounded,
                color: AppColors.error,
                message:
                    "You're offline. Connect to Wi-Fi to download the model.",
              )
            else if (state.shouldWarnAboutData)
              const _Notice(
                icon: Icons.signal_cellular_alt_rounded,
                color: AppColors.highlightYellow,
                message:
                    "You're on cellular data. Wi-Fi is strongly recommended "
                    'for a download this size.',
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: state.connection == ConnectionKind.none
                  ? null
                  : () => _confirmThenDownload(context),
              child: Text('Download ${ModelConfig.downloadSizeGb} GB'),
            ),
          ],
        );

      case ModelSetupStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                // value: null = indeterminate while HF CDN is resolving (progress stays
                // at 0 % during the redirect handshake, which can take several minutes).
                value: state.progress == 0 ? null : state.progress / 100,
                minHeight: 10,
                backgroundColor: AppColors.surface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${state.progress}%  ·  '
              '${(ModelConfig.downloadSizeGb * state.progress / 100).toStringAsFixed(1)} GB '
              'of ${ModelConfig.downloadSizeGb} GB',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGray),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: viewModel.cancelDownload,
              child: const Text('Cancel'),
            ),
          ],
        );

      case ModelSetupStatus.error:
        return ElevatedButton(
          onPressed: viewModel.check,
          child: const Text('Try again'),
        );
    }
  }

  Future<void> _confirmThenDownload(BuildContext context) async {
    if (state.shouldWarnAboutData) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Download over cellular?'),
          content: Text(
            'This will use about ${ModelConfig.downloadSizeGb} GB of mobile data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Wait for Wi-Fi'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Download anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    await viewModel.download();
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
