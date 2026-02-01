import 'package:flutter/material.dart';

enum SubmitButtonStyle { elevated, outlined, text }

class SubmitButtonStylesWidget extends StatelessWidget {
  const SubmitButtonStylesWidget({
    required this.style,
    super.key,
    this.textButton = 'Submit',
    this.textButtonSize, // New property for height
    this.child,
    this.isLoading = false,
    this.onPressed,
    this.primaryColor,
    this.height, // New property for height
    this.width, // New property for width
    this.radius = 8.0, // New property for button radius
    this.icon, // New property for custom icon
    this.useGradient = false, // New property to use gradient
    this.gradient,
    this.textButtonColor, // New property for custom gradient
  });

  final SubmitButtonStyle style;
  final String? textButton;
  final double? textButtonSize; // New property for height
  final Color? textButtonColor;
  final Widget? child;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color? primaryColor;
  final double? height; // New property for height
  final double? width; // New property for width
  final double radius; // New property for button radius
  final Widget? icon; // New property for custom icon
  final bool useGradient; // New property to use gradient
  final Gradient? gradient; // New property for custom gradient

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case SubmitButtonStyle.elevated:
        return _elevatedButton(context);
      case SubmitButtonStyle.outlined:
        return _outlinedButton(context);
      case SubmitButtonStyle.text:
        return _textButton(context);
    }
  }

  Widget _elevatedButton(BuildContext context) {
    final buttonChild = isLoading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) icon!,
              SizedBox(width: icon != null ? 8.0 : 0.0),
              child ??
                  Text(
                    textButton!,
                    style: TextStyle(
                      color: textButtonColor ?? Colors.white,
                      fontSize: textButtonSize,
                    ),
                  ),
            ],
          );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: useGradient ? Colors.transparent : primaryColor,
        elevation: 0,
        padding: EdgeInsets.zero, // penting untuk gradient
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      child: buttonChild,
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 36.0,
      child: useGradient
          ? Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: button,
              ),
            )
          : button,
    );
  }

  Widget _outlinedButton(BuildContext context) {
    final theme = Theme.of(context);

    final buttonChild = isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                primaryColor ?? theme.primaryColor,
              ),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) icon!,
              SizedBox(width: icon != null ? 8.0 : 0.0),
              child ??
                  Text(
                    textButton!,
                    style: TextStyle(
                      color: textButtonColor ?? primaryColor,
                      fontSize: textButtonSize,
                    ),
                  ),
            ],
          );

    // If gradient is enabled, wrap with gradient border
    if (useGradient && gradient != null) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height ?? 36.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Container(
            margin: const EdgeInsets.all(2), // Border width
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius - 2),
            ),
            child: TextButton(
              onPressed: isLoading ? null : onPressed,
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius - 2),
                ),
              ),
              child: buttonChild,
            ),
          ),
        ),
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        side: BorderSide(
          color: onPressed == null
              ? theme.disabledColor
              : primaryColor ?? theme.primaryColor,
        ),
        minimumSize: Size(width ?? double.infinity, height ?? 36.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      child: buttonChild,
    );
  }

  Widget _textButton(BuildContext context) {
    final theme = Theme.of(context);

    // Build gradient text widget if gradient is enabled
    Widget buildGradientText(String text) {
      return ShaderMask(
        shaderCallback: (bounds) => gradient!.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white, // This color will be masked by gradient
            fontSize: textButtonSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final buttonChild = isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                primaryColor ?? theme.primaryColor,
              ),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) icon!,
              SizedBox(width: icon != null ? 8.0 : 0.0),
              child ??
                  (useGradient && gradient != null
                      ? buildGradientText(textButton!)
                      : Text(
                          textButton!,
                          style: TextStyle(
                            color: textButtonColor ?? primaryColor,
                            fontSize: textButtonSize,
                          ),
                        )),
            ],
          );

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: Size(width ?? double.infinity, height ?? 36.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      child: buttonChild,
    );
  }
}
