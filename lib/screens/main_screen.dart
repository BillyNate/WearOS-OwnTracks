import 'package:flutter/material.dart';
import 'package:flutter_wearos_owntracks/content_state_provider.dart';
import 'package:provider/provider.dart';
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
              Consumer<ContentStateProvider>(
                  builder: (context, viewModel, child) {
                return Column(
                  children: [
                    Text(
                        'Battery is at ${viewModel.batteryLevel != 0 ? viewModel.batteryLevel : 'unknown level'}%'),
                    Text(
                        'Foreground task is ${viewModel.foregroundTaskRunningState ? '' : 'not'} running'),
                    Text(
                        'Activity: ${viewModel.activityState.type.name}, chance is ${viewModel.activityState.confidence.name}'),
                    Text(
                        'Connected to ${viewModel.connectivityState.name}${viewModel.networkInfoData != null && viewModel.connectivityState.name == 'wifi' ? ' (${viewModel.networkInfoData?.wifiName})' : ''}'),
                    Text(
                        'MQTT is ${viewModel.mqttConnectedState ? 'connected to' : 'disconnected from'} server'),
                  ],
                );
              }),
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
