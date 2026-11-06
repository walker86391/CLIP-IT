import 'package:flutter_test/flutter_test.dart';
import 'package:clipit/features/pipeline/services/resumable_transcription_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ResumableTranscriptionScanner finds interrupted transcription for project 1', () async {
    final job = await ResumableTranscriptionScanner.findInterruptedTranscriptionJob();
    expect(job, isNotNull);
    expect(job!.projectName, 'project 1');
    expect(job.wordsTranscribed, greaterThan(1000));
    expect(job.lastTranscribedSec, greaterThan(900.0));
    expect(job.totalAudioDurationSec, greaterThan(2000.0));
    expect(job.progressPercent, greaterThan(40.0));
    expect(job.chunkFiles.length, 2);
    expect(job.formattedLastPosition, '00:16:30');
    expect(job.formattedTotalDuration, '00:36:18');
  });
}
