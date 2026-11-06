import 'package:flutter/material.dart';

import '../../pipeline/pages/ongoing_process_page.dart';

/// Legacy processing queue page forwarder.
/// Points directly to the live [OngoingProcessPage].
class ProcessingPage extends StatelessWidget {
  const ProcessingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OngoingProcessPage();
  }
}
