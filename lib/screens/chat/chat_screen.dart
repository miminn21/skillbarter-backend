import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:glossy/glossy.dart';

import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/explore_provider.dart';
import '../explore/user_profile_screen.dart';
import '../../widgets/animated_background.dart';

class ChatScreen extends StatefulWidget {
  final int transactionId;
  final String partnerName;
  final String partnerNik;
  final String? partnerPhoto;

  const ChatScreen({
    Key? key,
    required this.transactionId,
    required this.partnerName,
    required this.partnerNik,
    this.partnerPhoto,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _statusOnline;
  String? _lastActive;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.startAutoRefresh(widget.transactionId);

      // Initial fetch
      _fetchPartnerStatus();

      // Refresh status every 30 seconds
      _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _fetchPartnerStatus();
      });
    });
  }

  Future<void> _fetchPartnerStatus() async {
    final exploreProvider = Provider.of<ExploreProvider>(
      context,
      listen: false,
    );
    final profile = await exploreProvider.getUserProfile(widget.partnerNik);

    if (mounted && profile != null) {
      setState(() {
        _statusOnline = profile.statusOnline;
        _lastActive = profile.terakhirAktif;
      });
    }
  }

  @override
  void deactivate() {
    Provider.of<ChatProvider>(context, listen: false).stopAutoRefresh();
    _statusTimer?.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatLastActive(String? timestamp) {
    if (timestamp == null) return 'Offline';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Baru saja aktif';
      if (diff.inMinutes < 60) return 'Aktif ${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return 'Aktif ${diff.inHours} jam lalu';
      if (diff.inDays == 1) return 'Aktif Kemarin';
      return 'Offline';
    } catch (e) {
      return 'Offline';
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    final success = await Provider.of<ChatProvider>(context, listen: false)
        .sendMessage(
          transactionId: widget.transactionId,
          receiverNik: widget.partnerNik,
          content: content,
        );

    if (success) {
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengirim pesan')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final myNik = authProvider.user?.nik;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(nik: widget.partnerNik),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  backgroundImage: widget.partnerPhoto != null
                      ? MemoryImage(base64Decode(widget.partnerPhoto!))
                      : null,
                  child: widget.partnerPhoto == null
                      ? const Icon(Icons.person, size: 24, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.partnerName,
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (_statusOnline == 'online') ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else ...[
                          Text(
                            _formatLastActive(_lastActive),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.messages.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (provider.messages.isEmpty) {
                      return Center(
                        child: GlossyContainer(
                          height: 150,
                          width: 280,
                          borderRadius: BorderRadius.circular(24),
                          strengthX: 12,
                          strengthY: 12,
                          opacity: 0.1,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Mulai percakapan dengan\n${widget.partnerName}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount: provider.messages.length,
                      itemBuilder: (context, index) {
                        final msg = provider.messages[index];
                        final isMe = msg.nikPengirim == myNik;

                        // Calculate showTime: if first message or time diff > 5 mins
                        bool showTime = false;
                        if (index == 0) {
                          showTime = true;
                        } else {
                          final prevMsg = provider.messages[index - 1];
                          final diff = msg.dibuatPada.difference(
                            prevMsg.dibuatPada,
                          );
                          if (diff.inMinutes > 5) showTime = true;
                        }

                        return Column(
                          children: [
                            if (showTime)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _formatFullDate(msg.dibuatPada),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isMe
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF662D8C),
                                            Color(0xFFED1E79),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(
                                              0.15,
                                            ), // Reduced opacity for transparency
                                            Colors.white.withOpacity(
                                              0.08,
                                            ), // Reduced opacity for transparency
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: isMe
                                        ? const Radius.circular(20)
                                        : Radius.zero,
                                    bottomRight: isMe
                                        ? Radius.zero
                                        : const Radius.circular(20),
                                  ),
                                  border: Border.all(
                                    color: isMe
                                        ? Colors.white.withOpacity(
                                            0.25,
                                          ) // Reduced opacity
                                        : Colors.white.withOpacity(
                                            0.15,
                                          ), // Reduced opacity
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: isMe
                                        ? const Radius.circular(20)
                                        : Radius.zero,
                                    bottomRight: isMe
                                        ? Radius.zero
                                        : const Radius.circular(20),
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 8,
                                      sigmaY: 8,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(
                                          0.15,
                                        ), // Transparent background
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            msg.isiPesan,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                DateFormat('HH:mm').format(
                                                  msg.dibuatPada.toLocal(),
                                                ),
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(
                                                    0.7, // Increased opacity for better visibility
                                                  ),
                                                  fontSize: 10,
                                                ),
                                              ),
                                              if (isMe) ...[
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.done_all,
                                                  size: 14,
                                                  color: Colors.white70,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              // Input Area
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black, // Solid black for the bottom area
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF262626), // Solid dark grey
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded),
                          color: Colors.white,
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();
    final diff = now.difference(localDate);

    if (diff.inDays == 0 && localDate.day == now.day) {
      return 'Hari Ini';
    } else if (diff.inDays == 1 ||
        (diff.inDays == 0 && localDate.day != now.day)) {
      return 'Kemarin';
    } else {
      return DateFormat('dd MMM yyyy').format(localDate);
    }
  }
}
