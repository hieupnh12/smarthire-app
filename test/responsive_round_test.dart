import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smarthire_app/features/applications/views/widgets/round_evaluation_panel.dart';
import 'package:smarthire_app/features/applications/models/application_model.dart';

void main() {
  testWidgets('RoundSummaryCard renders on 320px width with large font scale without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 600),
            textScaler: TextScaler.linear(1.4),
          ),
          child: Scaffold(
            body: Column(
              children: [
                RoundSummaryCard(
                  roundKey: EvaluationRoundKey.assessment,
                  round: const RoundItemModel(
                    status: 'NOT_STARTED',
                    score: null,
                    threshold: null,
                    passed: null,
                  ),
                  selected: false,
                  onTap: () {},
                ),
                RoundSummaryCard(
                  roundKey: EvaluationRoundKey.aiInterview,
                  round: const RoundItemModel(
                    status: 'PENDING',
                    score: 87.5,
                    threshold: 75.0,
                    passed: true,
                  ),
                  selected: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Bài đánh giá'), findsOneWidget);
    expect(find.text('Chưa có điểm'), findsOneWidget);
    expect(find.text('Phỏng vấn AI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}