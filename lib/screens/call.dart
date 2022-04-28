import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:videofi/pc.dart';
import 'package:videofi/ws.dart';

class Call extends StatefulWidget {
  const Call({Key? key}) : super(key: key);
  static const String routeName = '/call';

  @override
  State<Call> createState() => _CallState();
}

class _CallState extends State<Call> {
  MediaStream? localStream;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool isFrontCamera = true;
  bool isMuted = false;

  Future<MediaStream> getUserStream() {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': true,
    };

    return navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  @override
  void initState() {
    super.initState();

    final socket = SocketConnection().socket;

    socket.on('callAnswered', (signal) async {
      final pc = await PeerConnection().pc;

      pc.setRemoteDescription(
        RTCSessionDescription(
          signal['sdp'],
          signal['type'],
        ),
      );
    });

    print("initState");
    (() async {
      await localRenderer.initialize();
      getUserStream().then((stream) async {
        setState(() {
          localStream = stream;
          localRenderer.srcObject = localStream;
        });
        final pc = await PeerConnection().pc;
        registerPCEvents(pc);
      });
    })();
  }

  void registerPCEvents(RTCPeerConnection pc) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final remoteId = arguments['remoteId'];
    // Unified-Plan

    // When the remote user adds the stream
    pc.onTrack = (event) {
      if (event.track.kind == 'video') {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    // Let's add our stream
    localStream?.getTracks().forEach((track) {
      pc.addTrack(track, localStream as MediaStream);
    });

    pc.onIceCandidate = (candidate) async {
      final socket = SocketConnection().socket;

      socket.emit(
        "ice-candidate",
        {
          "peerId": remoteId,
          "candidate": {
            "sdpMLineIndex": candidate.sdpMLineIndex,
            "sdpMid": candidate.sdpMid,
            "candidate": candidate.candidate,
          },
        },
      );
    };

    pc.onConnectionState = (state) {
      // if failed restart ice
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        pc.restartIce();
      }
    };

    pc.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        pc.restartIce();
      }
    };
  }

  void onCameraSwitchPressed() async {
    await Helper.switchCamera(localStream!.getVideoTracks().first);

    setState(() {
      isFrontCamera = !isFrontCamera;
    });
  }

  void onMutePressed() {
    if (localStream == null) return;

    final stream = localStream as MediaStream;
    stream.getAudioTracks().first.enabled =
        !stream.getAudioTracks().first.enabled;

    setState(() {
      isMuted = !isMuted;
    });
  }

  void onAnswerPressed() async {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    final socket = SocketConnection().socket;
    final pc = await PeerConnection().pc;

    final signal = arguments['data']['signal'];
    final description = RTCSessionDescription(signal['sdp'], signal['type']);
    await pc.setRemoteDescription(description);

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    socket.emit("answerCall", {
      'callerId': arguments['data']['remoteId'],
      'signal': {
        'type': answer.type,
        'sdp': answer.sdp,
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      body: Container(
        child: Stack(
          fit: StackFit.expand,
          children: [
            RTCVideoView(
              localRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 180),
                  const Icon(Icons.face, size: 80),
                  const SizedBox(height: 18),
                  Text(
                    arguments['data']['remoteId'].toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    {
                      'incoming': 'Incoming...',
                      'outgoing': "Calling...",
                    }[arguments['type']]
                        .toString(),
                    style: const TextStyle(
                      color: Color(0xffdbdbdb),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    color: const Color(0xff300a24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 40,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: arguments['type'] == 'outgoing'
                          ? [
                              CallActionButton(
                                icon: Icons.cameraswitch,
                                onPressed: onCameraSwitchPressed,
                              ),
                              const SizedBox(width: 20),
                              CallActionButton(
                                icon: Icons.call_end,
                                onPressed: () async {
                                  final pc = await PeerConnection().pc;
                                  print(pc.connectionState);
                                },
                              ),
                              const SizedBox(width: 20),
                              CallActionButton(
                                icon: isMuted ? Icons.mic_off : Icons.mic,
                                onPressed: onMutePressed,
                              ),
                            ]
                          : [
                              const CallActionButton(
                                icon: Icons.call_end,
                              ),
                              const SizedBox(width: 20),
                              CallActionButton(
                                icon: Icons.call,
                                onPressed: onAnswerPressed,
                              ),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CallActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  const CallActionButton({Key? key, this.onPressed, required this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 50,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          overlayColor: MaterialStateProperty.all(Colors.grey),
          backgroundColor: MaterialStateProperty.all(Colors.white),
          shape: MaterialStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.black,
        ),
      ),
    );
  }
}
