/* =====================================================================
   03_load_data.sql
   Charge les 9 CSV dans les tables stg avec BULK INSERT.

   >>> Modifiez @path si vos CSV sont dans un autre dossier. <<<

   Points d'attention sur les fichiers source :
     - encodage UTF-8 (accents)                      -> CODEPAGE = '65001'
     - avis avec retours à la ligne entre guillemets -> FORMAT = 'CSV'
     - fins de ligne LF pour la plupart des fichiers,
       CRLF pour order_reviews et category_translation
   ===================================================================== */

USE OlistDB;
GO

SET NOCOUNT ON;

DECLARE @path NVARCHAR(400) = N'C:\Users\dell\Downloads\olist-sql-powerbi\data\raw\';

DECLARE @files TABLE (tbl SYSNAME, csv NVARCHAR(200), rowterm VARCHAR(10));
INSERT INTO @files VALUES
    ('customers',            'olist_customers_dataset.csv',           '0x0a'),
    ('sellers',              'olist_sellers_dataset.csv',             '0x0a'),
    ('products',             'olist_products_dataset.csv',            '0x0a'),
    ('category_translation', 'product_category_name_translation.csv', '0x0d0a'),
    ('orders',               'olist_orders_dataset.csv',              '0x0a'),
    ('order_items',          'olist_order_items_dataset.csv',         '0x0a'),
    ('order_payments',       'olist_order_payments_dataset.csv',      '0x0a'),
    ('order_reviews',        'olist_order_reviews_dataset.csv',       '0x0d0a'),
    ('geolocation',          'olist_geolocation_dataset.csv',         '0x0a');

DECLARE @tbl SYSNAME, @csv NVARCHAR(200), @rowterm VARCHAR(10), @sql NVARCHAR(MAX);

DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT tbl, csv, rowterm FROM @files;
OPEN c;
FETCH NEXT FROM c INTO @tbl, @csv, @rowterm;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'TRUNCATE TABLE stg.' + QUOTENAME(@tbl) + N';
BULK INSERT stg.' + QUOTENAME(@tbl) + N'
FROM ''' + @path + @csv + N'''
WITH (FORMAT = ''CSV'', FIRSTROW = 2, FIELDQUOTE = ''"'', FIELDTERMINATOR = '','',
      ROWTERMINATOR = ''' + @rowterm + N''', CODEPAGE = ''65001'', TABLOCK);';

    EXEC sp_executesql @sql;
    PRINT 'OK  stg.' + @tbl;

    FETCH NEXT FROM c INTO @tbl, @csv, @rowterm;
END
CLOSE c;
DEALLOCATE c;
GO

/* ---------- Contrôle : nombre de lignes chargées ---------- */
SELECT 'customers'            AS table_name, COUNT(*) AS nb_lignes, 99441   AS attendu FROM stg.customers            UNION ALL
SELECT 'sellers',                            COUNT(*),            3095              FROM stg.sellers              UNION ALL
SELECT 'products',                           COUNT(*),            32951             FROM stg.products             UNION ALL
SELECT 'category_translation',               COUNT(*),            71                FROM stg.category_translation UNION ALL
SELECT 'orders',                             COUNT(*),            99441             FROM stg.orders               UNION ALL
SELECT 'order_items',                        COUNT(*),            112650            FROM stg.order_items          UNION ALL
SELECT 'order_payments',                     COUNT(*),            103886            FROM stg.order_payments       UNION ALL
SELECT 'order_reviews',                      COUNT(*),            99224             FROM stg.order_reviews        UNION ALL
SELECT 'geolocation',                        COUNT(*),            1000163           FROM stg.geolocation;
GO
