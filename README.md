# Analyse E-commerce Olist — SQL Server → Power BI

> Projet portfolio Data Analyst : de la base de données brute au tableau de bord décisionnel.

🚧 **Projet en cours de réalisation**

## Contexte

**Olist** est une marketplace brésilienne qui connecte des petits vendeurs à des clients. Le jeu de données contient environ **99 000 commandes** passées entre **2016 et 2018** (montants en BRL).

En tant que Data Analyst, l'objectif est de construire un tableau de bord permettant à la direction de piloter les **ventes**, la **logistique** et la **satisfaction client**.

## Questions métier

1. **Ventes** : comment évolue le chiffre d'affaires ? Quelle saisonnalité ?
2. **Produits** : quelles catégories génèrent le plus de revenus (règle des 80/20) ?
3. **Logistique** : quelle part des commandes est livrée en retard, et dans quelles régions ?
4. **Satisfaction** : quel est l'impact des retards sur les notes clients ?
5. **Clients** : quel est le taux de réachat ? Quels sont les segments RFM ?
6. **Vendeurs** : quels vendeurs performent le mieux, et lesquels posent problème ?

## KPI suivis

| Domaine | Indicateurs |
|---|---|
| Ventes | CA, nombre de commandes, panier moyen, croissance vs N-1 |
| Logistique | Délai moyen de livraison, % de retards, frais de port moyens |
| Satisfaction | Note moyenne, % d'avis négatifs (≤ 2) |
| Clients | Nombre de clients, taux de réachat, segments RFM |

## Stack technique

- **SQL Server Express** + **SSMS** : stockage, nettoyage et modélisation des données
- **Power BI Desktop** : modélisation en étoile, mesures DAX, visualisation
- **Git / GitHub** : versionnement et documentation

## Architecture

```
CSV Kaggle → SQL Server (schéma stg) → vues nettoyées (schéma dw) → Power BI → Dashboard
```

## Structure du dépôt

```
olist-sql-powerbi/
├── data/raw/        ← CSV sources (non versionnés, voir ci-dessous)
├── sql/             ← scripts SQL (création, chargement, vues, analyses)
├── powerbi/         ← fichier .pbix
├── images/          ← captures du dashboard et schéma du modèle
└── README.md
```

## Données

Source : [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle).

Les fichiers CSV ne sont pas inclus dans le dépôt. Pour reproduire le projet, téléchargez-les et placez-les dans `data/raw/`.

## Résultats

*À venir : captures du dashboard, insights clés et recommandations.*

## Auteur

**Merouane Ayach** — Data Analyst
