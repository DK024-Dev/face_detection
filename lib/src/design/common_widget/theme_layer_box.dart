import 'package:divyanshu_assignment/src/core/configuration.dart';

class ThemeLayerBox extends StatelessWidget {
  const ThemeLayerBox({super.key, required this.text, this.onTap});
  final String text;
  final GestureLongPressCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: 60,
        margin: const EdgeInsets.only(right: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ColorConstant.whiteColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
