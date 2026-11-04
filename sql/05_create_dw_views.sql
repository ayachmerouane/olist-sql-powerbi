/* =====================================================================
   05_create_dw_views.sql
   Construit le schéma en étoile du schéma dw, utilisé par Power BI.

                    dim_date
                       │
    dim_client ── fact_commandes ── fact_ventes ── dim_produit
                                        │
                                   dim_vendeur

   Dimensions : dim_client, dim_produit, dim_vendeur (vues), dim_date (table)
   Faits      : fact_commandes (1 ligne = 1 commande)
                fact_ventes    (1 ligne = 1 article d'une commande)

   Corrections apportées aux anomalies relevées dans 04_tests_qualite.sql :
     - catégories vides ou non traduites -> nom portugais ou 'unknown'
     - avis en double                    -> une note moyenne par commande
     - commandes non livrées             -> délai et retard laissés à NULL
     - dates avec heure                  -> converties en DATE pour dim_date
   ===================================================================== */

USE OlistDB;
GO

/* ---------------------------------------------------------------------
   dim_client : un client par customer_id
   customer_unique_id identifie la personne réelle (pour le réachat).
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dw.dim_client AS
SELECT
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix AS code_postal,
    c.customer_city            AS ville,
    c.customer_state           AS etat,
    CASE
        WHEN c.customer_state IN ('SP','RJ','MG','ES')                          THEN 'Sudeste'
        WHEN c.customer_state IN ('PR','SC','RS')                               THEN 'Sul'
        WHEN c.customer_state IN ('DF','GO','MT','MS')                          THEN 'Centro-Oeste'
        WHEN c.customer_state IN ('BA','SE','AL','PE','PB','RN','CE','PI','MA') THEN 'Nordeste'
        ELSE 'Norte'
    END                        AS region,
    c.customer_state + ', Brazil' AS etat_pays   -- aide le géocodage des cartes Power BI
FROM stg.customers c;
GO

/* ---------------------------------------------------------------------
   dim_vendeur : un vendeur par seller_id
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dw.dim_vendeur AS
SELECT
    s.seller_id,
    s.seller_zip_code_prefix AS code_postal,
    s.seller_city            AS ville,
    s.seller_state           AS etat,
    CASE
        WHEN s.seller_state IN ('SP','RJ','MG','ES')                          THEN 'Sudeste'
        WHEN s.seller_state IN ('PR','SC','RS')                               THEN 'Sul'
        WHEN s.seller_state IN ('DF','GO','MT','MS')                          THEN 'Centro-Oeste'
        WHEN s.seller_state IN ('BA','SE','AL','PE','PB','RN','CE','PI','MA') THEN 'Nordeste'
        ELSE 'Norte'
    END                      AS region,
    s.seller_state + ', Brazil' AS etat_pays
FROM stg.sellers s;
GO

/* ---------------------------------------------------------------------
   dim_produit : un produit par product_id, catégorie en anglais
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dw.dim_produit AS
SELECT
    p.product_id,
    REPLACE(COALESCE(t.product_category_name_english,   -- traduction anglaise
                     p.product_category_name,           -- sinon nom portugais
                     'unknown'), '_', ' ')  AS categorie,
    COALESCE(p.product_category_name, 'unknown') AS categorie_pt,
    p.product_weight_g                      AS poids_g,
    p.product_length_cm * p.product_height_cm * p.product_width_cm AS volume_cm3,
    p.product_photos_qty                    AS nb_photos
FROM stg.products p
LEFT JOIN stg.category_translation t
       ON p.product_category_name = t.product_category_name;
GO

/* ---------------------------------------------------------------------
   dim_date : table calendrier, un jour par ligne (2016-01-01 -> 2018-12-31)
   Créée comme table (et non vue) : Power BI doit la marquer comme
   « table de dates » pour les fonctions de time intelligence (N-1, YTD...).
   Les noms de mois et de jours sont écrits en dur pour ne pas dépendre
   de la langue du serveur.
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS dw.dim_date;
GO

CREATE TABLE dw.dim_date (
    [date]           DATE        NOT NULL PRIMARY KEY,
    annee            INT         NOT NULL,
    trimestre        CHAR(2)     NOT NULL,   -- T1..T4
    mois_num         INT         NOT NULL,
    mois_nom         VARCHAR(10) NOT NULL,
    annee_mois       CHAR(7)     NOT NULL,   -- 2017-01
    annee_mois_tri   INT         NOT NULL,   -- 201701, pour trier annee_mois
    jour_semaine_num INT         NOT NULL,   -- 1 = lundi ... 7 = dimanche
    jour_semaine_nom VARCHAR(10) NOT NULL,
    est_weekend      BIT         NOT NULL
);
GO

WITH jours AS (
    SELECT CAST('2016-01-01' AS DATE) AS d
    UNION ALL
    SELECT DATEADD(DAY, 1, d) FROM jours WHERE d < '2018-12-31'
),
base AS (
    -- 1900-01-01 était un lundi : on calcule le jour de la semaine sans dépendre de SET DATEFIRST
    SELECT d, DATEDIFF(DAY, '1900-01-01', d) % 7 + 1 AS jsem
    FROM jours
)
INSERT INTO dw.dim_date
SELECT
    d,
    YEAR(d),
    'T' + CAST(DATEPART(QUARTER, d) AS CHAR(1)),
    MONTH(d),
    CHOOSE(MONTH(d), 'Janvier','Février','Mars','Avril','Mai','Juin',
                     'Juillet','Août','Septembre','Octobre','Novembre','Décembre'),
    CONVERT(CHAR(7), d, 126),
    YEAR(d) * 100 + MONTH(d),
    jsem,
    CHOOSE(jsem, 'Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'),
    CASE WHEN jsem IN (6, 7) THEN 1 ELSE 0 END
FROM base
OPTION (MAXRECURSION 0);
GO

/* ---------------------------------------------------------------------
   fact_commandes : une ligne par commande
   Logistique (délais, retards), satisfaction (note) et paiement.
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dw.fact_commandes AS
WITH avis AS (
    -- Une seule note par commande, même si la source contient des doublons
    SELECT order_id,
           CAST(AVG(CAST(review_score AS DECIMAL(4,2))) AS DECIMAL(3,2)) AS note_avis
    FROM stg.order_reviews
    GROUP BY order_id
),
paiements AS (
    SELECT order_id,
           SUM(payment_value)                                          AS montant_paye,
           MAX(payment_installments)                                   AS nb_echeances,
           MAX(CASE WHEN payment_sequential = 1 THEN payment_type END) AS type_paiement
    FROM stg.order_payments
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.customer_id,
    o.order_status                                        AS statut,
    CAST(o.order_purchase_timestamp      AS DATE)         AS date_commande,
    CAST(o.order_delivered_customer_date AS DATE)         AS date_livraison,
    CAST(o.order_estimated_delivery_date AS DATE)         AS date_livraison_prevue,
    DATEPART(HOUR, o.order_purchase_timestamp)            AS heure_commande,

    -- Délais : NULL si la commande n'a pas été livrée
    DATEDIFF(DAY, o.order_purchase_timestamp,
                  o.order_delivered_customer_date)        AS delai_livraison_jours,
    DATEDIFF(DAY, o.order_estimated_delivery_date,
                  o.order_delivered_customer_date)        AS ecart_vs_prevu_jours,  -- > 0 = retard
    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        WHEN CAST(o.order_delivered_customer_date AS DATE)
           > CAST(o.order_estimated_delivery_date AS DATE) THEN 1
        ELSE 0
    END                                                   AS en_retard,

    a.note_avis,
    p.montant_paye,
    p.type_paiement,
    p.nb_echeances
FROM stg.orders o
LEFT JOIN avis      a ON a.order_id = o.order_id
LEFT JOIN paiements p ON p.order_id = o.order_id;
GO

/* ---------------------------------------------------------------------
   fact_ventes : une ligne par article vendu
   Base du chiffre d'affaires. Le statut est conservé pour pouvoir
   exclure les commandes annulées ou indisponibles dans Power BI.
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dw.fact_ventes AS
SELECT
    i.order_id,
    i.order_item_id,
    o.customer_id,
    i.product_id,
    i.seller_id,
    CAST(o.order_purchase_timestamp AS DATE) AS date_commande,
    o.order_status                           AS statut,
    i.price                                  AS prix,
    i.freight_value                          AS frais_port,
    i.price + i.freight_value                AS montant_total
FROM stg.order_items i
JOIN stg.orders o ON o.order_id = i.order_id;
GO

/* ---------- Contrôle : nombre de lignes par objet dw ----------
   Attendu : dim_client 99441 / dim_vendeur 3095 / dim_produit 32951 /
             dim_date 1096 / fact_commandes 99441 / fact_ventes 112650 */
SELECT 'dim_client'     AS objet, COUNT(*) AS nb_lignes FROM dw.dim_client     UNION ALL
SELECT 'dim_vendeur',             COUNT(*)              FROM dw.dim_vendeur    UNION ALL
SELECT 'dim_produit',             COUNT(*)              FROM dw.dim_produit    UNION ALL
SELECT 'dim_date',                COUNT(*)              FROM dw.dim_date       UNION ALL
SELECT 'fact_commandes',          COUNT(*)              FROM dw.fact_commandes UNION ALL
SELECT 'fact_ventes',             COUNT(*)              FROM dw.fact_ventes;
GO
