import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScoreBar extends StatefulWidget {
  final int score;
  final int maxScore;
  final String? label;
  final bool showPercentage;
  final bool animated;

  const ScoreBar({
    super.key,
    required this.score,
    required this.maxScore,
    this.label,
    this.showPercentage = true,
    this.animated = true,
  });

  @override
  State<ScoreBar> createState() => _ScoreBarState();
}

class _ScoreBarState extends State<ScoreBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: (widget.score / widget.maxScore).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animated) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = (widget.score / widget.maxScore).clamp(0.0, 1.0);
    final percentage = (ratio * 100).round();
    
    Color color;
    String statusText;
    
    if (ratio >= 0.8) {
      color = AppTheme.scoreGoodColor;
      statusText = 'Mükemmel Eşleşme';
    } else if (ratio >= 0.6) {
      color = AppTheme.scoreMediumColor;
      statusText = 'İyi Eşleşme';
    } else if (ratio >= 0.4) {
      color = AppTheme.warningColor;
      statusText = 'Orta Eşleşme';
    } else {
      color = AppTheme.scorePoorColor;
      statusText = 'Zayıf Eşleşme';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null || widget.showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.darkGray,
                  ),
                ),
              if (widget.showPercentage)
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        
        // Progress Bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: color.withOpacity(0.2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: widget.animated
                ? AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      );
                    },
                  )
                : LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Status Text
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

