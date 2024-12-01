import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSvgButton extends StatelessWidget {
  final String svgAsset;
  final VoidCallback onPressed;
  final double buttonWidth;
  final double svgWidth;

  const CustomSvgButton({
    super.key,
    required this.svgAsset,
    required this.onPressed,
    required this.buttonWidth,
    required this.svgWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: buttonWidth,
      child: ElevatedButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 24),
          backgroundColor: const Color(0x336C6C6C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: SvgPicture.asset(
          svgAsset,
          width: svgWidth,
          height: svgWidth,
          color: Colors.white,
        ),
      ),
    );
  }
}
