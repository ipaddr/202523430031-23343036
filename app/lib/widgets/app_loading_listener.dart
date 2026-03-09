import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/loading_bloc.dart';
import 'loading_widgets.dart';

/// AppLoadingListener - shows/hides loading overlay based on LoadingBloc state
class AppLoadingListener extends StatelessWidget {
  final Widget child;

  const AppLoadingListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoadingBloc, LoadingState>(
      listener: (context, state) {
        // Handle loading states if needed for bottom sheet or other UI
      },
      child: Stack(
        children: [
          child,
          // Loading overlay on top
          BlocBuilder<LoadingBloc, LoadingState>(
            builder: (context, state) {
              if (state is LoadingStateLoading) {
                return LoadingOverlay(
                  message: state.message,
                  progress: state.progress > 0 ? state.progress : null,
                  showProgress: state.progress > 0 && state.progress < 1.0,
                  dismissible: false,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
