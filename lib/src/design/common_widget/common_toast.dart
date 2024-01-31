import 'package:divyanshu_assignment/src/core/configuration.dart';

void showToast(BuildContext context, {String? msg}) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(moreThanOneFace)));
