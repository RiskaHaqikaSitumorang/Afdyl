import 'package:flutter/material.dart';

class HijaiyahTracingDialog extends StatelessWidget {
  final String letter;
  final String pronunciation;
  final VoidCallback onClose;

  HijaiyahTracingDialog({
    required this.letter,
    required this.pronunciation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        onClose();
        return true;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Latihan Menulis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'OpenDyslexic',
                ),
              ),
              SizedBox(height: 20),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.width * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5DC),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Color(0xFFD4C785), width: 2),
                ),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    // Placeholder untuk tracing (akan membutuhkan CustomPainter untuk garis)
                    print('Tracing at: ${details.localPosition}');
                  },
                  child: Center(
                    child: Text(
                      letter.isNotEmpty ? letter : 'N/A',
                      style: TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                pronunciation.isNotEmpty ? pronunciation : 'N/A',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  fontFamily: 'OpenDyslexic',
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFE8D4A3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Trace dengan jari Anda pada huruf di atas untuk berlatih menulis',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontFamily: 'OpenDyslexic',
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD4C785),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Text(
                  'Selesai',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'OpenDyslexic',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}