import 'package:flutter/material.dart';

/// Toggle placed below the map compass to switch oblique 3D camera view.
class ThreeDToggle extends StatelessWidget {
  const ThreeDToggle({
    super.key,
    required this.active,
    required this.busy,
    required this.onPressed,
  });

  final bool active;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final onSurface = active ? Colors.white : const Color(0xFF2D3748);

    return Semantics(
      button: true,
      enabled: !busy,
      label: active ? 'Disable 3D view' : 'Enable 3D view',
      child: Tooltip(
        message: active ? 'Switch to 2D' : 'Switch to 3D',
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(4),
          color: active ? const Color(0xFF2D3748) : Colors.white,
          child: InkWell(
            onTap: busy ? null : onPressed,
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: busy
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: onSurface,
                        ),
                      )
                    : Text(
                        '3D',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
