/* =====================================================================
   06_rfm_clients.sql
   Segmentation RFM des clients (Récence, Fréquence, Montant).
   Une ligne par client réel (customer_unique_id).

   - Commandes annulées / indisponibles exclues (même règle que le CA)
   - Date de référence : le lendemain de la dernière commande du jeu
   - 97 % des clients n'ont commandé qu'une fois : la fréquence est
     traitée en 2 groupes (1 commande / 2 et plus), les scores R et M
     sont calculés en quartiles (NTILE 4, 4 = meilleur)
   ===================================================================== */

USE OlistDB;
GO

CREATE OR ALTER VIEW dw.client_rfm AS
WITH commandes AS (
    SELECT c.customer_unique_id,
           o.order_id,
           o.order_purchase_timestamp
    FROM stg.orders o
    JOIN stg.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
),
montants AS (
    SELECT order_id, SUM(price + freight_value) AS montant
    FROM stg.order_items
    GROUP BY order_id
),
date_ref AS (
    SELECT DATEADD(DAY, 1, CAST(MAX(order_purchase_timestamp) AS DATE)) AS d
    FROM stg.orders
),
rfm AS (
    SELECT cm.customer_unique_id,
           DATEDIFF(DAY, MAX(cm.order_purchase_timestamp), r.d) AS recence_jours,
           COUNT(DISTINCT cm.order_id)                          AS frequence,
           SUM(m.montant)                                       AS montant
    FROM commandes cm
    JOIN montants m ON m.order_id = cm.order_id
    CROSS JOIN date_ref r
    GROUP BY cm.customer_unique_id, r.d
),
scores AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY recence_jours DESC) AS score_r,  -- 4 = achat le plus récent
           NTILE(4) OVER (ORDER BY montant ASC)        AS score_m   -- 4 = plus gros montant
    FROM rfm
)
SELECT
    customer_unique_id,
    recence_jours,
    frequence,
    montant,
    score_r,
    score_m,
    CASE
        WHEN frequence >= 2 AND score_r >= 3 THEN N'Fidèles actifs'
        WHEN frequence >= 2                  THEN N'Fidèles à réactiver'
        WHEN score_r >= 3 AND score_m >= 3   THEN N'Nouveaux à fort potentiel'
        WHEN score_r >= 3                    THEN N'Nouveaux clients'
        WHEN score_m >= 3                    THEN N'Gros clients perdus'
        ELSE                                      N'Clients perdus'
    END AS segment,
    CASE
        WHEN frequence >= 2 AND score_r >= 3 THEN 1
        WHEN frequence >= 2                  THEN 2
        WHEN score_r >= 3 AND score_m >= 3   THEN 3
        WHEN score_r >= 3                    THEN 4
        WHEN score_m >= 3                    THEN 5
        ELSE                                      6
    END AS segment_ordre   -- pour trier les segments dans Power BI
FROM scores;
GO

/* ---------- Contrôle : répartition des clients par segment ----------
   Attendu : environ 93 000 à 95 000 clients au total,
             Fidèles actifs + Fidèles à réactiver ≈ 3 % */
SELECT segment,
       COUNT(*)                                            AS nb_clients,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,1)) AS pct_clients,
       AVG(recence_jours)                                  AS recence_moy_jours,
       CAST(AVG(montant) AS DECIMAL(10,2))                 AS montant_moyen
FROM dw.client_rfm
GROUP BY segment, segment_ordre
ORDER BY segment_ordre;
GO