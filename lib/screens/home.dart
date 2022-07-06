import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:videofi/components/connecting_overlay.dart';
import 'package:videofi/id_display.dart';
import 'package:videofi/pc.dart';
import 'package:videofi/screens/call.dart';
import 'package:videofi/ws.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);
  static const String routeName = '/dashboard';

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController remoteIdController = TextEditingController();
  bool isWSConnected = false;

  int? localId;
  MediaStream? localStream;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  dynamic callData;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    super.dispose();
    localStream?.dispose();
    localRenderer.dispose();
    remoteRenderer.dispose();
    SocketConnection().socket.dispose();
    PeerConnection().pc.then((pc) => pc.dispose());
  }

  void wsOnConnect(dynamic _) {
    final socket = SocketConnection().socket;
    socket.emit("join");
  }

  void wsOnJoined(dynamic id) {
    setState(() {
      localId = id;
      isWSConnected = true;
    });
  }

  void wsOnDisconnect(dynamic _) {
    setState(() {
      isWSConnected = false;
    });
  }

  void wsOnCallReceived(dynamic data) async {
    print("call received");
    remoteIdController.text = data['callerId'].toString();
    localStream = await getUserStream();

    final pc = await PeerConnection().pc;
    registerPCEvents(pc);

    setState(() {
      callData = data;
    });
  }

  void onAnswerPressed() async {
    final data = callData;

    final pc = await PeerConnection().pc;
    final signal = data['signal'];
    final description = RTCSessionDescription(signal['sdp'], signal['type']);
    await pc.setRemoteDescription(description);

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    print('answered call');
    final socket = SocketConnection().socket;
    socket.emit("answerCall", {
      'callerId': data['callerId'],
      'signal': {
        'sdp': answer.sdp,
        'type': answer.type,
      },
    });
  }

  void initialize() async {
    final socket = SocketConnection().socket;

    socket.on("connect", wsOnConnect);
    socket.on("join/callback", wsOnJoined);
    socket.on("disconnect", wsOnDisconnect);

    // Signaling events
    socket.on("peerIsCalling", wsOnCallReceived);
    socket.on("ice-candidate", (candidate) async {
      if (candidate['candidate'] == null) return;
      final iceCandidate = RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      );
      final pc = await PeerConnection().pc;
      await pc.addCandidate(iceCandidate);
    });
    socket.on("callAnswered", (signal) async {
      print("call answered");
      final pc = await PeerConnection().pc;

      final description = RTCSessionDescription(signal['sdp'], signal['type']);
      await pc.setRemoteDescription(description);
    });
  }

  Future<MediaStream> getUserStream() {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': true,
    };

    return navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  void registerPCEvents(RTCPeerConnection pc) {
    // Unified-Plan

    // When the remote user adds the stream
    pc.onTrack = (event) {
      if (event.track.kind == 'video') {
        print("track received");
        setState(() {
          remoteRenderer.srcObject = event.streams[0];
        });
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
          "peerId": remoteIdController.text,
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

  void onCallPressed() async {
    final remoteId = remoteIdController.text;
    if (remoteId.length < 6) return;

    // Navigator.pushNamed(context, Call.routeName, arguments: {
    //   'type': 'outgoing',
    //   'data': {
    //     'remoteId': remoteId,
    //   }
    // });
    localStream = await getUserStream();

    final pc = await PeerConnection().pc;
    registerPCEvents(pc);

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    final socket = SocketConnection().socket;
    socket.emit("callPeer", {
      "peerId": remoteId,
      "signal": {
        "type": offer.type,
        "sdp": offer.sdp,
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isWSConnected == false) {
      return const Scaffold(
          body: SafeArea(
        child: ConnectingOverlay(),
      ));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Image.asset(
              'images/globe.png',
              height: 221,
            ),
            const Text(
              'Your ID',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  localId == null
                      ? const SizedBox()
                      : IDDisplay(localId.toString()),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 285,
                    child: Material(
                      shadowColor: Colors.white,
                      child: TextField(
                        controller: remoteIdController,
                        showCursor: true,
                        // readOnly: true,
                        autofocus: true,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        keyboardType: TextInputType.number,
                        cursorColor: Colors.white,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 20),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: "Remote ID",
                          hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontFamily: 'SpaceMono',
                              fontSize: 20),
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          filled: true,
                          enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: Colors.white)),
                          focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: Colors.white)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                TextButton(
                  onPressed: onAnswerPressed,
                  child: const Text("Answer"),
                ),
                TextButton(
                  onPressed: () async {
                    final pc = await PeerConnection().pc;
                    print(pc.connectionState);
                    print(remoteRenderer.srcObject != null);
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
            Numpad(
              controller: remoteIdController,
              onSubmit: onCallPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class Numpad extends StatelessWidget {
  const Numpad({Key? key, required this.controller, this.onSubmit})
      : super(key: key);

  final TextEditingController controller;
  final VoidCallback? onSubmit;

  void onNumPressed(int num) {
    final int cursorPos = controller.selection.baseOffset;
    controller.text = controller.text.substring(0, cursorPos) +
        '$num' +
        controller.text.substring(cursorPos);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: cursorPos + 1));
  }

  void onBackspacePressed() {
    // Remove the last character from the cursor position
    final int cursorPos = controller.selection.baseOffset;
    controller.text = controller.text.substring(0, cursorPos - 1) +
        controller.text.substring(cursorPos);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: cursorPos - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 44),
      color: const Color(0xff333134),
      child: GridView.count(
        crossAxisCount: 6,
        children: [
          for (int i = 1; i <= 5; i++)
            KeypadButton(
              child: KeypadNum(i),
              onPressed: () => onNumPressed(i),
            ),
          KeypadButton(
            child: const Icon(
              Icons.close,
              color: Colors.white,
            ),
            onPressed: onBackspacePressed,
          ),
          for (int i = 6; i <= 9; i++)
            KeypadButton(
              child: KeypadNum(i),
              onPressed: () => onNumPressed(i),
            ),
          KeypadButton(
              child: const KeypadNum(0), onPressed: () => onNumPressed(0)),
          KeypadButton(
            child: const Icon(
              Icons.video_call,
              color: Colors.black,
            ),
            color: Colors.white,
            onPressed: onSubmit,
          ),
        ],
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
    );
  }
}

class KeypadButton extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onPressed;
  const KeypadButton(
      {Key? key, required this.child, this.onPressed, this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        overlayColor: MaterialStateProperty.all(Colors.grey),
        backgroundColor: MaterialStateProperty.all(
          color ?? const Color(0xff4e4c50),
        ),
      ),
      child: child,
    );
  }
}

class KeypadNum extends StatelessWidget {
  final int number;
  const KeypadNum(
    this.number, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      '$number',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
