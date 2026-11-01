# Farm d'Energie (Roblox) — projet Rojo

Petit jeu "simulator" : on clique sur un Core d'Energie pour farmer, on
achete des pets avec l'energie gagnee, les pets equipes rapportent de
l'energie passive par seconde. Base volontairement simple pour demarrer
(v1), pensee pour grandir ensuite (rebirths, plots perso, oeufs, etc).

Synchronise avec Studio via [Rojo](https://rojo.space/) : je (Claude)
modifie le code ici, `rojo serve` resynchronise automatiquement dans
Studio tant qu'il tourne et que le plugin est connecte.

## Installation (une seule fois)

1. **Plugin Rojo dans Studio** : Toolbox / Plugins Marketplace → "Rojo"
   (par Rojo Foundation) → installer.
2. **Rojo CLI sur ton PC** : `cargo install aftman` (ou l'installeur
   officiel GitHub, jamais un site tiers), puis dans ce dossier :
   ```
   aftman install
   ```
3. Clone ce repo si ce n'est pas déjà fait :
   ```
   git clone https://github.com/ServeurOpen/roblox-game.git
   cd roblox-game
   ```

## Utilisation (à chaque session)

1. **Stop** toute partie Play en cours dans Studio avant de puller ou de
   laisser Claude modifier des fichiers (sinon la partie en cours tourne
   sur une copie figee d'avant les changements - symptome classique :
   des dossiers manquants genre `Workspace.Map` au Play alors que tout
   est bien present dans l'Explorer en mode edition).
2. `git pull` (si le code a ete modifie depuis une autre machine).
3. `rojo serve` (laisse le terminal ouvert).
4. Studio → plugin Rojo → **Connect** (ou **Disconnect** puis
   **Connect** si c'etait deja connecte, pour forcer une resynchro
   complete apres des changements importants).
5. **Exécuter** (Play) pour tester.

## v1 : ce qui est jouable maintenant

- Une map partagee avec un **Core d'Energie** (clic pour farmer) et un
  **stand de Boutique de Pets** (interaction pour ouvrir le menu).
- 5 pets : Chaton Etincelle (gratuit, offert au depart), Pierre Vivante,
  Flammy, Cristal Luisant, Dragonnet — chacun rapporte de l'energie
  passive par seconde une fois equipe.
- Jusqu'a 3 pets equipes en meme temps, ils suivent le joueur en
  orbitant autour de lui.
- Energie et pets (possedes/equipes) sauvegardes en DataStore, persistent
  entre les sessions.
- HUD : compteur d'energie, revenu passif affiche, boutique de pets
  (acheter / equiper / retirer).

## Prochaines étapes possibles

- Plots personnels par joueur (au lieu d'une map partagee).
- Oeufs a ouvrir pour obtenir des pets aleatoires (au lieu d'un achat
  direct dans un shop fixe).
- Rebirth/Prestige : reset contre un multiplicateur permanent de gains.
- Pets de rarete variable (communs/rares/legendaires) avec un indicateur
  visuel (particules, taille).
- Boutons/zones de farm multiples, outils a ramasser.
- Classement des joueurs les plus riches.
- Monetisation (Game Pass/Dev Products) — a faire une fois le coeur de
  jeu valide.

## Structure

- `src/ReplicatedStorage/RemoteNames.lua` — noms des remotes partages.
- `src/ReplicatedStorage/Game/PetTypes.lua` — catalogue des pets
  (cout, revenu passif, couleur).
- `src/ServerScriptService/Bootstrap.server.lua` — cree le dossier
  `Remotes` dans `ReplicatedStorage`.
- `src/ServerScriptService/PlayerData.lua` — persistance DataStore
  (`Energy`, `OwnedPets`, `EquippedPets`).
- `src/ServerScriptService/Game/MapSetup.server.lua` — construit la map
  (sol, spawn, Core d'Energie, stand de boutique).
- `src/ServerScriptService/Game/PetManager.lua` — logique d'achat/
  equipement des pets + modeles visuels qui suivent le joueur.
- `src/ServerScriptService/Main.server.lua` — boucle principale : clics
  sur le Core, revenu passif, remotes de la boutique, push d'etat aux
  clients.
- `src/StarterGui/FarmHUD.client.lua` — toute l'UI (stats, boutique).
