import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerDialog extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerDialog({Key? key, required this.audioUrl}) : super(key: key);

  @override
  State<AudioPlayerDialog> createState() => _AudioPlayerDialogState();
}

class _AudioPlayerDialogState extends State<AudioPlayerDialog> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _player = AudioPlayer();

    try {
      _player.playbackEventStream.listen((event) {
        if (mounted) {
          setState(() {
            _duration = event.duration ?? Duration.zero;
            _position = event.updatePosition;
            _isPlaying = _player.playing;
          });
        }
      });

      // ⏱ Add timeout to prevent infinite hang
      await _player
          .setUrl(widget.audioUrl)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Audio load timeout'),
          );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load audio: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Future<void> _initializePlayer() async {
  //   _player = AudioPlayer();

  //   try {
  //     // Set up listeners
  //     _player.playbackEventStream.listen((event) {
  //       if (mounted) {
  //         setState(() {
  //           _duration = event.duration ?? Duration.zero;
  //           _position = event.updatePosition;
  //           _isPlaying = _player.playing;
  //         });
  //       }
  //     });

  //     // Load the audio
  //     // await _player.setUrl(widget.audioUrl);
  //     await _player
  //         .setUrl(widget.audioUrl)
  //         .timeout(
  //           const Duration(seconds: 30),
  //           onTimeout: () => throw Exception('Audio load timeout'),
  //         );

  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  //   // catch (e) {
  //   //   if (mounted) {
  //   //     setState(() {
  //   //       _error = 'Failed to load audio: $e';
  //   //       _isLoading = false;
  //   //     });
  //   //   }
  //   // }
  //   catch (e) {
  //     String message = 'Unknown error';
  //     if (e is PlayerException) {
  //       message = 'Player error: ${e.message}';
  //     } else if (e is PlayerInterruptedException) {
  //       message = 'Connection interrupted';
  //     } else {
  //       message = 'General error: $e';
  //     }

  //     setState(() {
  //       _error = message;
  //       _isLoading = false;
  //     });
  //   }
  // }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (e) {
      setState(() {
        _error = 'Playback error: $e';
      });
    }
  }

  Future<void> _seek(Duration position) async {
    await _player.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Audio Player'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading audio...'),
                ],
              )
            else if (_error != null)
              Column(
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center),
                ],
              )
            else ...[
              // Progress slider
              // Slider(
              //   value: _position.inMilliseconds.toDouble(),
              //   max: _duration.inMilliseconds.toDouble(),
              //   onChanged: (value) {
              //     _seek(Duration(milliseconds: value.toInt()));
              //   },
              // ),
              Slider(
                min: 0.0,
                max: _duration.inMilliseconds.toDouble(),
                value: min(
                  _position.inMilliseconds.toDouble(),
                  _duration.inMilliseconds.toDouble(),
                ),
                onChanged: (value) {
                  _seek(Duration(milliseconds: value.toInt()));
                },
              ),
              // Time display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position)),
                  Text(_formatDuration(_duration)),
                ],
              ),

              const SizedBox(height: 16),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _seek(Duration.zero),
                    icon: const Icon(Icons.replay),
                    tooltip: 'Restart',
                  ),
                  IconButton(
                    onPressed: _togglePlayPause,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 48,
                    tooltip: _isPlaying ? 'Pause' : 'Play',
                  ),
                  IconButton(
                    onPressed: () async {
                      await _player.stop();
                      await _seek(Duration.zero);
                    },
                    icon: const Icon(Icons.stop),
                    tooltip: 'Stop',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _player.stop();
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
