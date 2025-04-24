import 'package:flutter/material.dart';

class ScrollToBottomButton extends StatelessWidget {
  final int newMessagesCount;
  final VoidCallback onPressed;

  const ScrollToBottomButton({
    Key? key,
    required this.newMessagesCount,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 70,
      right: 20,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          FloatingActionButton.small(
            backgroundColor: Colors.blue,
            child: Icon(Icons.arrow_downward),
            onPressed: onPressed,
          ),
          if (newMessagesCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                child: Center(
                  child: Text(
                    '$newMessagesCount',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
