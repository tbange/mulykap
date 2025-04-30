import 'package:flutter/material.dart';

class LoadingSpinner extends StatelessWidget {
  final String? message;
  
  const LoadingSpinner({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(message!),
            ),
        ],
      ),
    );
  }
} 