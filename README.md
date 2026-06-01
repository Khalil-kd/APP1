# Flutter 2048

Jeu 2048 complet en Flutter/Dart.

## Jouer en ligne

Apres le deploiement GitHub Pages, le jeu sera disponible ici :

https://khalil-kd.github.io/APP1/

## Fonctionnalites

- Grille 4x4.
- Deplacements haut, bas, gauche, droite.
- Fusion des tuiles identiques avec ajout au score.
- Nouvelle tuile aleatoire `2` ou `4` apres chaque mouvement valide.
- Detection de victoire a `2048`.
- Detection de fin de partie lorsqu'aucun mouvement n'est possible.
- Redemarrage de partie.
- Score actuel et meilleur score sauvegarde localement.
- Gestes de balayage mobile.
- Controles clavier web/desktop.
- Animations de deplacement, apparition et fusion.
- Interface responsive inspiree du 2048 original.

## Execution

Installez Flutter, puis lancez :

```bash
flutter pub get
flutter run
```

Si vous partez de ce dossier sans plateformes Flutter generees, executez d'abord :

```bash
flutter create --platforms=android,ios,web,windows,macos,linux --no-overwrite .
flutter pub get
flutter run
```

Pour le web :

```bash
flutter run -d chrome
```

Build web pour GitHub Pages :

```bash
flutter build web --release --base-href /APP1/
```
