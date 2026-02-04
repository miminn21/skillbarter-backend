import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:dio/dio.dart';
import 'beautiful_notification.dart';
import '../widgets/status_dialog.dart';

class RatingDialog extends StatefulWidget {
  final String partnerName;
  final Function(int rating, String? comment, bool anonymous) onSubmit;

  const RatingDialog({
    super.key,
    required this.partnerName,
    required this.onSubmit,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 0.0;
  final _commentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      StatusDialog.show(
        context,
        success: false,
        title: 'Rating Kosong',
        message: 'Mohon berikan bintang terlebih dahulu',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        _rating.toInt(),
        _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        _isAnonymous,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        StatusDialog.show(
          context,
          success: true,
          title: 'Rating Terkirim!',
          message: 'Terima kasih atas ulasan Anda',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Terjadi kesalahan saat mengirim rating';

        if (e is DioException) {
          final dioError = e as DioException;
          if (dioError.response?.data != null &&
              dioError.response?.data is Map &&
              (dioError.response?.data as Map)['error'] != null) {
            errorMessage = (dioError.response?.data as Map)['error'];
          } else if (dioError.response?.data != null &&
              dioError.response?.data is Map &&
              (dioError.response?.data as Map)['message'] != null) {
            errorMessage = (dioError.response?.data as Map)['message'];
          }
        }

        BeautifulNotification.show(
          context,
          type: NotificationType.error,
          title: 'Gagal Mengirim',
          message: errorMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                'Beri Rating',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Partner name
              Text(
                'Bagaimana pengalaman Anda dengan\n${widget.partnerName}?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Star rating
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 42,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) =>
                    const Icon(Icons.star_rounded, color: Colors.amber),
                onRatingUpdate: (rating) {
                  setState(() => _rating = rating);
                },
              ),
              const SizedBox(height: 12),

              // Rating text
              AnimatedOpacity(
                opacity: _rating > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _getRatingText(_rating.toInt()),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getRatingColor(_rating.toInt()),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Comment field
              TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Tulis ulasan pengalaman Anda (opsional)...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 8),

              // Anonymous checkbox
              Theme(
                data: ThemeData(
                  checkboxTheme: CheckboxThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                child: CheckboxListTile(
                  value: _isAnonymous,
                  onChanged: (value) {
                    setState(() => _isAnonymous = value ?? false);
                  },
                  title: Text(
                    'Kirim sebagai anonim',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Kirim Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Skip button
              if (!_isSubmitting)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: const Text('Lewati'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Sangat Baik!';
      case 4:
        return 'Baik';
      case 3:
        return 'Cukup';
      case 2:
        return 'Kurang';
      case 1:
        return 'Buruk';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating == 3) return Colors.orange;
    return Colors.red;
  }
}
