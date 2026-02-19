import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'audio_cue_service.dart';

class AudioplayersAudioCueService implements AudioCueService {
  AudioplayersAudioCueService({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> playPhaseCompleteCue() async {
    try {
      await _player.play(AssetSource('audio/phase_complete.wav'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }
}
