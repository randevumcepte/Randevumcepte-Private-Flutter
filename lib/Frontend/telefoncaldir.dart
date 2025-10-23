import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
AudioPlayer _audioPlayer = AudioPlayer();

Future<void> playRingtone() async {
  try {
    // Load and play the ringtone (you can use network or local assets)
    await _audioPlayer.play(AssetSource('audio/ring.mp3'), volume: 1.0);
  } catch (e) {
    log("Error playing ringtone: $e");
  }
}

Future<void> stopRingtone() async {
  try {
    // Stop playing the ringtone
    await _audioPlayer.stop();
  } catch (e) {
    log("Error stopping ringtone: $e");
  }
}