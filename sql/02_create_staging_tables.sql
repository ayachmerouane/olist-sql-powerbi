/* =====================================================================
   02_create_staging_tables.sql
   Crée les 9 tables du schéma stg, une par fichier CSV.

   Choix des types :
     - identifiants (hash de 32 caractères)  -> CHAR(32)
     - codes postaux (zéros en tête : 01037) -> CHAR(5), pas INT
     - villes, catégories, avis (accents)    -> NVARCHAR
     - montants                              -> DECIMAL(10,2)
     - dates                                 -> DATETIME2(0)
   ===================================================================== */

USE OlistDB;
GO

DROP TABLE IF EXISTS stg.order_reviews;
DROP TABLE IF EXISTS stg.order_payments;
DROP TABLE IF EXISTS stg.order_items;
DROP TABLE IF EXISTS stg.orders;
DROP TABLE IF EXISTS stg.customers;
DROP TABLE IF EXISTS stg.sellers;
DROP TABLE IF EXISTS stg.products;
DROP TABLE IF EXISTS stg.category_translation;
DROP TABLE IF EXISTS stg.geolocation;
GO

CREATE TABLE stg.customers (
    customer_id              CHAR(32)      NOT NULL PRIMARY KEY,
    customer_unique_id       CHAR(32)      NOT NULL,
    customer_zip_code_prefix CHAR(5)       NOT NULL,
    customer_city            NVARCHAR(60)  NOT NULL,
    customer_state           CHAR(2)       NOT NULL
);

CREATE TABLE stg.sellers (
    seller_id              CHAR(32)      NOT NULL PRIMARY KEY,
    seller_zip_code_prefix CHAR(5)       NOT NULL,
    seller_city            NVARCHAR(60)  NOT NULL,
    seller_state           CHAR(2)       NOT NULL
);

CREATE TABLE stg.products (
    product_id                 CHAR(32)      NOT NULL PRIMARY KEY,
    product_category_name      NVARCHAR(60)  NULL,
    product_name_lenght        INT           NULL,   -- faute de frappe d'origine conservée
    product_description_lenght INT           NULL,
    product_photos_qty         INT           NULL,
    product_weight_g           INT           NULL,
    product_length_cm          INT           NULL,
    product_height_cm          INT           NULL,
    product_width_cm           INT           NULL
);

CREATE TABLE stg.category_translation (
    product_category_name         NVARCHAR(60) NOT NULL PRIMARY KEY,
    product_category_name_english NVARCHAR(60) NOT NULL
);

CREATE TABLE stg.orders (
    order_id                      CHAR(32)     NOT NULL PRIMARY KEY,
    customer_id                   CHAR(32)     NOT NULL,
    order_status                  VARCHAR(20)  NOT NULL,
    order_purchase_timestamp      DATETIME2(0) NOT NULL,
    order_approved_at             DATETIME2(0) NULL,
    order_delivered_carrier_date  DATETIME2(0) NULL,
    order_delivered_customer_date DATETIME2(0) NULL,
    order_estimated_delivery_date DATETIME2(0) NOT NULL
);

CREATE TABLE stg.order_items (
    order_id            CHAR(32)      NOT NULL,
    order_item_id       INT           NOT NULL,
    product_id          CHAR(32)      NOT NULL,
    seller_id           CHAR(32)      NOT NULL,
    shipping_limit_date DATETIME2(0)  NOT NULL,
    price               DECIMAL(10,2) NOT NULL,
    freight_value       DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_order_items PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE stg.order_payments (
    order_id             CHAR(32)      NOT NULL,
    payment_sequential   INT           NOT NULL,
    payment_type         VARCHAR(20)   NOT NULL,
    payment_installments INT           NOT NULL,
    payment_value        DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_order_payments PRIMARY KEY (order_id, payment_sequential)
);

-- Pas de clé primaire : certains review_id apparaissent plusieurs fois dans la source.
CREATE TABLE stg.order_reviews (
    review_id               CHAR(32)       NOT NULL,
    order_id                CHAR(32)       NOT NULL,
    review_score            TINYINT        NOT NULL,
    review_comment_title    NVARCHAR(100)  NULL,
    review_comment_message  NVARCHAR(1000) NULL,
    review_creation_date    DATETIME2(0)   NOT NULL,
    review_answer_timestamp DATETIME2(0)   NOT NULL
);

-- Pas de clé primaire : plusieurs coordonnées GPS par code postal.
CREATE TABLE stg.geolocation (
    geolocation_zip_code_prefix CHAR(5)      NOT NULL,
    geolocation_lat             FLOAT        NOT NULL,
    geolocation_lng             FLOAT        NOT NULL,
    geolocation_city            NVARCHAR(60) NOT NULL,
    geolocation_state           CHAR(2)      NOT NULL
);
GO
