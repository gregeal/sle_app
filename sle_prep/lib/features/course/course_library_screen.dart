import 'package:flutter/material.dart';
import '../../domain/course/course_catalog.dart';
import 'course_screen.dart';

class CourseLibraryScreen extends StatelessWidget {
  const CourseLibraryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mes parcours de français')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Un chemin de A vers C',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Text(
          'Deux parcours indépendants, chacun avec 8 modules et 16 classes. Chaque classe associe lecture, écoute, rédaction et conversation. Votre progression reste locale à cet appareil ou navigateur.',
        ),
        const SizedBox(height: 16),
        for (final track in courseTracks)
          Card(
            child: ListTile(
              key: Key('track-${track.id}'),
              title: Text('Parcours ${track.label}'),
              subtitle: Text(track.description),
              leading: const Icon(Icons.route),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CourseScreen(track: track)),
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Text('Par où commencer ?'),
        const Text(
          'A → B : si les phrases de base, questions, récits factuels ou consignes vous demandent encore beaucoup d’effort. B → C : si vous pouvez déjà expliquer des faits et échanger sur des situations concrètes, mais souhaitez mieux traiter la complexité et les nuances.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Vous pouvez utiliser les deux parcours et revenir aux bases. Les niveaux désignent l’ÉLS canadienne, pas le CECR. Terminer les activités ne certifie aucun niveau et ne garantit pas de résultat à l’examen.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Mise à jour : vos anciennes activités B → C restent enregistrées. Les nouveaux ateliers de lecture, écoute et rédaction ont leur propre progression; ils ne réinitialisent pas vos notes ni vos conversations.',
        ),
      ],
    ),
  );
}
