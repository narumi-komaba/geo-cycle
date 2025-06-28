import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;

  const CustomAppBar({
    this.title,
    this.showBackButton = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFFA410),
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(color: Colors.white),
            )
          : Image.asset(
              'assets/images/GeoCycle_logo.png',
              height: 50,
              alignment: Alignment.centerLeft,
            ),
      centerTitle: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          color: const Color(0xFFFFA410), // オレンジ線
          height: 2,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 2);
}
