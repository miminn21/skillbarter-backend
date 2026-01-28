import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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
  double _rating = 5.0;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih rating terlebih dahulu')),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim rating: $e')));
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Beri Rating',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Partner name
            Text(
              'Bagaimana pengalaman Anda dengan ${widget.partnerName}?',
              style: Theme.of(context).textTheme.bodyMedium,
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
              itemSize: 48,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() => _rating = rating);
              },
            ),
            const SizedBox(height: 8),

            // Rating text
            Text(
              _getRatingText(_rating.toInt()),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: _getRatingColor(_rating.toInt()),
              ),
            ),
            const SizedBox(height: 24),

            // Comment field
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Tulis ulasan Anda (opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),

            // Anonymous checkbox
            CheckboxListTile(
              value: _isAnonymous,
              onChanged: (value) {
                setState(() => _isAnonymous = value ?? false);
              },
              title: const Text('Kirim sebagai anonim'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Kirim Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Skip button
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Lewati'),
            ),
          ],
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
