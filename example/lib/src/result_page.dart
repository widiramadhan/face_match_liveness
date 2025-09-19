import 'dart:io';
import 'package:example/src/widget/action_button.dart';
import 'package:example/src/widget/info_section.dart';
import 'package:example/src/widget/photo_comparison.dart';
import 'package:example/src/widget/result_message.dart';
import 'package:example/src/widget/similarity_card.dart';
import 'package:flutter/material.dart';
import 'package:example/src/main_page.dart';

class ResultPage extends StatefulWidget {
  final File imageFile1;
  final File imageFile2;
  final double similarity;
  final ComparisonMode mode;

  const ResultPage({
    super.key,
    required this.imageFile1,
    required this.imageFile2,
    required this.similarity,
    required this.mode,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool isSame = false;

  @override
  void initState() {
    super.initState();
    isSame = widget.similarity >= 50; // pakai threshold langsung
  }

  @override
  Widget build(BuildContext context) {
    final messages = ResultMessage.getMessages(
      isSame: isSame,
      mode: widget.mode,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (widget.similarity > 0)
              SimilarityCard(similarity: widget.similarity, isSame: isSame),
            const SizedBox(height: 16),
            InfoSection(isSame: isSame, messages: messages),
            const SizedBox(height: 16),
            PhotoComparison(
              image1: widget.imageFile1,
              image2: widget.imageFile2,
              mode: widget.mode,
            ),
            const SizedBox(height: 16),
            ActionButtons(
              onRetry: () => Navigator.pop(context),
              onHome: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
