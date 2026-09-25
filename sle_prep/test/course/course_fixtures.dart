import 'package:sle_prep/data/db/database.dart';
import 'package:sle_prep/data/db/course_daos.dart';
import 'package:sle_prep/domain/course/course_catalog.dart';

List<int> workshopAnswers(String id) {
  final workshop = workshopForLesson(id);
  return [workshop.readingQuestion.correct, workshop.listeningQuestion.correct];
}

Future<void> finishWorkshop(AppDatabase db, String id) async {
  await db.saveCourseNotes(
    id,
    '',
    writing: 'Mon texte personnel explique la situation et la prochaine étape.',
  );
  await db.saveCourseWorkshop(
    id,
    answers: workshopAnswers(id),
    writingRevised: true,
  );
}
