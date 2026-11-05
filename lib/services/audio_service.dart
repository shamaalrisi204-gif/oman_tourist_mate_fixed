import 'package:firebase_storage/firebase_storage.dart';

import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer player = AudioPlayer();

  Future<void> playAudio(String storagePath) async {
    try {
      final ref = FirebaseStorage.instance.ref(storagePath);

      final downloadUrl = await ref.getDownloadURL();

      await player.setUrl(downloadUrl);

      await player.play();
    } catch (e) {
      print('Audio playback error: $e');

      rethrow;
    }
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> resume() async {
    await player.play();
  }

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> dispose() async {
    await player.dispose();
  }
}
