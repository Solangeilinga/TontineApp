# Règles ProGuard/R8 spécifiques au projet.
#
# Ce fichier était référencé dans build.gradle.kts
# (proguardFiles(getDefaultProguardFile(...), "proguard-rules.pro")) mais
# n'existait pas dans le dépôt — Gradle peut échouer au build release selon
# la config exacte si le fichier référencé est introuvable. Il démarre vide
# intentionnellement : proguard-android-optimize.txt (fourni par le SDK
# Android) couvre déjà les règles de base, et Flutter + les plugins
# ajoutent automatiquement leurs propres règles de conservation via leurs
# propres fichiers consumer-rules.pro.
#
# Ajoute ici des règles -keep si un crash release "ClassNotFoundException"
# ou "NoSuchMethodError" apparaît après activation de minifyEnabled (souvent
# lié à la réflexion : sérialisation JSON manuelle, plugins natifs, etc.).
