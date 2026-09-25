import 'a_to_b_course.dart';
import 'b_to_c_course.dart';
import 'course_workshops.dart';
export 'b_to_c_course.dart' show CourseLesson, CourseModule, CourseQuestion;
export 'course_workshops.dart' show CourseWorkshop;

class CourseTrack {
  const CourseTrack(
    this.id,
    this.label,
    this.description,
    this.modules,
    this.lessons,
  );
  final String id, label, description;
  final List<CourseModule> modules;
  final List<CourseLesson> lessons;
}

const aToBCourse = CourseTrack(
  'a-to-b-v1',
  'A → B',
  'Des bases familières aux échanges factuels : comprendre, lire, écrire et parler de situations concrètes au travail.',
  aToBModules,
  aToBLessons,
);
const bToCCourse = CourseTrack(
  courseId,
  'B → C',
  'Développer les quatre compétences : textes et échanges complexes, inférences, explications structurées et points de vue nuancés.',
  courseModules,
  bToCLessons,
);
const courseTracks = [aToBCourse, bToCCourse];

CourseTrack courseTrackForLesson(String id) => courseTracks.firstWhere(
  (track) => track.lessons.any((lesson) => lesson.id == id),
);
CourseLesson findCourseLesson(String id) =>
    courseTrackForLesson(id).lessons.firstWhere((lesson) => lesson.id == id);
CourseWorkshop workshopForLesson(String id) {
  courseTrackForLesson(id);
  return courseWorkshops[id]!;
}
