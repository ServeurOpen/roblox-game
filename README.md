# Roblox Game (Tycoon/Simulateur) — projet Rojo

Squelette de jeu Roblox synchronisé avec Studio via [Rojo](https://rojo.space/).
Je (Claude) modifie le code ici et tu n'as qu'à `git pull` pour que ça se
resynchronise automatiquement dans Studio.

## Installation (une seule fois)

1. **Plugin Rojo dans Studio** : ouvre Roblox Studio → Toolbox / Plugins
   Marketplace → cherche "Rojo" → installe le plugin officiel (rojo-rbx).
2. **Rojo CLI sur ton PC** : installe [Aftman](https://github.com/LPGhatguy/aftman)
   (gestionnaire d'outils), puis dans ce dossier lance :
   ```
   aftman install
   ```
   Ça installe automatiquement la bonne version de Rojo (voir `aftman.toml`).
3. Clone ce repo en local si ce n'est pas déjà fait :
   ```
   git clone https://github.com/ServeurOpen/roblox-game.git
   cd roblox-game
   ```

## Utilisation (à chaque session de travail)

1. Dans le dossier du projet : `rojo serve`
2. Dans Roblox Studio (fichier `.rbxl` vide ou ton jeu existant) : ouvre le
   plugin Rojo → clique **Connect**.
3. Les scripts apparaissent dans l'explorer Studio. Teste avec le bouton
   Play habituel.

Quand je pousse de nouveaux scripts sur ce repo : `git pull`, puis Rojo
resynchronise automatiquement (tant que `rojo serve` tourne et que Studio
est connecté).

## Structure

- `src/ReplicatedStorage/` — config partagée (IDs Game Pass/Dev Product,
  noms des Remotes)
- `src/ServerScriptService/` — logique serveur : sauvegarde des données
  (DataStore), économie (gain de cash), monétisation (achats Robux)
- `src/StarterGui/` — UI affichée au joueur (compteur de cash)
- `src/StarterPlayerScripts/` — scripts client (boutique de boosters)

## Avant de publier : configurer la monétisation

Dans **Roblox Creator Dashboard** (depuis la page de ton jeu) :

1. Crée un **Game Pass** "Double Cash" et un "VIP" → récupère leurs IDs
   numériques → colle-les dans `src/ReplicatedStorage/GameConfig.lua`
   (`GamePasses.DoubleCash`, `GamePasses.VIP`).
2. Crée des **Developer Products** "100 Cash", "500 Cash", "2000 Cash" →
   récupère leurs IDs → colle-les dans le même fichier (`DevProducts`).
3. Pour recevoir l'argent réel (pas juste des Robux) : configure le
   **DevEx (Developer Exchange)** sur ton compte Roblox une fois que tu as
   au moins 30 000 Robux cumulés et que ton compte respecte les conditions
   (âge, compte vérifié, etc.) — voir la page officielle Roblox DevEx.

## Idées de prochaines étapes

- Construire les plots de tycoon (zones à acheter/upgrader) dans Studio,
  les relier à `Economy.server.lua`.
- Ajouter une vraie UI de boutique (boutons) qui appellent
  `BoosterShop.PromptDoubleCash()`, `PromptVIP()`, `PromptCash(100)`.
- Ajouter un système de codes promo / événements pour relancer
  régulièrement l'intérêt des joueurs (boost de rétention).
