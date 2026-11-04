/* =====================================================================
   04_tests_qualite.sql
   Contrôles de qualité des données après le chargement (schéma stg).
   Exécuter chaque test séparément : sélectionner le bloc puis F5.
   ===================================================================== */

USE OlistDB;
GO

/* ---------- Test 1 : volumétrie ----------
   Attendu : 99441 / 3095 / 32951 / 71 / 99441 / 112650 / 103886 / 99224 / 1000163 */
SELECT 'customers' AS table_name, COUNT(*) AS nb FROM stg.customers UNION ALL
SELECT 'sellers',              COUNT(*) FROM stg.sellers UNION ALL
SELECT 'products',             COUNT(*) FROM stg.products UNION ALL
SELECT 'category_translation', COUNT(*) FROM stg.category_translation UNION ALL
SELECT 'orders',               COUNT(*) FROM stg.orders UNION ALL
SELECT 'order_items',          COUNT(*) FROM stg.order_items UNION ALL
SELECT 'order_payments',       COUNT(*) FROM stg.order_payments UNION ALL
SELECT 'order_reviews',        COUNT(*) FROM stg.order_reviews UNION ALL
SELECT 'geolocation',          COUNT(*) FROM stg.geolocation;


/* ---------- Test 2 : intégrité référentielle (lignes orphelines) ----------
   Attendu : 0 partout */
SELECT 'commandes sans client' AS test, COUNT(*) AS nb
FROM stg.orders o LEFT JOIN stg.customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'lignes sans commande', COUNT(*)
FROM stg.order_items i LEFT JOIN stg.orders o ON i.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'lignes sans produit', COUNT(*)
FROM stg.order_items i LEFT JOIN stg.products p ON i.product_id = p.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'lignes sans vendeur', COUNT(*)
FROM stg.order_items i LEFT JOIN stg.sellers s ON i.seller_id = s.seller_id
WHERE s.seller_id IS NULL
UNION ALL
SELECT 'paiements sans commande', COUNT(*)
FROM stg.order_payments p LEFT JOIN stg.orders o ON p.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'avis sans commande', COUNT(*)
FROM stg.order_reviews r LEFT JOIN stg.orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


/* ---------- Test 3 : types de données ---------- */
-- Codes postaux : les zéros en tête sont conservés (01037, pas 1037)
SELECT TOP 5 geolocation_zip_code_prefix, geolocation_city
FROM stg.geolocation WHERE geolocation_zip_code_prefix LIKE '0%';

-- Accents : affichés correctement (são paulo, pas sÃ£o paulo)
SELECT TOP 5 customer_city FROM stg.customers WHERE customer_city LIKE N'%ã%';

-- Dates : attendu 2016-09-04 -> 2018-10-17
SELECT MIN(order_purchase_timestamp) AS premiere_commande,
       MAX(order_purchase_timestamp) AS derniere_commande
FROM stg.orders;

-- Montants : prix minimum > 0
SELECT MIN(price) AS prix_min, MAX(price) AS prix_max,
       MIN(freight_value) AS port_min, MAX(freight_value) AS port_max
FROM stg.order_items;


/* ---------- Test 4 : valeurs manquantes ----------
   Attendu : 160 / 1783 / 2965, et 610 produits sans catégorie */
SELECT
    SUM(CASE WHEN order_approved_at             IS NULL THEN 1 ELSE 0 END) AS approbation_null,
    SUM(CASE WHEN order_delivered_carrier_date  IS NULL THEN 1 ELSE 0 END) AS remise_transporteur_null,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS livraison_null
FROM stg.orders;

SELECT COUNT(*) AS produits_sans_categorie
FROM stg.products WHERE product_category_name IS NULL;


/* ---------- Test 5 : cohérence des statuts ----------
   Attendu : ~96 000 'delivered' ; les annulées n'ont pas de date de livraison */
SELECT order_status, COUNT(*) AS nb,
       SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS sans_date_livraison
FROM stg.orders
GROUP BY order_status
ORDER BY nb DESC;


/* ---------- Test 6 : pièges de la source (corrigés dans les vues dw) ---------- */
-- Avis en double
SELECT COUNT(*) AS total_avis, COUNT(DISTINCT review_id) AS avis_uniques
FROM stg.order_reviews;

-- Catégories sans traduction anglaise (attendu : 2)
SELECT DISTINCT p.product_category_name
FROM stg.products p
LEFT JOIN stg.category_translation t ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL AND p.product_category_name IS NOT NULL;

-- Un client réel peut avoir plusieurs customer_id
SELECT COUNT(DISTINCT customer_id)        AS customer_ids,
       COUNT(DISTINCT customer_unique_id) AS clients_reels
FROM stg.customers;
