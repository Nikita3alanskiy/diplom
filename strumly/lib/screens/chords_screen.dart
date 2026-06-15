import 'package:flutter/material.dart';
import '../widgets/chord_diagram.dart';
import '../models/chord_dictionary.dart';

class ChordsScreen extends StatelessWidget {
  const ChordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chords = ChordDictionary.chords;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("АКОРДИ",
            style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: chords.length,
        itemBuilder: (context, index) {
          final chord = chords[index];
          return Container(
            padding: const EdgeInsets.only(top: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ChordDiagram(
              chordName: chord['name'],
              positions: chord['pos'],
              size: 100,
            ),
          );
        },
      ),
    );
  }
}
