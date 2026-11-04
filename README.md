# Analyse E-commerce Olist — SQL Server → Power BI

> Projet portfolio Data Analyst : de la base de données brute au tableau de bord décisionnel.

🚧 **Projet en cours de réalisation**

## Contexte

**Olist** est une marketplace brésilienne qui connecte des petits vendeurs à des clients. Le jeu de données contient environ **99 000 commandes** passées entre **2016 et 2018** (montants en BRL).

En tant que Data Analyst, l'objectif est de construire un tableau de bord permettant à la direction de piloter les **ventes**, la **logistique** et la **satisfaction client**.

## Questions métier

### 1. Ventes : comment évolue l'activité ?
- Comment évoluent le chiffre d'affaires et le nombre de commandes mois par mois ?
- Quelle est la croissance par rapport à l'année précédente ?
- Y a-t-il une saisonnalité (Black Friday, fin d'année) ?
- À quels jours et à quelles heures les clients commandent-ils le plus ?

*Indicateurs : CA, nombre de commandes, panier moyen, croissance N-1 — Tables : `fact_ventes`, `fact_commandes`, `dim_date`*

### 2. Produits : qu'est-ce qui se vend ?
- Quelles catégories génèrent le plus de chiffre d'affaires ?
- La règle des 80/20 se vérifie-t-elle (20 % des catégories font-elles 80 % du CA) ?
- Quelles catégories ont les frais de port les plus élevés par rapport à leur prix ?

*Indicateurs : CA par catégorie, part du CA cumulée, ratio port / prix — Tables : `fact_ventes`, `dim_produit`*

### 3. Logistique : livre-t-on à temps ?
- Quel est le délai moyen de livraison ?
- Quelle part des commandes est livrée en retard ?
- Quels États et quelles régions sont les plus touchés par les retards ?
- Le délai a-t-il évolué entre 2016 et 2018 ?

*Indicateurs : délai moyen, % de retards, écart par rapport à la date prévue — Tables : `fact_commandes`, `dim_client`*

### 4. Satisfaction : les clients sont-ils contents ?
- Quelle est la note moyenne des avis ?
- Quel est l'impact d'un retard sur la note ?
- Quelles catégories reçoivent le plus d'avis négatifs ?

*Indicateurs : note moyenne, % d'avis négatifs (≤ 2), note selon le retard — Tables : `fact_commandes`, `fact_ventes`, `dim_produit`*

### 5. Clients : fidélise-t-on ?
- Combien de clients différents ont commandé ?
- Quelle part des clients a passé plus d'une commande (taux de réachat) ?
- Quels sont les segments de clients selon la méthode RFM (Récence, Fréquence, Montant) ?

*Indicateurs : nombre de clients uniques, taux de réachat, segments RFM — Tables : `fact_commandes`, `dim_client`*

### 6. Vendeurs : qui performe ?
- Quels sont les 10 vendeurs qui réalisent le plus gros chiffre d'affaires ?
- Quels vendeurs cumulent retards et mauvaises notes ?
- La distance entre l'État du vendeur et celui du client influence-t-elle le délai ?

*Indicateurs : CA par vendeur, % de retards par vendeur, note moyenne par vendeur — Tables : `fact_ventes`, `fact_commandes`, `dim_vendeur`*

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
