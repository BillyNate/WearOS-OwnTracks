import 'package:flutter/material.dart';
import 'package:wear/wear.dart';

class MainContentView extends StatefulWidget {
  const MainContentView({super.key});

  @override
  State<MainContentView> createState() => _MainContentViewState();
}

class _MainContentViewState extends State<MainContentView> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: WatchShape(
        builder: (BuildContext context, WearShape shape, Widget? child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                'Shape: ${shape == WearShape.round ? 'round' : 'square'}',
              ),
              child!,
            ],
          );
        },
        child: AmbientMode(
          builder: (BuildContext context, WearMode mode, Widget? child) {
            return Text(
              'Mode: ${mode == WearMode.active ? 'Active' : 'Ambient'}',
            );
          },
        ),
      ),
    );
  }
}
