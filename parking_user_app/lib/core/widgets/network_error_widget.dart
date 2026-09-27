import 'package:flutter/material.dart';

class NetworkErrorWidget extends StatelessWidget {
  const NetworkErrorWidget({super.key});

  @override
  Widget build(BuildContext context) => Positioned(
    top: MediaQuery.paddingOf(context).top + 4,
    left: 12,
    right: 12,
    child: IgnorePointer(
      child: Material(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(10),
        elevation: 4,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'No internet connection',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
