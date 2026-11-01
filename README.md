# Tower Defense Infini (Roblox) — projet Rojo

Portage sur Roblox du jeu web "Tower Defense Infini" (studio FERRA). Pas
un copier-coller du JS/Canvas (impossible, moteurs totalement différents) :
le design (stats des tours/ennemis, formules de scaling des vagues,
économie) est repris du fichier source, mais tout le code est réécrit en
Lua pour de vrai (parts 3D, combat serveur-autorité).

Synchronisé avec Studio via [Rojo](https://rojo.space/) : je (Claude)
modifie le code ici, tu fais `git pull` et ça se resynchronise
automatiquement dans Studio tant que `rojo serve` tourne.

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

1. **Stop** toute partie Play en cours dans Studio avant de puller (sinon
   risque de doublons d'instances en mémoire).
2. `git pull`
3. `rojo serve` (laisse le terminal ouvert)
4. Studio → plugin Rojo → **Connect** → accepter la synchro.
5. **Exécuter** (Play) pour tester.

## v1 : ce qui est jouable maintenant

- 4 parcelles de jeu privées (une par joueur), attribuées automatiquement
  à l'arrivée, avec téléportation directe dessus.
- Chemin en zigzag généré proceduralement, zones constructibles
  calculées automatiquement autour du chemin (pas de placement à la main).
- 4 tours : Canon, Tour Archer, Tour de Glace (ralentit), Tour de Feu
  (brûlure) — stats/coûts repris du fichier source.
- 4 ennemis : Rôdeur, Furtif Rapide, Blindé, Diviseur (se divise en
  Éclats à sa mort) — stats reprises du fichier source.
- Vagues infinies avec la vraie formule de scaling du jeu original
  (nombre d'ennemis, vitesse de spawn, vie, vitesse, récompense en or).
- Or de départ 200, 20 vies, défaite = reset de la run (le meilleur
  numéro de vague atteint est sauvegardé en `PlayerData.BestWave`).
- HUD : or/vies/vague, menu de construction, bouton "Lancer la vague"
  avec compte à rebours automatique.

## Ce qui n'est PAS encore porté (prochaines étapes)

Le jeu source est enorme (9 tours, 16 ennemis dont 5 boss, synergies
élémentaires, vagues maudites, prestige, wiki, classement, panel admin).
Tout faire d'un coup aurait donné quelque chose de bâclé — on ajoute le
reste par vagues, testées une par une :

- Tours restantes : Vent, Tesla, Poison, Caserne Militaire, Tour du
  Prestige.
- Ennemis restants + vagues de Boss/Mini-Boss (toutes les 10/5 vagues),
  roulette de boss, Nécromancien (invocation), Chaman Soigneur.
- Synergies élémentaires entre tours.
- Vagues maudites (mutateurs aléatoires après la vague 15).
- Vente de tours, repositionnement.
- Système de Prestige, Wiki, classement, succès.
- Monétisation (Game Pass/Dev Products) — volontairement pas encore
  remise en place, à faire une fois le cœur de jeu validé.

## Structure

- `src/ReplicatedStorage/TD/` — configs partagées : `TowerTypes.lua`,
  `EnemyTypes.lua`, `Formulas.lua` (scaling des vagues)
- `src/ServerScriptService/TD/` — logique serveur : `ArenaSetup` (génère
  les parcelles), `ArenaManager` (attribution), `RunState` (état de
  partie par joueur), `EnemyManager`, `TowerManager`, `GameLoop` (boucle
  principale + remotes)
- `src/ServerScriptService/PlayerData.lua` — persistance DataStore
  (uniquement `BestWave` pour l'instant)
- `src/StarterGui/TowerDefenseHUD.client.lua` — toute l'UI
