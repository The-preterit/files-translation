
---

# Projet : Project Language Translator

## Objectif

Développer un outil Python capable de traduire automatiquement les portions d'un projet écrites dans une langue donnée (par exemple le chinois) vers une autre (par exemple l'anglais), **sans modifier le reste du contenu des fichiers**.

Le programme doit :

* parcourir récursivement un dossier ;
* ignorer certains dossiers, fichiers et extensions ;
* détecter uniquement les segments dans la langue cible ;
* traduire uniquement ces segments ;
* réécrire le fichier en conservant strictement le code et le formatage.

Le projet doit être facilement extensible à d'autres langues et à d'autres fournisseurs de traduction.

---

# Contraintes importantes

## Ne jamais envoyer un fichier entier à l'API

Interdit :

```text
Tout le fichier Java
```

Autorisé :

```text
初始化摄像头

检测成功

无法连接
```

Le coût de traduction doit être minimisé.

---

## Ne jamais modifier le code

Exemple :

Avant

```java
String text = "检测成功";
```

Après

```java
String text = "Detection successful";
```

Mais

```java
String
=
```

ne doivent jamais être modifiés.

---

## Préserver parfaitement

* indentation
* espaces
* tabulations
* retour à la ligne
* encodage UTF-8
* commentaires
* structure du fichier

Le programme ne doit modifier que les portions traduites.

---

# Architecture

```
translator/
│
├── main.py
├── config.py
│
├── scanner/
│
├── detectors/
│
├── translators/
│
├── cache/
│
├── writer/
│
├── models/
│
├── utils/
│
└── tests/
```

---

# Étape 1 : Configuration

Créer une classe de configuration.

Elle contient :

```
project_directory

ignored_directories

ignored_extensions

ignored_files

source_language

target_language

translator

batch_size

backup_enabled

cache_enabled

dry_run

max_workers
```

---

# Étape 2 : Scanner

Créer un scanner qui :

parcourt le dossier avec pathlib.

Ignore :

```
.git

.idea

.gradle

build

node_modules

dist

bin

obj
```

Ignore également :

```
*.png

*.jpg

*.gif

*.jar

*.zip

*.mp4

*.mp3

*.class

*.so

*.dll
```

Retourne la liste des fichiers à analyser.

---

# Étape 3 : Détecteurs de langue

Créer une interface :

```
LanguageDetector
```

avec

```
find_segments(text)
```

Chaque détecteur retourne :

```
[
    Segment(...),
    Segment(...),
    ...
]
```

où Segment contient :

```
texte original

position début

position fin
```

---

## Détecteur chinois

Utiliser les blocs Unicode.

Détecter :

```
汉字

测试

初始化摄像头
```

Ne pas détecter :

```
english

12345

camelCase

snake_case
```

---

# Étape 4 : Modèle Segment

Créer une classe

```
Segment
```

contenant

```
text

start

end
```

Les positions servent à remplacer précisément le texte.

---

# Étape 5 : Lecture des fichiers

Créer un FileReader.

Il :

* ouvre en UTF-8
* ignore les erreurs mineures d'encodage
* retourne le contenu

---

# Étape 6 : Extraction

Pour chaque fichier :

```
contenu

↓

détection

↓

liste des segments chinois
```

Aucune traduction n'est faite ici.

---

# Étape 7 : Cache

Créer un cache mémoire.

Exemple :

```
{
    "检测成功":
        "Detection successful",

    "初始化":
        "Initialization"
}
```

Si une chaîne existe déjà :

ne pas appeler l'API.

---

# Étape 8 : Batch

Les nouveaux segments sont regroupés.

Exemple

```
100 segments

↓

1 appel DeepL
```

Jamais :

```
100 appels API
```

Le batch_size est configurable.

---

# Étape 9 : API de traduction

Créer une interface :

```
Translator
```

avec

```
translate(
    texts,
    source,
    target
)
```

Elle retourne

```
[
...
]
```

Même ordre.

---

## Implémentation DeepL

Créer

```
DeepLTranslator
```

Utiliser le SDK officiel.

Ne jamais traduire une chaîne vide.

Gérer :

* erreurs réseau
* dépassement quota
* timeout

---

## Implémentation Google

Créer

```
GoogleTranslator
```

Même interface.

Aucun autre code du projet ne doit dépendre du fournisseur.

---

# Étape 10 : Remplacement

Créer un replacer.

Il reçoit :

```
contenu

segments

traductions
```

Les remplacements doivent être faits depuis la fin du fichier vers le début afin que les indices ne soient jamais invalidés.

---

# Étape 11 : Écriture

Créer FileWriter.

Si modification :

écrire le fichier.

Sinon :

ne rien faire.

---

# Étape 12 : Sauvegarde

Option configurable.

Avant modification :

```
Main.java

↓

Main.java.bak
```

ou

```
backup/

...
```

---

# Étape 13 : Journalisation

Afficher :

```
Analyse du fichier :

...

Segments trouvés :

...

Segments traduits :

...
```

Puis résumé :

```
Fichiers analysés

Fichiers modifiés

Segments détectés

Segments traduits

Segments issus du cache

Caractères envoyés

Temps total
```

---

# Étape 14 : Mode Dry Run

Ajouter

```
dry_run=True
```

Dans ce mode :

aucun fichier n'est modifié.

Le programme affiche uniquement ce qui aurait été traduit.

---

# Étape 15 : Multithreading

Les fichiers peuvent être analysés en parallèle.

La traduction reste regroupée en batch.

Utiliser :

```
ThreadPoolExecutor
```

Le cache doit être thread-safe.

---

# Étape 16 : Ligne de commande

Créer une CLI.

Exemple :

```bash
python main.py \
    --project ./project \
    --translator deepl \
    --source ZH \
    --target EN-US \
    --ignore-dir .git build node_modules \
    --ignore-ext .png .jpg .jar \
    --batch-size 100 \
    --backup \
    --dry-run
```

---

# Étape 17 : Tests

Prévoir des tests unitaires pour :

* détection du chinois ;
* extraction correcte des segments ;
* remplacement sans casser les indices ;
* cache ;
* regroupement en batch ;
* parcours des dossiers avec exclusions ;
* absence de modification lorsqu'aucun segment n'est trouvé ;
* conservation exacte du code après traduction.

Ajouter également quelques tests d'intégration sur un petit projet factice (Java/Kotlin/XML/Markdown) afin de valider le flux complet.

---

# Critères de qualité

Le code produit doit :

* être compatible Python 3.11+ ;
* être fortement typé (`typing`) ;
* respecter PEP 8 ;
* utiliser `pathlib` plutôt que `os.path` ;
* utiliser `dataclasses` pour les modèles simples ;
* être documenté avec des docstrings ;
* être structuré de manière à faciliter l'ajout de nouveaux détecteurs de langue et de nouveaux fournisseurs de traduction sans modifier le reste du projet (principe Open/Closed).
