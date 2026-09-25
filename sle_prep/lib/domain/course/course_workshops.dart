import 'b_to_c_course.dart';

class CourseWorkshop {
  const CourseWorkshop(
    this.reading,
    this.readingQuestion,
    this.listening,
    this.listeningQuestion,
    this.writingTask,
    this.writingModel,
  );
  final String reading, listening, writingTask, writingModel;
  final CourseQuestion readingQuestion, listeningQuestion;
  List<bool> answerResults(List<int> answers) {
    final questions = [readingQuestion, listeningQuestion];
    if (answers.length != 2) throw ArgumentError('Incomplete comprehension');
    for (var i = 0; i < 2; i++) {
      if (answers[i] < 0 || answers[i] >= questions[i].options.length) {
        throw ArgumentError('Invalid comprehension answer');
      }
    }
    return [for (var i = 0; i < 2; i++) answers[i] == questions[i].correct];
  }

  bool answersCorrect(List<int> answers) =>
      answerResults(answers).every((v) => v);
}

// All passages are original. Listening uses device/browser synthetic speech.
const courseWorkshops = <String, CourseWorkshop>{
  'ab-01-identity': CourseWorkshop(
    'Bonjour, je m’appelle Amélie. Je suis agente au service des inscriptions. Mon bureau est à Montréal. Je réponds aux questions des participants. Mon collègue Karim prépare les salles.',
    CourseQuestion(
      'Qui répond aux questions des participants ?',
      ['Amélie', 'Karim', 'Le directeur'],
      0,
      'Le message attribue cette tâche à Amélie; Karim prépare les salles.',
    ),
    'Bonjour, ici Paul. Je suis technicien à Ottawa. Je travaille avec Nina. Elle est responsable des horaires. Pour une question sur votre horaire, demandez Nina.',
    CourseQuestion(
      'À qui faut-il demander un renseignement sur les horaires ?',
      ['Paul', 'Nina', 'Amélie'],
      1,
      'Nina est responsable des horaires.',
    ),
    'Écrivez 4 à 6 phrases pour vous présenter à une nouvelle équipe : nom fictif, fonction, lieu et une tâche. Relisez être et les articles.',
    'Bonjour, je m’appelle Alex. Je suis adjoint administratif. Je travaille à Ottawa. Je prépare les réunions du service. Je suis disponible pour répondre à vos questions.',
  ),
  'ab-02-routine': CourseWorkshop(
    'Le matin, notre équipe classe les nouvelles demandes. À dix heures, nous vérifions les dossiers urgents. Le vendredi, nous préparons le bilan. Nous ne recevons pas le public au bureau; nous répondons par téléphone.',
    CourseQuestion(
      'Comment l’équipe répond-elle au public ?',
      ['Au bureau', 'Par téléphone', 'Seulement le vendredi'],
      1,
      'Le texte précise que les réponses sont données par téléphone.',
    ),
    'Chaque matin, je consulte mes messages. Je prépare les documents après le dîner. Je ne travaille pas le mercredi. Mon collègue répond alors aux appels.',
    CourseQuestion(
      'Quel jour la personne ne travaille-t-elle pas ?',
      ['Lundi', 'Vendredi', 'Mercredi'],
      2,
      'Elle indique explicitement ne pas travailler le mercredi.',
    ),
    'Décrivez votre routine en 5 ou 6 phrases. Ajoutez deux fréquences et une négation complète.',
    'Chaque matin, je lis mes messages. Je vérifie ensuite les demandes urgentes. Le mardi, je prépare la réunion. Je ne travaille pas le samedi. Mon équipe répond aux appels tous les jours de la semaine.',
  ),
  'ab-03-questions': CourseWorkshop(
    'Bonjour, merci d’envoyer le formulaire signé à Luc avant jeudi. Le modèle se trouve dans le dossier commun. Si vous ne pouvez pas respecter le délai, prévenez Luc mercredi matin.',
    CourseQuestion(
      'Que doit-on faire si le délai ne peut pas être respecté ?',
      [
        'Prévenir Luc mercredi matin',
        'Envoyer un formulaire non signé',
        'Attendre vendredi',
      ],
      0,
      'La dernière phrase donne la démarche à suivre en cas de retard.',
    ),
    'Pour la rencontre, apportez votre liste de questions. Nous serons dans la salle 105. La rencontre commence à onze heures. Vous pouvez demander le programme à Sara.',
    CourseQuestion(
      'Quel renseignement Sara peut-elle fournir ?',
      ['La liste des congés', 'Le programme', 'Une facture'],
      1,
      'La personne indique de demander le programme à Sara.',
    ),
    'Écrivez un message contenant trois questions ciblées pour organiser une rencontre : lieu, horaire et document à apporter.',
    'Bonjour, dans quelle salle se tient la rencontre ? À quelle heure commence-t-elle ? Quel document dois-je apporter ? Merci pour ces renseignements.',
  ),
  'ab-04-time': CourseWorkshop(
    'Atelier du 12 juin : accueil à 8 h 45, début à 9 h, fin à 11 h 30. Merci de confirmer votre présence avant le 8 juin. Douze places sont disponibles. La salle ouvre seulement à 8 h 30.',
    CourseQuestion(
      'Quelle est la date limite de confirmation ?',
      ['Le 12 juin', 'Le 8 juin', 'Le 30 juin'],
      1,
      'Le 8 juin est la limite de confirmation; le 12 juin est la date de l’atelier.',
    ),
    'La livraison arrivera mardi à quatorze heures trente. Il y aura quinze boîtes, pas cinquante. Merci de libérer la salle avant quatorze heures.',
    CourseQuestion(
      'Combien de boîtes sont annoncées ?',
      ['50', '14', '15'],
      2,
      'Le message précise quinze et exclut cinquante.',
    ),
    'Rédigez une invitation courte avec la date, l’heure de début, le lieu et un délai de réponse. Vérifiez tous les chiffres.',
    'Bonjour, la rencontre aura lieu le 18 juin à quatorze heures dans la salle 210. Merci de confirmer votre présence avant le 15 juin. Nous attendons dix participants.',
  ),
  'ab-05-places': CourseWorkshop(
    'Le service informatique est au troisième étage. En sortant de l’ascenseur, tournez à droite. Le bureau est en face de la cuisine. Les visiteurs doivent d’abord se présenter à l’accueil, au rez-de-chaussée.',
    CourseQuestion(
      'Que doit faire un visiteur en premier ?',
      [
        'Aller directement à la cuisine',
        'Monter au troisième étage',
        'Se présenter à l’accueil',
      ],
      2,
      'La dernière phrase impose un passage à l’accueil avant la visite.',
    ),
    'La salle de formation est au deuxième étage. Prenez l’escalier à côté de l’accueil. En haut, la salle est à gauche, juste avant la bibliothèque.',
    CourseQuestion(
      'Où se trouve la salle en haut de l’escalier ?',
      ['À gauche', 'À droite', 'Dans la bibliothèque'],
      0,
      'La salle est à gauche, avant la bibliothèque.',
    ),
    'Donnez par écrit un trajet de trois étapes entre l’entrée et une salle. Employez au moins deux expressions de lieu.',
    'Depuis l’entrée, allez à l’accueil. Prenez ensuite l’ascenseur jusqu’au deuxième étage. La salle est à droite de l’ascenseur, en face du bureau des inscriptions.',
  ),
  'ab-06-description': CourseWorkshop(
    'La petite salle contient six chaises et une table ronde. Elle dispose d’un écran, mais pas d’un ordinateur. La grande salle contient douze chaises. Son écran est en réparation cette semaine.',
    CourseQuestion(
      'Quel équipement manque dans la petite salle ?',
      ['Un écran', 'Un ordinateur', 'Une table'],
      1,
      'La petite salle a un écran, mais pas d’ordinateur.',
    ),
    'Pour demain, nous avons une salle disponible avec huit chaises. Il manque deux chaises pour notre groupe. L’écran fonctionne, mais apportez votre ordinateur.',
    CourseQuestion(
      'Combien de chaises faut-il ajouter ?',
      ['Deux', 'Huit', 'Dix'],
      0,
      'Huit sont déjà disponibles et deux manquent.',
    ),
    'Écrivez une demande de matériel en 5 phrases : ce qui est disponible, ce qui manque et les caractéristiques utiles. Relisez les accords.',
    'Nous avons réservé une grande salle pour dix personnes. Huit chaises sont disponibles. Il manque deux chaises. Nous avons aussi besoin d’un ordinateur portable. L’écran de la salle fonctionne bien.',
  ),
  'ab-07-requests': CourseWorkshop(
    'Bonjour, pouvez-vous vérifier le tableau avant demain midi ? J’ai ajouté les nouvelles inscriptions. Ne modifiez pas la première colonne; elle contient les numéros officiels. Merci de me signaler les doublons.',
    CourseQuestion(
      'Quelle modification faut-il éviter ?',
      [
        'Vérifier les inscriptions',
        'Signaler les doublons',
        'Changer la première colonne',
      ],
      2,
      'Le message demande explicitement de ne pas modifier la première colonne.',
    ),
    'Je ne peux pas vous envoyer le document ce soir. Je peux vous transmettre une version provisoire demain matin, puis la version signée vendredi. Est-ce que cela vous convient ?',
    CourseQuestion(
      'Qu’est-ce qui sera disponible demain matin ?',
      ['La version signée', 'Une version provisoire', 'Aucun document'],
      1,
      'La version provisoire est proposée pour demain; la version signée pour vendredi.',
    ),
    'Demandez une vérification avec un délai, puis proposez une solution si la personne n’est pas disponible. Restez concret et poli.',
    'Bonjour, pouvez-vous vérifier cette liste avant jeudi ? Je dois confirmer les inscriptions vendredi. Si vous n’êtes pas disponible, pouvez-vous me proposer une autre personne ? Merci de votre aide.',
  ),
  'ab-08-instructions': CourseWorkshop(
    'Pour réserver une salle, consultez d’abord le calendrier. Remplissez ensuite le formulaire avec la date et le nombre de participants. Attendez le courriel de confirmation avant d’envoyer l’invitation. Sans confirmation, la salle n’est pas réservée.',
    CourseQuestion(
      'Quand peut-on envoyer l’invitation ?',
      [
        'Après la confirmation',
        'Avant de consulter le calendrier',
        'Dès que le formulaire est ouvert',
      ],
      0,
      'Il faut attendre le courriel confirmant la réservation.',
    ),
    'Ouvrez le dossier partagé. Choisissez le fichier nommé Inscription. Ajoutez votre nom à la dernière ligne, puis enregistrez. Ne supprimez pas les noms déjà présents.',
    CourseQuestion(
      'Quelle action est interdite ?',
      [
        'Enregistrer le fichier',
        'Ajouter son nom',
        'Supprimer les noms présents',
      ],
      2,
      'Le message demande de conserver les noms déjà présents.',
    ),
    'Rédigez une procédure de quatre étapes pour une tâche familière. Ajoutez une précaution et un signe de confirmation.',
    'Ouvrez le formulaire. Indiquez la date et le nom de la salle. Vérifiez les renseignements. Envoyez la demande et attendez la confirmation. Ne transmettez pas l’invitation avant cette confirmation.',
  ),
  'ab-09-past': CourseWorkshop(
    'Hier, l’équipe a reçu vingt demandes. Nous avons traité les dossiers complets avant midi. Trois dossiers étaient incomplets; nous avons demandé les documents manquants. Le service a confirmé la réception de notre bilan à seize heures.',
    CourseQuestion(
      'Pourquoi trois dossiers n’ont-ils pas été traités comme les autres ?',
      [
        'Ils sont arrivés à seize heures',
        'Ils étaient incomplets',
        'Le bilan était perdu',
      ],
      1,
      'Il manquait des documents dans ces trois dossiers.',
    ),
    'Ce matin, j’ai appelé le fournisseur. Il a confirmé l’envoi du matériel. J’ai ensuite prévenu l’équipe, mais je n’ai pas encore reçu le numéro de suivi.',
    CourseQuestion(
      'Quel renseignement manque encore ?',
      ['La confirmation d’envoi', 'Le nom de l’équipe', 'Le numéro de suivi'],
      2,
      'L’envoi a été confirmé, mais le numéro de suivi n’a pas encore été reçu.',
    ),
    'Écrivez un bilan de journée de 60 à 80 mots environ. Présentez trois actions terminées et un résultat; vérifiez les auxiliaires.',
    'Hier, j’ai vérifié les nouvelles inscriptions. J’ai ensuite appelé deux participants pour compléter leurs dossiers. Nous avons préparé la liste finale et envoyé les invitations. Trois personnes ont confirmé leur présence. Je n’ai pas encore reçu la dernière réponse. J’ai prévenu ma collègue pour qu’elle sache quels dossiers restent ouverts.',
  ),
  'ab-10-background': CourseWorkshop(
    'L’équipe préparait l’atelier dans la grande salle. Il faisait très chaud et plusieurs fenêtres étaient fermées. À neuf heures, la ventilation est tombée en panne. Nous avons déplacé l’atelier dans une autre salle; les participants sont arrivés à l’heure.',
    CourseQuestion(
      'Quel événement a provoqué le changement de salle ?',
      [
        'L’arrivée tardive des participants',
        'La préparation de l’atelier',
        'La panne de ventilation',
      ],
      2,
      'La panne à neuf heures explique le déplacement.',
    ),
    'Je travaillais à l’accueil quand le groupe est arrivé. Le responsable était absent. J’ai donc vérifié la réservation et accompagné les visiteurs à la salle.',
    CourseQuestion(
      'Que faisait la personne à l’arrivée du groupe ?',
      [
        'Elle travaillait à l’accueil',
        'Elle quittait le bâtiment',
        'Elle réparait la salle',
      ],
      0,
      'Le travail à l’accueil constitue le contexte du récit.',
    ),
    'Racontez un changement de programme en 60 à 90 mots environ : contexte, événement et réaction. Utilisez imparfait et passé composé.',
    'Nous préparions une formation lorsque la salle est devenue indisponible. Le bâtiment accueillait un autre événement et il y avait beaucoup de visiteurs. J’ai demandé une autre salle à l’accueil. Ma collègue a envoyé le nouveau numéro aux participants. Nous avons commencé avec dix minutes de retard, mais tout le groupe a trouvé la salle.',
  ),
  'ab-11-future': CourseWorkshop(
    'La semaine prochaine, l’équipe testera le nouveau formulaire. Léa préparera les consignes lundi. Omar réunira les commentaires mercredi. La décision finale sera prise vendredi. Le lancement n’est pas encore confirmé; il dépendra des résultats du test.',
    CourseQuestion(
      'Qu’est-ce qui n’est pas encore confirmé ?',
      [
        'La préparation des consignes',
        'Le lancement',
        'Le recueil des commentaires',
      ],
      1,
      'Le lancement dépend encore des résultats.',
    ),
    'Demain, je vais vérifier les inscriptions. Vous préparerez les documents jeudi. Nous confirmerons le nombre de repas vendredi, quand nous aurons la liste complète.',
    CourseQuestion(
      'Quand le nombre de repas sera-t-il confirmé ?',
      ['Demain', 'Jeudi', 'Vendredi'],
      2,
      'La confirmation du nombre de repas est prévue vendredi.',
    ),
    'Présentez par écrit un plan concret pour la semaine prochaine avec trois actions, leurs responsables et une étape non confirmée.',
    'Lundi, je vais préparer la liste des participants. Mardi, Nadia vérifiera la disponibilité de la salle. Nous enverrons les invitations mercredi. Le nombre de repas reste à confirmer. Je vous transmettrai ce renseignement après les réponses du groupe.',
  ),
  'ab-12-reasons': CourseWorkshop(
    'La salle A coûte moins cher, mais elle accueille seulement six personnes. La salle B peut accueillir douze personnes et possède un écran. Notre groupe compte dix personnes. Nous avons donc choisi B, même si son prix est plus élevé.',
    CourseQuestion(
      'Quelle raison principale explique le choix de B ?',
      [
        'Sa capacité convient au groupe',
        'Elle coûte moins cher',
        'Aucune salle n’a d’écran',
      ],
      0,
      'Le groupe de dix personnes ne tient pas dans la salle A de six places.',
    ),
    'Le train arrive plus tôt que le bus. Le bus coûte moins cher, mais il arrive après le début de la rencontre. Je prendrai donc le train pour être à l’heure.',
    CourseQuestion(
      'Pourquoi la personne choisit-elle le train ?',
      [
        'Pour payer moins cher',
        'Pour arriver à l’heure',
        'Parce que le bus est annulé',
      ],
      1,
      'L’horaire, et non le prix, motive le choix.',
    ),
    'Comparez deux options concrètes dans un court message. Utilisez une comparaison, parce que et une conséquence avec donc.',
    'Je propose l’horaire du matin parce que davantage de collègues sont disponibles. La salle est aussi plus calme le matin que l’après-midi. Nous commencerons donc à neuf heures. Cet horaire demande toutefois de préparer le matériel la veille.',
  ),
  'ab-13-email': CourseWorkshop(
    'Objet : liste des participants. Bonjour, merci d’ajouter les nouvelles inscriptions au tableau avant mercredi à 15 h. Les annulations doivent figurer dans une feuille séparée. Ne contactez pas encore les participants : l’horaire sera confirmé jeudi. Cordialement, Nora.',
    CourseQuestion(
      'Que faut-il attendre avant de contacter les participants ?',
      [
        'La confirmation de l’horaire',
        'Une nouvelle salle',
        'Le mois prochain',
      ],
      0,
      'Le message demande de ne pas contacter les participants avant la confirmation de jeudi.',
    ),
    'Bonjour, votre demande est reçue. Il manque la signature sur la deuxième page. Renvoyez uniquement cette page avant vendredi. Il n’est pas nécessaire de compléter à nouveau tout le formulaire.',
    CourseQuestion(
      'Que faut-il renvoyer ?',
      ['Tout le formulaire', 'La première page', 'La deuxième page signée'],
      2,
      'Seule la deuxième page avec la signature est demandée.',
    ),
    'Répondez au courriel de Nora en 60 à 90 mots : confirmez l’action et le délai, puis posez une question utile. Ne contactez pas les participants dans votre scénario.',
    'Bonjour Nora, je vais mettre à jour le tableau avant mercredi à quinze heures. Je placerai les annulations dans une feuille séparée. J’attendrai la confirmation de l’horaire jeudi avant de contacter les participants. Pouvez-vous me confirmer où se trouve la liste des nouvelles inscriptions ? Merci, Sam.',
  ),
  'ab-14-clarify': CourseWorkshop(
    'Le message indique que les boîtes doivent être livrées au bureau 312 avant midi. Le nom du destinataire est difficile à lire. La réception ferme de midi à treize heures. Avant d’expédier les boîtes, il faut confirmer le nom par téléphone.',
    CourseQuestion(
      'Quelle information doit être vérifiée ?',
      ['Le numéro du bureau', 'Le nom du destinataire', 'L’heure de fermeture'],
      1,
      'Le nom est illisible; le lieu et l’horaire sont indiqués.',
    ),
    'La rencontre ne sera pas mardi, mais mercredi. L’heure reste la même : dix heures. Seule la date change. Merci de corriger votre calendrier; le lieu ne change pas.',
    CourseQuestion(
      'Qu’est-ce qui change ?',
      ['La date seulement', 'L’heure seulement', 'La date et le lieu'],
      0,
      'Le message insiste sur le changement de date et maintient l’heure et le lieu.',
    ),
    'Écrivez une confirmation du message écouté. Distinguez clairement ce qui change de ce qui reste identique.',
    'Bonjour, je confirme que la rencontre aura lieu mercredi, et non mardi. L’heure reste dix heures et le lieu ne change pas. J’ai corrigé mon calendrier. Merci de m’avoir prévenu.',
  ),
  'ab-15-incident': CourseWorkshop(
    'Ce matin, le groupe est arrivé dans la salle indiquée sur l’invitation. La salle était déjà occupée. L’accueil a trouvé une autre salle au même étage. La formation a commencé dix minutes plus tard. La cause de la double réservation n’a pas encore été vérifiée.',
    CourseQuestion(
      'Quelle information reste inconnue ?',
      [
        'La durée du retard',
        'L’étage de la nouvelle salle',
        'La cause de la double réservation',
      ],
      2,
      'Le texte indique que la cause n’a pas encore été vérifiée.',
    ),
    'Le fournisseur a livré quatre boîtes au lieu de cinq. J’ai vérifié le bon de livraison et appelé le service. La dernière boîte arrivera demain matin. Je vous préviendrai dès sa réception.',
    CourseQuestion(
      'Quelle est la prochaine étape annoncée ?',
      [
        'Recevoir la dernière boîte demain',
        'Renvoyer toutes les boîtes',
        'Annuler la commande',
      ],
      0,
      'La dernière boîte est prévue demain matin.',
    ),
    'Rédigez un compte rendu factuel de 80 à 110 mots environ sur un incident fictif. Indiquez les faits, la réaction et la prochaine étape sans inventer une cause.',
    'Ce matin, quatre boîtes ont été livrées, alors que nous en attendions cinq. J’ai comparé le contenu avec le bon de livraison. J’ai ensuite appelé le fournisseur pour signaler la boîte manquante. Il a confirmé une deuxième livraison demain matin. La cause de l’oubli reste à vérifier. Je contrôlerai le contenu à la réception et je vous transmettrai une confirmation. Pour le moment, nous pouvons préparer la salle avec le matériel déjà reçu.',
  ),
  'ab-16-transfer': CourseWorkshop(
    'Huit collègues doivent suivre une formation lundi à neuf heures. La salle habituelle est fermée pour réparation. Une salle de dix places est disponible au même étage, mais elle n’a pas d’ordinateur. Le service peut prêter un appareil si la demande est envoyée vendredi avant midi.',
    CourseQuestion(
      'Quelle action doit être effectuée vendredi avant midi ?',
      [
        'Fermer la salle habituelle',
        'Demander le prêt de l’ordinateur',
        'Commencer la formation',
      ],
      1,
      'La demande de prêt doit être envoyée avant ce délai.',
    ),
    'Nous avons réservé la nouvelle salle. Il reste à prévenir les huit participants et à confirmer le prêt de l’ordinateur. Je vais envoyer le message au groupe. Pouvez-vous vous occuper du matériel avant vendredi midi ?',
    CourseQuestion(
      'Quelle tâche est confiée à l’interlocuteur ?',
      [
        'Réserver une autre salle',
        'Envoyer le message au groupe',
        'S’occuper du matériel',
      ],
      2,
      'La personne garde le message au groupe et demande à l’interlocuteur de s’occuper du matériel.',
    ),
    'Rédigez un message de 90 à 120 mots environ au groupe : changement, éléments inchangés, actions déjà faites et prochaines étapes. Relisez dates et temps verbaux.',
    'Bonjour, la formation de lundi aura lieu dans une autre salle au même étage. L’heure ne change pas : nous commencerons à neuf heures. La salle habituelle est fermée pour réparation. Nous avons réservé une salle de dix places pour nos huit participants. Il manque seulement un ordinateur. Nous allons demander un prêt avant vendredi midi. Je vous enverrai le numéro de la salle avec la confirmation du matériel. Merci de me signaler toute question avant la rencontre.',
  ),
  '01-detail': CourseWorkshop(
    'Le service a ajouté une étape de vérification aux demandes complexes. Le délai moyen a légèrement augmenté, mais les dossiers retournés pour information manquante sont moins nombreux. Ces résultats concernent un essai de six semaines dans une seule équipe. Le rapport recommande de poursuivre l’essai avant d’étendre la mesure.',
    CourseQuestion(
      'Quelle conclusion respecte la portée des résultats ?',
      [
        'La mesure améliore tous les services',
        'L’essai est encourageant, mais limité',
        'La hausse du délai prouve un échec complet',
      ],
      1,
      'L’essai porte sur une seule équipe et ne permet pas une généralisation immédiate.',
    ),
    'Nous avons réduit les erreurs en ajoutant une vérification. Je tiens toutefois à préciser que la plupart des dossiers étaient simples pendant cette période. Avant de conclure à un effet durable, il faudra observer une période plus chargée.',
    CourseQuestion(
      'Quelle réserve limite la conclusion ?',
      [
        'Le contexte observé était relativement simple',
        'Aucune vérification n’a été ajoutée',
        'Tous les dossiers étaient incorrects',
      ],
      0,
      'Le contexte simple peut limiter la généralisation à une période plus chargée.',
    ),
    'Rédigez une note de 120 à 160 mots environ : changement, résultats, exemple et limite. Distinguez observation et conclusion; évitez d’allonger sans ajouter d’information.',
    'La nouvelle vérification semble réduire les dossiers incomplets, au prix d’un léger allongement du traitement. Ce compromis pourrait être utile pour les demandes complexes, dont les retours entraînent souvent plusieurs échanges. Il faut cependant interpréter les résultats avec prudence : l’essai est court et ne concerne qu’une équipe. Je propose de le poursuivre durant une période chargée et de comparer séparément les dossiers simples et complexes. Cette démarche permettrait de vérifier si le bénéfice observé se maintient.',
  ),
  '02-narration': CourseWorkshop(
    'L’équipe préparait la consultation depuis un mois lorsque la date a été avancée. Elle avait déjà recueilli les commentaires des régions, mais pas ceux des utilisateurs externes. Un bilan provisoire a donc été remis. Le rapport final, publié après la consultation externe, a modifié deux recommandations.',
    CourseQuestion(
      'Quels commentaires étaient disponibles avant le changement de date ?',
      [
        'Ceux des utilisateurs externes seulement',
        'Tous les commentaires',
        'Ceux des régions',
      ],
      2,
      'Le plus-que-parfait marque ici la collecte régionale antérieure au changement.',
    ),
    'Quand la consigne est arrivée, nous avions déjà envoyé la première version. Nous avons ensuite préparé un complément. Ce n’est qu’après sa lecture que la direction a confirmé sa décision.',
    CourseQuestion(
      'Quel ordre respecte le récit ?',
      [
        'Décision, consigne, première version',
        'Première version, consigne, complément, décision',
        'Consigne, décision, complément',
      ],
      1,
      'Les repères déjà, ensuite et après ordonnent les étapes.',
    ),
    'Racontez un changement de projet en 120 à 160 mots environ. Distinguez contexte, antériorité et événements; terminez par une leçon sans réécrire le passé comme une certitude.',
    'Nous préparions une consultation lorsque l’échéance a été avancée. Nous avions déjà analysé les commentaires régionaux, mais la consultation externe n’était pas terminée. Nous avons donc remis un bilan provisoire en indiquant clairement ses limites. Le rapport final a ensuite modifié certaines recommandations. Cette expérience montre l’intérêt de distinguer une décision provisoire d’une conclusion définitive. Pour un prochain projet, je proposerais de fixer dès le départ les renseignements indispensables avant toute décision.',
  ),
  '03-precision': CourseWorkshop(
    'La direction a transmis au comité une analyse du service. Celui-ci doit en examiner les limites avant de lui présenter ses recommandations. Le document sur lequel s’appuie l’analyse ne couvre pas les demandes téléphoniques. Cette exclusion doit donc être mentionnée dans le compte rendu.',
    CourseQuestion(
      'Dans ce passage, que désigne « celui-ci » ?',
      ['Le comité', 'Le document', 'Le service téléphonique'],
      0,
      'Le comité est l’entité qui examine l’analyse et présente ses recommandations.',
    ),
    'J’ai parlé à Nadia du rapport de Luc. Elle souhaite le présenter demain, mais il doit encore le vérifier. Pour éviter toute confusion, je précise : c’est Luc qui fera la vérification, et Nadia qui présentera le rapport.',
    CourseQuestion(
      'Qui doit vérifier le rapport ?',
      ['Nadia', 'Luc', 'Le locuteur'],
      1,
      'La dernière phrase lève explicitement l’ambiguïté.',
    ),
    'Réécrivez un message de 100 à 150 mots avec deux personnes et deux documents. Réduisez les répétitions sans créer d’ambiguïtés; utilisez une relative avec dont ou auquel.',
    'Nadia présentera le rapport que Luc a préparé. Avant la rencontre, Luc en vérifiera les chiffres. Le tableau auquel le rapport renvoie sera transmis séparément. Nadia ajoutera ensuite une courte introduction pour expliquer la méthode. Si une donnée reste incertaine, Luc la signalera dans une note plutôt que de modifier silencieusement le résultat. Cette répartition précise qui vérifie le contenu et qui en assure la présentation.',
  ),
  '04-coherence': CourseWorkshop(
    'Le formulaire a été raccourci afin de faciliter l’accès au service. Le nombre de demandes complètes a augmenté. Toutefois, les demandes complexes nécessitent désormais davantage d’échanges, car certaines précisions ne sont plus recueillies au départ. La simplification n’a donc pas produit le même effet pour toutes les catégories.',
    CourseQuestion(
      'Quel rapport logique exprime la dernière phrase ?',
      [
        'Un objectif',
        'Une illustration sans lien',
        'Une conclusion tirée de résultats différents',
      ],
      2,
      'Donc introduit une conclusion fondée sur les effets contrastés.',
    ),
    'Nous souhaitions accélérer le traitement. Les délais ont effectivement diminué pour les cas courants. En revanche, les cas particuliers prennent plus de temps. Je propose donc d’adapter le formulaire au type de demande plutôt que de revenir entièrement à l’ancien modèle.',
    CourseQuestion(
      'Quelle proposition découle du contraste observé ?',
      [
        'Adapter le formulaire selon le type de demande',
        'Supprimer tout formulaire',
        'Revenir entièrement à l’ancien modèle',
      ],
      0,
      'Le locuteur propose une adaptation différenciée.',
    ),
    'Rédigez une analyse de 120 à 160 mots distinguant but, résultat, cause et limite. Vérifiez le sens de chaque connecteur plutôt que leur nombre.',
    'Le formulaire a été simplifié pour améliorer l’accès. Les dossiers courants sont maintenant traités plus rapidement, mais les cas particuliers exigent des échanges supplémentaires. Ce résultat s’explique en partie par l’absence de certaines questions initiales. Il ne justifie donc ni un retour complet à l’ancien formulaire ni une généralisation sans modification. Une version adaptée aux dossiers complexes pourrait préserver le gain de temps tout en réduisant les demandes de précisions.',
  ),
  '05-opinion': CourseWorkshop(
    'Une formation commune assurerait un vocabulaire partagé, soutient la responsable. Un collègue objecte qu’elle pourrait répéter des acquis et réduire le temps consacré aux dossiers. Le groupe envisage alors un tronc commun court, suivi d’activités adaptées. Aucun résultat n’établit encore que cette formule serait plus efficace.',
    CourseQuestion(
      'Quel statut a la formule proposée ?',
      [
        'Une efficacité démontrée',
        'Une option qui répond à des objections et reste à évaluer',
        'Une décision imposée sans discussion',
      ],
      1,
      'Elle est envisagée, mais son efficacité n’est pas encore établie.',
    ),
    'Je suis favorable à une formation commune, à condition qu’elle réponde à un besoin réel. Mon expérience m’incite à prévoir des exercices adaptés aux fonctions. Elle ne suffit toutefois pas à conclure que cette formule convient à toutes les équipes.',
    CourseQuestion(
      'Quelle limite la personne reconnaît-elle ?',
      [
        'Elle rejette toute formation',
        'Les fonctions sont identiques',
        'Son expérience ne suffit pas pour généraliser',
      ],
      2,
      'Elle distingue son expérience d’une preuve valable pour toutes les équipes.',
    ),
    'Défendez une position en 150 à 190 mots : deux raisons, un exemple, une objection et les conditions qui vous feraient revoir votre avis.',
    'Je privilégie un tronc commun court, car il peut donner aux équipes des repères partagés sans supposer que leurs besoins sont identiques. Des exercices adaptés permettraient ensuite de relier ces repères aux tâches réelles. Je reconnais néanmoins le risque de répéter des acquis. Un diagnostic initial pourrait limiter cette répétition. Je réviserais ma recommandation si les participants ne pouvaient pas réutiliser la formation dans leur travail ou si les gains observés ne justifiaient pas le temps investi.',
  ),
  '06-options': CourseWorkshop(
    'L’option A est moins coûteuse au départ, mais elle exige une intervention manuelle permanente. L’option B demande une formation et un investissement initial plus élevés. Sur trois ans, son coût pourrait être inférieur, à condition que le volume prévu se maintienne. Le choix dépend donc de l’horizon et de la fiabilité des prévisions.',
    CourseQuestion(
      'Quelle condition soutient l’avantage financier possible de B ?',
      [
        'Le maintien du volume prévu',
        'L’absence de formation',
        'Un usage pendant une seule semaine',
      ],
      0,
      'Le coût inférieur à long terme dépend du volume de traitement.',
    ),
    'Si notre priorité est de démarrer ce mois-ci, A est plus réaliste. Pour un service durable à fort volume, B mérite une analyse plus poussée. Je ne confondrais donc pas la solution la plus rapide avec la meilleure solution à long terme.',
    CourseQuestion(
      'Quelle distinction organise la recommandation ?',
      [
        'Public et privé',
        'Rapidité initiale et pertinence à long terme',
        'Deux options identiques',
      ],
      1,
      'La recommandation varie selon l’horizon et le volume.',
    ),
    'Comparez deux options en 150 à 190 mots avec des critères communs, un compromis explicite et une condition de réévaluation.',
    'A offre un démarrage rapide et un coût initial limité. En revanche, ses interventions manuelles risquent de devenir coûteuses à fort volume. B exige davantage de préparation, mais pourrait être plus adaptée à un service durable. Je choisirais A pour un essai court, sans présenter ce choix comme définitif. Avant un déploiement prolongé, il faudrait mesurer le volume réel et le temps consacré aux interventions. Ces données permettraient de vérifier si l’investissement dans B devient justifié.',
  ),
  '07-concession': CourseWorkshop(
    'Bien que l’outil améliore la visibilité des dossiers, il ne garantit pas l’exactitude des renseignements saisis. Même si toutes les équipes l’utilisent, une vérification reste nécessaire. Le comité recommande donc son adoption sous réserve d’un mécanisme de contrôle, et non comme remplacement du jugement professionnel.',
    CourseQuestion(
      'Quelle interprétation respecte la concession ?',
      [
        'L’outil est inutile',
        'L’outil remplace tout contrôle',
        'L’outil est utile, mais insuffisant à lui seul',
      ],
      2,
      'L’amélioration est reconnue sans en déduire une garantie d’exactitude.',
    ),
    'Je reconnais que le délai est court. Cela ne rend pas le projet impossible, pourvu que nous réduisions sa portée. En revanche, maintenir tous les objectifs dans ce délai me paraît peu réaliste.',
    CourseQuestion(
      'À quelle condition le projet est-il jugé possible ?',
      [
        'Réduire sa portée',
        'Maintenir tous les objectifs',
        'Supprimer le délai sans discussion',
      ],
      0,
      'La faisabilité dépend de la réduction de portée.',
    ),
    'Écrivez une recommandation de 130 à 170 mots avec une concession réelle, une condition et une mesure de réduction du risque. Relisez les modes verbaux.',
    'Bien que l’outil rende les dossiers plus visibles, il ne suffit pas à garantir la fiabilité des données. Je recommande son adoption à condition qu’un contrôle proportionné soit maintenu. Ce contrôle devrait cibler les renseignements qui influencent les décisions plutôt que répéter toutes les vérifications. Même si cette mesure demande du temps, elle peut éviter de diffuser des données inexactes. L’essai devra préciser si les gains de visibilité compensent cet effort supplémentaire.',
  ),
  '08-advice': CourseWorkshop(
    'Les premiers commentaires signalent des difficultés d’utilisation, sans permettre d’en mesurer la fréquence. La note propose un essai accompagné plutôt qu’un remplacement immédiat. Elle recommande que les utilisateurs consignent les problèmes et que l’équipe distingue les défauts de l’outil des besoins de formation.',
    CourseQuestion(
      'Pourquoi ne pas conclure immédiatement au remplacement ?',
      [
        'Tout problème est inventé',
        'La fréquence et la nature des difficultés restent à préciser',
        'La formation est interdite',
      ],
      1,
      'Les observations initiales ne suffisent pas encore à déterminer la meilleure réponse.',
    ),
    'Je proposerais que nous commencions avec une petite équipe. Il ne s’agit pas de minimiser les difficultés, mais de comprendre lesquelles relèvent du fonctionnement et lesquelles relèvent de l’accompagnement.',
    CourseQuestion(
      'Quel est l’objectif de l’essai limité ?',
      [
        'Prouver d’avance que tout fonctionne',
        'Écarter les utilisateurs',
        'Distinguer les sources des difficultés',
      ],
      2,
      'L’essai cherche à comprendre les difficultés avant une décision générale.',
    ),
    'Rédigez une note de 150 à 190 mots séparant constats, incertitudes et recommandations. Incluez une action mesurable et un point de décision.',
    'Les commentaires reçus indiquent des difficultés, mais leur fréquence reste inconnue. Je recommande un essai accompagné de quatre semaines. Les participants consigneraient les problèmes rencontrés et les solutions utilisées. L’équipe pourrait alors distinguer les défauts techniques des besoins de formation. À la fin de l’essai, nous comparerions le temps de traitement et les difficultés non résolues. Cette démarche ne garantit pas que l’outil sera conservé; elle vise à rendre la décision plus solide.',
  ),
  '09-hypothesis': CourseWorkshop(
    'Si le volume doublait, l’équipe pourrait absorber une partie de la hausse grâce aux tâches automatisées. Les dossiers complexes resteraient toutefois dépendants d’une expertise limitée. L’analyse ne prévoit pas une hausse identique des délais pour toutes les demandes; elle invite à distinguer les catégories avant d’estimer les besoins.',
    CourseQuestion(
      'Quelle conséquence serait abusive à déduire ?',
      [
        'Les dossiers complexes peuvent rester un point de pression',
        'L’automatisation peut absorber une partie de la hausse',
        'Tous les délais doubleraient nécessairement',
      ],
      2,
      'Le texte exclut une projection identique et automatique pour toutes les catégories.',
    ),
    'Avec moins de ressources, je protégerais d’abord les demandes urgentes. Cela pourrait allonger l’attente pour les autres dossiers. Je vérifierais donc la répartition réelle des demandes avant de promettre un délai uniforme.',
    CourseQuestion(
      'Pourquoi vérifier la répartition des demandes ?',
      [
        'Pour estimer les conséquences avant de promettre un délai',
        'Pour garantir une hausse de budget',
        'Pour supprimer toutes les priorités',
      ],
      0,
      'La répartition est nécessaire pour évaluer les effets de la réduction.',
    ),
    'Analysez une réduction fictive de ressources en 150 à 190 mots : priorités, deux conséquences, incertitude et information à vérifier. Utilisez des hypothèses cohérentes.',
    'Si les ressources diminuaient, je maintiendrais la priorité aux demandes urgentes. Les dossiers courants pourraient attendre davantage, tandis que les dossiers complexes exigeraient toujours une expertise particulière. Il serait donc risqué de promettre un délai uniforme. Avant de modifier les engagements, nous devrions examiner le volume par catégorie et les tâches réellement automatisables. Cette analyse aiderait à expliquer les compromis aux utilisateurs et à réviser les priorités si la demande évoluait.',
  ),
  '10-hindsight': CourseWorkshop(
    'Si les rôles avaient été clarifiés plus tôt, certaines vérifications en double auraient probablement été évitées. La panne externe n’aurait cependant pas été empêchée. Le bilan recommande de séparer les problèmes de coordination des événements hors du contrôle de l’équipe pour choisir des mesures utiles.',
    CourseQuestion(
      'Quelle distinction le bilan demande-t-il de faire ?',
      [
        'Tous les problèmes étaient évitables',
        'Coordination interne et événement externe',
        'Aucune amélioration n’est possible',
      ],
      1,
      'Les mesures utiles dépendent de ce qui relevait ou non du contrôle de l’équipe.',
    ),
    'Nous aurions pu tester la procédure avant le lancement. Je ne peux pas affirmer que cela aurait révélé tous les problèmes. En revanche, les difficultés de connexion auraient probablement été repérées.',
    CourseQuestion(
      'Que peut-on raisonnablement retenir ?',
      [
        'Un test aurait garanti une absence totale de problèmes',
        'Le test aurait été inutile',
        'Le test aurait pu révéler certaines difficultés',
      ],
      2,
      'La personne limite explicitement la portée de l’hypothèse.',
    ),
    'Écrivez un bilan rétrospectif de 150 à 190 mots sans blâme personnel. Distinguez hypothèse, probabilité et fait, puis proposez une mesure concrète.',
    'Le lancement a révélé plusieurs difficultés de connexion. Un essai préalable aurait probablement permis d’en repérer certaines, sans garantir que tous les problèmes auraient été évités. La panne externe doit être analysée séparément, puisqu’elle ne relevait pas du contrôle de l’équipe. Pour le prochain lancement, je recommande un test limité et un plan de continuité. Ces mesures répondent à des risques différents et devraient être évaluées selon leur utilité réelle plutôt qu’à partir d’une recherche de responsabilité individuelle.',
  ),
  '11-summary': CourseWorkshop(
    'Nadia souhaite lancer le service lundi avec une petite équipe. Marc estime que la formation doit précéder le lancement, mais accepte d’examiner un essai limité. Les deux personnes veulent éviter une interruption. Elles ont convenu de vérifier la disponibilité des formateurs, pas encore d’autoriser le démarrage.',
    CourseQuestion(
      'Quelle décision a réellement été prise ?',
      [
        'Autoriser le lancement complet lundi',
        'Annuler le projet',
        'Vérifier la disponibilité des formateurs',
      ],
      2,
      'L’accord porte sur une vérification préalable, non sur le démarrage.',
    ),
    'Nous sommes d’accord sur l’objectif de continuité. Le désaccord concerne l’ordre des étapes. Nadia propose un essai lundi; Marc veut connaître les possibilités de formation. Nous reviendrons sur la décision après cette vérification.',
    CourseQuestion(
      'Sur quoi porte le désaccord ?',
      [
        'L’ordre des étapes',
        'L’objectif de continuité',
        'L’existence du service',
      ],
      0,
      'L’objectif est partagé; la séquence reste à déterminer.',
    ),
    'Rédigez un compte rendu de 130 à 170 mots : positions attribuées, accord, désaccord et décision en suspens. Séparez ensuite votre recommandation.',
    'Les participants partagent l’objectif d’éviter une interruption du service. Nadia propose un essai limité lundi, alors que Marc souhaite préciser les possibilités de formation avant le démarrage. Ils ont convenu de vérifier la disponibilité des formateurs. Le lancement n’est donc pas encore autorisé. À titre de recommandation, je proposerais de définir les conditions minimales d’un essai avant la prochaine rencontre. Cette proposition est distincte des décisions déjà prises par le groupe.',
  ),
  '12-listening': CourseWorkshop(
    'La directrice ne s’oppose pas à un lancement ce mois-ci, sous réserve d’un soutien suffisant. Si la demande dépasse la capacité, le nombre de participants devra être limité. La date envisagée n’est donc ni une garantie ni un refus : elle dépend de conditions opérationnelles encore à préciser.',
    CourseQuestion(
      'Comment qualifier la position de la directrice ?',
      [
        'Un accord inconditionnel',
        'Une ouverture conditionnelle',
        'Un refus définitif',
      ],
      1,
      'Elle accepte d’envisager le lancement sous conditions.',
    ),
    'Je suis prêt à appuyer l’essai, pourvu que les équipes puissent obtenir de l’aide rapidement. Ce qui m’inquiète n’est pas le principe du changement, mais la capacité à résoudre les difficultés au début. Sans ce soutien, je préférerais reporter.',
    CourseQuestion(
      'Quelle préoccupation motive la réserve ?',
      [
        'Le principe même de tout changement',
        'Le nom du projet',
        'La disponibilité d’un soutien rapide',
      ],
      2,
      'Le soutien au démarrage, et non le changement lui-même, motive la réserve.',
    ),
    'Rédigez une réponse de 130 à 170 mots : reformulez fidèlement la réserve, posez une question de clarification et proposez une mesure sans prétendre que l’accord est acquis.',
    'Si je comprends bien, vous êtes favorable à l’essai à condition qu’un soutien rapide soit disponible. Votre réserve concerne surtout la gestion des difficultés au démarrage. Quel délai de réponse jugeriez-vous acceptable ? Nous pourrions prévoir une personne de soutien pendant les premières journées et limiter le nombre de participants. Cette proposition reste à valider avec les équipes concernées; elle ne signifie pas que les conditions de lancement sont déjà réunies.',
  ),
  '13-abstract': CourseWorkshop(
    'Une procédure identique pour tous peut sembler équitable tout en créant des obstacles différents. Le texte propose de distinguer l’égalité des règles de l’accès effectif au service. Il ne recommande pas de supprimer les exigences communes, mais d’examiner si des modalités adaptées permettraient d’atteindre le même objectif.',
    CourseQuestion(
      'Quelle interprétation respecte l’argument ?',
      [
        'Adapter les modalités peut préserver un objectif commun',
        'Toute exigence commune doit disparaître',
        'Des règles identiques garantissent toujours l’accès',
      ],
      0,
      'Le texte distingue l’objectif commun des modalités permettant de l’atteindre.',
    ),
    'Pour moi, la transparence consiste à expliquer les critères d’une décision. Elle n’oblige pas à divulguer tous les renseignements personnels. La difficulté est de rendre la démarche compréhensible tout en protégeant les personnes.',
    CourseQuestion(
      'Quelle tension est explicitement examinée ?',
      [
        'Coût et délai',
        'Explication des décisions et protection des renseignements',
        'Formation et vacances',
      ],
      1,
      'La personne met en relation transparence et confidentialité.',
    ),
    'Expliquez une notion abstraite en 160 à 200 mots avec définition contextualisée, exemple, tension et limite. Évitez les affirmations absolues.',
    'Dans un service public, l’équité peut désigner la possibilité réelle d’accéder au service, et non seulement l’application d’une procédure identique. Une inscription uniquement en ligne peut être simple pour certains usagers et constituer un obstacle pour d’autres. Une modalité complémentaire pourrait préserver les mêmes critères tout en améliorant l’accès. Cette adaptation doit toutefois être examinée au regard des ressources disponibles et de la cohérence des décisions. Il ne s’agit donc ni de traiter chaque situation sans règle ni de supposer qu’une règle identique produit toujours le même effet.',
  ),
  '14-disagreement': CourseWorkshop(
    'La note reconnaît l’intérêt d’un déploiement rapide, mais conteste le calendrier proposé. Elle indique que deux équipes n’ont pas terminé leur formation et suggère une mise en œuvre progressive. Elle ne remet pas en cause l’objectif du projet. Son désaccord porte sur les conditions du changement, non sur les intentions de son auteur.',
    CourseQuestion(
      'Quel est l’objet précis du désaccord ?',
      [
        'L’objectif du projet',
        'Les conditions et le calendrier du déploiement',
        'La valeur personnelle du responsable',
      ],
      1,
      'La note soutient l’objectif tout en contestant les modalités.',
    ),
    'Je partage votre objectif. Je crains toutefois que certaines équipes ne soient pas prêtes lundi. Pourrions-nous commencer avec les équipes formées, puis confirmer la suite après une semaine ? Je souhaite vérifier votre accord sur cette étape, pas présumer que tout est décidé.',
    CourseQuestion(
      'Quel statut a le déploiement progressif ?',
      [
        'Une décision déjà acceptée',
        'Un refus de toute action',
        'Une proposition dont l’accord reste à vérifier',
      ],
      2,
      'La personne demande une confirmation et ne présume pas l’accord.',
    ),
    'Rédigez un message délicat de 150 à 190 mots : objectif partagé, observation précise, réserve, option et demande d’accord. Éliminez les jugements sur les personnes.',
    'Je partage l’objectif de simplifier rapidement le service. Ma réserve concerne la préparation des équipes : deux d’entre elles n’ont pas encore terminé la formation. Un lancement simultané pourrait donc augmenter les demandes de soutien. Je propose de commencer avec les équipes formées, puis d’examiner les difficultés après une semaine. Cette démarche permettrait d’avancer sans supposer que toutes les conditions sont réunies. Pourrions-nous confirmer ensemble les critères nécessaires pour élargir le déploiement ?',
  ),
  '15-fluency': CourseWorkshop(
    'Le compte rendu devient difficile à suivre lorsque chaque phrase recommence l’explication depuis le début. La révision propose de regrouper les faits, de supprimer les répétitions et de garder les précisions qui modifient le sens. La concision recherchée ne consiste pas à retirer toutes les nuances.',
    CourseQuestion(
      'Quelle révision respecte l’objectif de concision ?',
      [
        'Supprimer toute réserve',
        'Ajouter des termes techniques partout',
        'Retirer les répétitions tout en gardant les nuances utiles',
      ],
      2,
      'La concision doit préserver les précisions qui changent le sens.',
    ),
    'Nous avons créé un… je cherche le mot… un écran qui regroupe les principaux indicateurs. Autrement dit, l’équipe peut voir rapidement ce qui avance et ce qui bloque. Ce système ne remplace pas l’analyse des dossiers particuliers.',
    CourseQuestion(
      'Comment la personne surmonte-t-elle le mot manquant ?',
      [
        'Elle décrit la fonction et poursuit',
        'Elle abandonne le message',
        'Elle supprime toute limite',
      ],
      0,
      'La paraphrase permet de continuer tout en conservant une réserve importante.',
    ),
    'Écrivez une explication de 140 mots environ, puis une version plus concise dans vos notes. Gardez la même idée principale et une limite; remplacez un terme technique par une paraphrase.',
    'Version concise possible : nous utilisons un écran qui regroupe les principaux indicateurs du service. Il aide l’équipe à repérer les retards et à choisir les dossiers à examiner. Il ne remplace toutefois pas l’analyse des situations particulières. Sa valeur dépend donc aussi de la fiabilité des données et de la manière dont les personnes interprètent les résultats.',
  ),
  '16-transfer': CourseWorkshop(
    'Le projet de service numérique pourrait élargir les heures d’accès et réduire certaines tâches répétitives. Une réduction générale de l’accueil en personne risquerait cependant d’exclure des usagers. Le rapport recommande un essai avec plusieurs canaux, suivi d’une analyse des coûts, de l’accès réel et des demandes non résolues. Aucun canal n’est présenté comme suffisant à lui seul.',
    CourseQuestion(
      'Quelle recommandation correspond au rapport ?',
      [
        'Remplacer immédiatement tout accueil en personne',
        'Tester plusieurs canaux et évaluer leurs effets',
        'Abandonner tout service numérique',
      ],
      1,
      'Le rapport préconise un essai évalué plutôt qu’une solution exclusive.',
    ),
    'Si le budget était réduit, je maintiendrais d’abord les services essentiels. Nous pourrions limiter la portée de l’essai numérique, sans fermer immédiatement l’accueil en personne. Je reconnais que ce choix ralentirait le projet, mais il laisserait le temps d’observer les besoins qui restent sans réponse.',
    CourseQuestion(
      'Quel compromis est reconnu ?',
      [
        'Une réduction de portée sans aucun coût',
        'Une fermeture immédiate de l’accueil',
        'Un projet plus lent pour mieux observer les besoins',
      ],
      2,
      'La personne accepte de ralentir pour préserver l’observation des besoins.',
    ),
    'Bilan écrit : rédigez une note de 180 à 230 mots sur ce projet. Résumez les enjeux, recommandez une option, examinez une objection et une réduction de budget. Relisez cohérence, nuance et exactitude.',
    'Le service numérique peut améliorer l’accès horaire et réduire certaines tâches, mais il ne répond pas nécessairement à tous les besoins. Je recommande un essai limité maintenant plusieurs canaux. Une objection légitime concerne le coût de cette coexistence. Il faudrait donc définir la durée de l’essai et les indicateurs permettant de décider de la suite. Si le budget diminuait, je réduirais la portée du volet numérique plutôt que de fermer immédiatement l’accueil en personne. Cette option ralentirait le déploiement, mais préserverait un moyen de repérer les besoins non satisfaits. La recommandation devrait être réexaminée à partir de l’accès réel, des coûts et des demandes non résolues.',
  ),
};
