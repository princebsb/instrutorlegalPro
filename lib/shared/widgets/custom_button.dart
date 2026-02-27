import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum ButtonVariant { primary, secondary, outline, text, danger }

enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final IconData? trailingIcon;
  final Color? customColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.trailingIcon,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final textStyle = _getTextStyle();
    final padding = _getPadding();
    final height = _getHeight();

    Widget child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == ButtonVariant.primary ? AppColors.white : AppColors.primary,
              ),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: _getIconSize()),
            const SizedBox(width: 8),
          ],
          Text(text, style: textStyle),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(trailingIcon, size: _getIconSize()),
          ],
        ],
      ],
    );

    switch (variant) {
      case ButtonVariant.primary:
        return SizedBox(
          width: fullWidth ? double.infinity : null, height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: Padding(padding: padding, child: child),
          ),
        );
      case ButtonVariant.secondary:
        return SizedBox(
          width: fullWidth ? double.infinity : null, height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle.copyWith(
              backgroundColor: WidgetStateProperty.all(AppColors.primarySurface),
              foregroundColor: WidgetStateProperty.all(AppColors.primary),
            ),
            child: Padding(padding: padding, child: child),
          ),
        );
      case ButtonVariant.outline:
        return SizedBox(
          width: fullWidth ? double.infinity : null, height: height,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: Padding(padding: padding, child: child),
          ),
        );
      case ButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          child: Padding(padding: padding, child: child),
        );
      case ButtonVariant.danger:
        return SizedBox(
          width: fullWidth ? double.infinity : null, height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle.copyWith(
              backgroundColor: WidgetStateProperty.all(AppColors.error),
            ),
            child: Padding(padding: padding, child: child),
          ),
        );
    }
  }

  ButtonStyle _getButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: customColor ?? AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  TextStyle _getTextStyle() {
    double fontSize;
    switch (size) {
      case ButtonSize.small: fontSize = 13; break;
      case ButtonSize.medium: fontSize = 15; break;
      case ButtonSize.large: fontSize = 17; break;
    }
    return TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600);
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small: return const EdgeInsets.symmetric(horizontal: 12, vertical: 4);
      case ButtonSize.medium: return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.large: return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small: return 40;
      case ButtonSize.medium: return 52;
      case ButtonSize.large: return 60;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small: return 16;
      case ButtonSize.medium: return 20;
      case ButtonSize.large: return 24;
    }
  }
}

class IconButtonRound extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final String? tooltip;

  const IconButtonRound({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primarySurface,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor ?? AppColors.primary, size: size * 0.5),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
